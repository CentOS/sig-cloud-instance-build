install
url --url=http://mirrors.karan.org/centos/6/os/x86_64/
lang en_US.UTF-8
keyboard uk
network --device eth0 --bootproto dhcp
rootpw --iscrypted $1$UKLtvLuY$kka6S665oCFmU7ivSDZzU.
firewall --service=ssh
authconfig --enableshadow --passalgo=sha512 --enablefingerprint
selinux --enforcing
timezone --utc Europe/London
repo --name="CentOS" --baseurl=http://mirrors.karan.org/centos/6/os/x86_64/ --cost=100
clearpart --all --initlabel
part / --fstype ext4 --size=1024 --grow
reboot
%packages  --excludedocs --nobase
@Core
-MAKEDEV
-aic94xx-firmware
-atmel-firmware
-b43-openfwwf
-bfa-firmware
-cronie
-dhclient
-efibootmgr
-ethtool
-initscripts
-iproute
-iptables
-iptables-ipv6
-iputils
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
-kbd
-kernel-firmware
-libertas-usb8388-firmware
-openssh-server
-postfix
-policycoreutils
-ql2100-firmware
-ql2200-firmware
-ql23xx-firmware
-ql2400-firmware
-ql2500-firmware
-redhat-logos
-rsyslog
-rt61pci-firmware
-rt73usb-firmware
-selinux-policy
-selinux-policy-targeted
-sudo
-upstart
-vim-minimal
-xorg-x11-drv-ati-firmware
-zd1211-firmware
%end

%post
# randomize root password and lock root account
dd if=/dev/urandom count=50 | md5sum | passwd --stdin root
passwd -l root

# cleanup unwanted stuff

# ami-creator requires grub during the install, so we remove it (and
# its dependencies) in %post
rpm -e grub redhat-logos
rm -rf /boot

# some packages get installed even though we ask for them not to be,
# and they don't have any external dependencies that should make
# anaconda install them
rpm -e MAKEDEV ethtool upstart initscripts iputils policycoreutils iptables \
    iproute

# locales
rm -rf /usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
#  docs
rm -rf /usr/share/{man,doc,info,gnome/help}
#  cracklib
rm -rf /usr/share/cracklib
#  i18n
rm -rf /usr/share/i18n
#  sln
rm -rf /sbin/sln
#  ldconfig
rm -rf /etc/ld.so.cache
rm -rf /var/cache/ldconfig/*

%end
