#repo http://mirror.centos.org/centos/6/os/x86_64/
install
text
keyboard us
lang en_US.UTF-8
skipx
network --device eth0 --bootproto dhcp
rootpw vagrant
firewall --disabled
authconfig --enableshadow --enablemd5
selinux --enforcing
timezone --utc UTC
services --enabled ntpd,tuned
# The biosdevname and ifnames options ensure we get "eth0" as our interface
# even in environments like virtualbox that emulate a real NW card
bootloader --location=mbr --append="no_timer_check console=ttyS0,115200n8 console=tty0 net.ifnames=0 biosdevname=0"
zerombr
clearpart --all --drives=vda

user --name=vagrant --password=vagrant

part biosboot --fstype=biosboot --size=1
part /boot --fstype ext4 --size=250 --ondisk=vda
part pv.2 --size=1 --grow --ondisk=vda
volgroup VolGroup00 --pesize=32768 pv.2
logvol swap --fstype swap --name=LogVol01 --vgname=VolGroup00 --size=768 --grow --maxsize=1536
logvol / --fstype ext4 --name=LogVol00 --vgname=VolGroup00 --size=1024 --grow
reboot

%packages
deltarpm
man-pages
bzip2
@core
rsync
screen
nfs-utils
tuned
hyperv-daemons
# Microcode updates cannot work in a VM
-microcode_ctl
# Firmware packages are not needed in a VM
-aic94xx-firmware
-atmel-firmware
-bfa-firmware
-ipw2100-firmware
-ipw2200-firmware
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6050-firmware
-libertas-usb8388-firmware
-ql2100-firmware
-ql2200-firmware
-ql23xx-firmware
-ql2400-firmware
-ql2500-firmware
-rt61pci-firmware
-rt73usb-firmware
-xorg-x11-drv-ati-firmware
-zd1211-firmware
# Disable kdump
-kexec-tools

%end

%post

# sudo
echo "%vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/vagrant

# Fix for https://github.com/CentOS/sig-cloud-instance-build/issues/38
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF

# sshd: disable password authentication and DNS checks
ex -s /etc/ssh/sshd_config <<EOF
:%substitute/^\(PasswordAuthentication\) yes$/\1 no/
:%substitute/^#\(UseDNS\) yes$/&\r\1 no/
:update
:quit
EOF
cat >>/etc/sysconfig/sshd <<EOF

# Decrease connection time by preventing reverse DNS lookups
# (see https://lists.centos.org/pipermail/centos-devel/2016-July/014981.html
#  and man sshd for more information)
OPTIONS="-u0"
EOF

# Default insecure vagrant key
mkdir -m 0700 -p /home/vagrant/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" >> /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
# Workaround for SSH pubkey auth not working, due to .ssh having the
# wrong SELinux context (see "Known Issues" in the CentOS 6 release notes)
restorecon -vR /home/vagrant/.ssh

# Fix for issue #76, regular users can gain admin privileges via su
ex -s /etc/pam.d/su <<'EOF'
/^account\s\+sufficient\s\+pam_succeed_if.so uid = 0 use_uid quiet$/
:append
# allow vagrant to use su, but prevent others from becoming root or vagrant
account		[success=1 default=ignore] \\
				pam_succeed_if.so user = vagrant use_uid quiet
account		required	pam_succeed_if.so user notin root:vagrant
.
:update
:quit
EOF

# Indicate that vagrant6 infra is being used
echo 'vag' > /etc/yum/vars/infra

# Configure tuned
tuned-adm profile virtual-guest

# Configure grub to wait just 1 second before booting
sed -i 's/^timeout=[0-9]\+$/timeout=1/' /boot/grub/grub.conf

pushd /etc/dracut.conf.d
echo 'add_drivers+=" hv_netvsc hv_storvsc hv_utils hv_vmbus hid-hyperv "' > hyperv-drivers.conf
popd
# Fix the SELinux context of the new files
restorecon -f - <<EOF
/etc/sudoers.d/vagrant
/etc/dracut.conf.d/hyperv-drivers.conf
EOF
# Rerun dracut for the installed kernel (not the running kernel):
KERNEL_VERSION=$(rpm -q kernel --qf '%{version}-%{release}.%{arch}\n')
dracut -f /boot/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}

# Seal for deployment
rm -rf /etc/ssh/ssh_host_*
sed -i 's/^HOSTNAME=.*$/HOSTNAME=localhost.localdomain/' /etc/sysconfig/network
rm -rf /etc/udev/rules.d/70-*
%end
