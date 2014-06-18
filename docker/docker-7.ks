install
keyboard us
network  --bootproto=dhcp --device=eth0 --onboot=on
rootpw --iscrypted $1$UKLtvLuY$kka6S665oCFmU7ivSDZzU.
timezone Europe/London --isUtc 
selinux --enforcing
repo --name "CentOS" --baseurl=http://buildlogs.centos.org/centos/7/os/x86_64-latest/


clearpart --all --initlabel
part / --fstype ext4 --size=1024 --grow
reboot

%packages  --excludedocs --nobase
@core
-cronie
-dhclient
-efibootmgr
-ethtool
-initscripts
-iproute
-iptables
-kexec-tools
-dracut-network
-mozjs17
-polkit
-polkit-pkla-compat
-iputils
-kbd
-openssh-server
-postfix
-policycoreutils
-rsyslog
-selinux-policy
-selinux-policy-targeted
-sudo
-vim-minimal
-*-firmware
-kernel*
-NetworkManager
-tuned
-parted
-ModemManager-glib
-ppp
-wpa_supplicant
-teamd
-libteam
-gsettings-desktop-schemas
-glib-networking
-libsoup
-dnsmasq
-man-db




%end

%post
# randomize root password and lock root account
dd if=/dev/urandom count=50 | md5sum | passwd --stdin root
passwd -l root

# create necessary devices
/sbin/MAKEDEV /dev/console

# cleanup unwanted stuff

# ami-creator requires grub during the install, so we remove it (and
# its dependencies) in %post
yum -y remove  grub centos-logos iproute wpa_supplicant NetworkManager \
  iptables mozjs17 ppp teamd
rm -rf /boot

# some packages get installed even though we ask for them not to be,
# and they don't have any external dependencies that should make
# anaconda install them
rpm -e MAKEDEV ethtool upstart initscripts iputils policycoreutils iptables \
    iproute

# Remove files that are known to take up lots of space but leave
# directories intact since those may be required by new rpms.

# locales
find /usr/{{lib,share}/{i18n,locale},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
        -type f \( ! -iname "*utf*" ! -name "en_US" \) | xargs /bin/rm

#  man pages and documentation
find /usr/share/{man,doc,info,gnome/help} \
        -type f | xargs /bin/rm

#  cracklib
find /usr/share/cracklib \
        -type f | xargs /bin/rm

#  sln
rm -f /sbin/sln

#  ldconfig
rm -rf /etc/ld.so.cache
rm -rf /var/cache/ldconfig/*

%end
