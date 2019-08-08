# Kickstart for creating a CentOS 7 Azure VM

# System authorization information
auth --enableshadow --passalgo=sha512

# Use text install
text

# Do not run the Setup Agent on first boot
firstboot --disable

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
network --bootproto=dhcp
network --hostname=localhost.localdomain
firewall --enabled --service=ssh

# Use network installation
url --url="mirrorsnap.centos.org/DATESTAMP/centos/7/os/x86_64" 
repo --name "os" --baseurl="http://mirrorsnap.centos.org/DATESTAMP/centos/7/os/x86_64/" --cost=100
repo --name "updates" --baseurl="http://mirrorsnap.centos.org/DATESTAMP/centos/7/updates/x86_64/" --cost=100
repo --name "extras" --baseurl="http://mirrorsnap.centos.org/DATESTAMP/centos/7/extras/x86_64/" --cost=100
# Root password
rootpw --iscrypted nothing
selinux --enforcing

# System services
services --disabled="kdump,abrtd" --enabled="network,sshd,rsyslog,chronyd,waagent,dnsmasq,NetworkManager"
%addon com_redhat_kdump --disable
%end

# System timezone
timezone UTC --isUtc

# Disk partitioning information
zerombr
clearpart --all --initlabel
part /boot --fstype="xfs" --size=500
part / --fstype="xfs" --size=1 --grow --asprimary

# System bootloader configuration
bootloader --append="console=tty0" --location=mbr --timeout=1

# Don't configure X
skipx

# Power down the machine after install
poweroff


%packages
@base
@console-internet
chrony
cifs-utils
sudo
python-pyasn1
parted
WALinuxAgent
hypervkvpd
-dracut-config-rescue
%end


%post --erroronfail 
#!/bin/bash

passwd -d root
passwd -l root

# setup systemd to boot to the right runlevel
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

# Set the kernel cmdline
sed -i 's/^\(GRUB_CMDLINE_LINUX\)=".*"$/\1="console=tty1 console=ttyS0,115200n8 earlyprintk=ttyS0,115200 rootdelay=300 net.ifnames=0 scsi_mod.use_blk_mq=y"/g' /etc/default/grub


# Enable grub serial console
echo 'GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"' >> /etc/default/grub
sed -i 's/^GRUB_TERMINAL_OUTPUT=".*"$/GRUB_TERMINAL="serial console"/g' /etc/default/grub

# Set default kernel
cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# Rebuild grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg

# Ensure Hyper-V drivers are built into initramfs
echo -e "\nadd_drivers+=\"hv_vmbus hv_netvsc hv_storvsc\"" >> /etc/dracut.conf
kversion=$( rpm -q kernel | sed 's/kernel\-//' )
dracut -v -f "/boot/initramfs-${kversion}.img" "$kversion"

# Import CentOS public key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

# Configure network
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
USERCTL=no
PEERDNS=yes
IPV6INIT=no
NM_CONTROLLED=no
PERSISTENT_DHCLIENT="1"
EOF

cat << EOF > /etc/sysconfig/network
NETWORKING=yes
NOZEROCONF=yes
HOSTNAME=localhost.localdomain
EOF


# Disable persistent net rules
rm -f /etc/udev/rules.d/70* 2>/dev/null
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules

# Disable NetworkManager handling of the SRIOV interfaces
cat <<EOF > /etc/udev/rules.d/68-azure-sriov-nm-unmanaged.rules
# Accelerated Networking on Azure exposes a new SRIOV interface to the VM.
# This interface is transparently bonded to the synthetic interface,
# so NetworkManager should just ignore any SRIOV interfaces.
SUBSYSTEM=="net", DRIVERS=="hv_pci", ACTION=="add", ENV{NM_UNMANAGED}="1"

EOF

# Change dhcp client retry/timeouts to resolve #6866
cat  >> /etc/dhcp/dhclient.conf << EOF
timeout 300
retry 60
EOF

# Blacklist the nouveau driver as it is incompatible
# with Azure GPU instances.
cat << EOF > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

echo "Fixing SELinux contexts."
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

# Modify yum, clean cache
echo "http_caching=packages" >> /etc/yum.conf
yum clean all

# XXX instance type markers - MUST match CentOS Infra expectation
echo 'azure' > /etc/yum/vars/infra

# Set tuned profile
echo "virtual-guest" > /etc/tuned/active_profile

%end
