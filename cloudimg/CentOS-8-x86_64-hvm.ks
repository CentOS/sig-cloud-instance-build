# System authorization information
auth --enableshadow --passalgo=sha512
# Reboot after installation
reboot
# Use network installation
url --url="http://mirror.centos.org/centos/8/BaseOS/x86_64/os"
# Firewall configuration
firewall --enabled --service=ssh
firstboot --disable
ignoredisk --only-use=vda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
repo --name="BaseOS" --baseurl="http://mirror.centos.org/centos/8/BaseOS/x86_64/os/" --cost=100
repo --name="AppStream" --baseurl="http://mirror.centos.org/centos/8/AppStream/x86_64/os/" --cost=100
repo --name="extras" --baseurl="http://mirror.centos.org/centos/8/extras/x86_64/os/" --cost=100
#TODO: add update repository once available
#repo --name="updates" --baseurl="http://mirror.centos.org/centos/8/updates/x86_64/os/" --cost=100
# Network information
network  --bootproto=dhcp
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted nothing
selinux --enforcing
services --disabled="kdump" --enabled="sshd,rsyslog,chronyd"
timezone UTC --isUtc
# Disk
bootloader --append="console=tty0 console=ttyS0,115200n81 no_timer_check net.ifnames=0" --location=mbr --timeout=1 --boot-drive=vda
zerombr
clearpart --all --initlabel
part / --fstype="xfs" --ondisk=vda --size=4096 --grow

# Disable kdump via Kickstart add-on
# https://docs.centos.org/en-US/centos/install-guide/Kickstart2/
%addon com_redhat_kdump --disable
%end

%post --erroronfail

# these are installed by default but we don't need them in virt
echo "Removing linux-firmware and kernel-modules packages."
dnf -C -y remove linux-firmware kernel-modules

# Remove firewalld; it is required to be present for install/image building.
echo "Removing firewalld."
dnf -C -y remove firewalld

echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
rm -f /etc/sysconfig/network-scripts/ifcfg-*

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
BOOTPROTOv6="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="yes"
PERSISTENT_DHCLIENT="1"
EOF

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active_profile

# Set python => python3
update-alternatives --set python /usr/bin/python

echo "Cleaning old yum repodata."
dnf clean all

echo "set instance type markers"
echo 'genclo' > /etc/yum/vars/infra

# clean up installation logs"
rm -rf /var/log/dnf.log
rm -rf /var/lib/dnf/*
rm -rf /root/anaconda-ks.cfg
rm -rf /root/original-ks.cfg
rm -rf /var/log/anaconda*
rm -rf /root/anac*

#echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
echo "(Don't worry -- that out-of-space error was expected.)"

%end

%packages --excludedocs
@core
chrony
cloud-init
cloud-utils-growpart
dracut-config-generic
dnf-utils
firewalld
grub2
kernel
NetworkManager
nfs-utils
rsync
tar
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-biosdevname
-dracut-config-rescue
-iprutils
-ivtv-firmware
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
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
-plymouth

%end

