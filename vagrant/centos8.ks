#url --mirrorlist=http://mirrorlist.centos.org/?release=8&arch=x86_64&repo=BaseOS&infra=stock
#repo --name=AppStream --mirrorlist=http://mirrorlist.centos.org/?release=8&arch=x86_64&repo=AppStream&infra=stock
text
keyboard --vckeymap us
lang en_US
skipx
network --device eth0 --bootproto dhcp
rootpw --plaintext vagrant
firewall --disabled
timezone --utc UTC
services --enabled=vmtoolsd
# The biosdevname and ifnames options ensure we get "eth0" as our interface
# even in environments like virtualbox that emulate a real NW card
bootloader --timeout=1 --append="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop"
zerombr
clearpart --all --drives=vda
part / --fstype=xfs --asprimary --size=1024 --grow --ondisk=vda

user --name=vagrant --plaintext --password=vagrant

reboot

%packages --instLangs=en
bash-completion
man-pages
bzip2
rsync
nfs-utils
cifs-utils
chrony
yum-utils
hyperv-daemons
open-vm-tools
# Vagrant boxes aren't normally visible, no need for Plymouth
-plymouth
# Microcode updates cannot work in a VM
-microcode_ctl
# Firmware packages are not needed in a VM
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6050-firmware
-iwl7260-firmware
# Don't build rescue initramfs
-dracut-config-rescue
%end

# kdump needs to reserve 160MB + 2bits/4kB RAM, and automatic allocation only
# works on systems with at least 2GB RAM (which excludes most Vagrant boxes)
# CBS doesn't support %addon yet https://bugs.centos.org/view.php?id=12169
%addon com_redhat_kdump --disable
%end

%post
# configure swap to a file
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

# sudo
echo "%vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

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

# Fix for issue #76, regular users can gain admin privileges via su
ex -s /etc/pam.d/su <<'EOF'
# allow vagrant to use su, but prevent others from becoming root or vagrant
/^account\s\+sufficient\s\+pam_succeed_if.so uid = 0 use_uid quiet$/
:append
account		[success=1 default=ignore] \\
				pam_succeed_if.so user = vagrant use_uid quiet
account		required	pam_succeed_if.so user notin root:vagrant
.
:update
:quit
EOF

# systemd should generate a new machine id during the first boot, to
# avoid having multiple Vagrant instances with the same id in the local
# network. /etc/machine-id should be empty, but it must exist to prevent
# boot errors (e.g.  systemd-journald failing to start).
:>/etc/machine-id

echo 'vag' > /etc/yum/vars/infra

# Blacklist the floppy module to avoid probing timeouts
echo blacklist floppy > /etc/modprobe.d/nofloppy.conf
chcon -u system_u -r object_r -t modules_conf_t /etc/modprobe.d/nofloppy.conf

# Customize the initramfs
pushd /etc/dracut.conf.d
# Enable VMware PVSCSI support for VMware Fusion guests.
echo 'add_drivers+=" vmw_pvscsi "' > vmware-fusion-drivers.conf
echo 'add_drivers+=" hv_netvsc hv_storvsc hv_utils hv_vmbus hid-hyperv "' > hyperv-drivers.conf
# There's no floppy controller, but probing for it generates timeouts
echo 'omit_drivers+=" floppy "' > nofloppy.conf
popd
# Fix the SELinux context of the new files
restorecon -f - <<EOF
/etc/sudoers.d/vagrant
/etc/dracut.conf.d/vmware-fusion-drivers.conf
/etc/dracut.conf.d/hyperv-drivers.conf
/etc/dracut.conf.d/nofloppy.conf
EOF

# Rerun dracut for the installed kernel (not the running kernel):
KERNEL_VERSION=$(rpm -q kernel --qf '%{version}-%{release}.%{arch}\n')
dracut -f /boot/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}

# Seal for deployment
rm -rf /etc/ssh/ssh_host_*
hostnamectl set-hostname localhost.localdomain
rm -rf /etc/udev/rules.d/70-*
%end
