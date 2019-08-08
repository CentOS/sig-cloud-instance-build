# Build a basic CentOS 6.5 x86_64
lang en_US.UTF-8
keyboard us
timezone --utc UTC
auth --useshadow --enablemd5
rootpw --iscrypted nothing
selinux --enforcing
firewall --service=ssh
bootloader --timeout=1 
network --bootproto=dhcp --device=eth0 --onboot=on
services --enabled=network
zerombr
clearpart --all --initlabel
part / --size 4096 --grow --fstype ext4
reboot

# Repositories
repo --name=CentOS6-Base --baseurl=http://mirrorsnap.centos.org/DATESTAMP/centos/6/os/x86_64
repo --name=CentOS6-Updates --baseurl=http://mirrorsnap.centos.org/DATESTAMP/centos/6/updates/x86_64
repo --name=CentOS6-Extras --baseurl=http://mirrorsnap.centos.org/DATESTAMP/centos/6/extras/x86_64

#
#
# Add all the packages after the base packages
#
%packages --nobase --instLangs=en
@core
system-config-securitylevel-tui
newt-python
system-config-firewall-base
audit
pciutils
bash
coreutils
kernel
grub
e2fsprogs
passwd
policycoreutils
chkconfig
rootfiles
yum
yum-presto
vim-minimal
acpid
openssh-clients
openssh-server
curl
man
rsync
#Allow for dhcp access
dhclient
iputils

# cloud stuff
cloud-init

#stuff we really done want
-kernel-firmware
-xorg-x11-drv-ati-firmware
-iwl6000g2a-firmware
-aic94xx-firmware
-iwl6000-firmware
-iwl100-firmware
-ql2200-firmware
-libertas-usb8388-firmware
-ipw2100-firmware
-atmel-firmware
-iwl3945-firmware
-ql2500-firmware
-rt61pci-firmware
-ipw2200-firmware
-iwl6050-firmware
-iwl1000-firmware
-bfa-firmware
-iwl5150-firmware
-iwl5000-firmware
-ql2400-firmware
-rt73usb-firmware
-ql23xx-firmware
-iwl4965-firmware
-ql2100-firmware
-ivtv-firmware
-zd1211-firmware

%end

#
# Add custom post scripts after the base post.
#
%post
%end

# more ec2-ify
%post --erroronfail
# disable root password based login
cat >> /etc/ssh/sshd_config << EOF
PermitRootLogin without-password
UseDNS no
EOF

sed -i 's|PasswordAuthentication yes|PasswordAuthentication no|' /etc/ssh/sshd_config

# set the firstrun flag
touch /root/firstrun

# lock the root pass
passwd -l root

# chance dhcp client retry/timeouts to resolve #6866
cat  >> /etc/dhcp/dhclient.conf << EOF

timeout 300
retry 60
EOF
# set up ssh key fetching and set a random root passwd if needed
cat >> /etc/rc.local << EOF

# set a random pass on first boot
if [ -f /root/firstrun ]; then 
  dd if=/dev/urandom count=50|md5sum|passwd --stdin root
  passwd -l root
  rm /root/firstrun
fi

if [ ! -d /root/.ssh ]; then
  mkdir -m 0700 -p /root/.ssh
  restorecon /root/.ssh
fi
EOF

# Do some basic cleanup
sed -i -e 's/^ACTIVE_CONSOLES=\/dev\/tty\[1-6\]/ACTIVE_CONSOLES=\/dev\/tty1/' /etc/sysconfig/init

# make sure the kernel can be updated
rm /boot/grub/menu.lst
rm /etc/grub.conf
ln -s /boot/grub/grub.conf /boot/grub/menu.lst
ln -s /boot/grub/grub.conf /etc/grub.conf
cat >> /etc/sysconfig/kernel << EOF
UPDATEDEFAULT=yes
DEFAULTKERNEL=kernel
EOF

# clear out some network stuff 
sed -i "/HWADDR/d" /etc/sysconfig/network-scripts/ifcfg-eth*
rm -f /etc/udev/rules.d/*-persistent-net.rules
touch /etc/udev/rules.d/75-persistent-net-generator.rules
echo NOZEROCONF=yes >> /etc/sysconfig/network


#echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
echo "(Don't worry -- that out-of-space error was expected.)"

%end

