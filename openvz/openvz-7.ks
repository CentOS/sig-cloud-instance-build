install
url --url=http://buildlogs.centos.org/centos/7/os/x86_64-latest/
lang en_GB.UTF-8
keyboard uk
network --device eth0 --bootproto dhcp
rootpw --iscrypted $1$UKLtvLuY$kka6S665oCFmU7ivSDZzU.
authconfig --enableshadow --passalgo=sha512 --enablefingerprint
selinux --enforcing
timezone --utc Europe/London
skipx

clearpart --all --initlabel
part / --fstype ext4 --size=1024 --grow
reboot
%packages --excludedocs --nobase
@Core
yum-utils
wget
-ModemManager-glib
-NetworkManager*
-alsa-lib
-centos-logos
-dracut-network
-efibootmgr
-ethtool
-gsettings-desktop-schemas
-kbd*
-kernel*
-libteam
-mozjs17
-parted
-pciutils-libs
-plymouth
-plymouth-scripts
-postfix
-policycoreutils
-ppp
-selinux-policy
-selinux-policy-targeted
-sudo
-teamd
-upstart
-wpa_supplicant
-*-firmware
%end

%post
# cleanup unwanted stuff, that might still get installed
yum -y remove grub* centos-logos plymouth* kernel*

# Remove /boot, as that is not required
rm -rf /boot

# Remove files that are known to take up lots of space but leave
# directories intact since those may be required by new rpms.

# locales
find $installroot/usr/{{lib,share}/{i18n,locale},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
        -type f \( ! -iname "*utf*" ! -name "en_US" \) | xargs /bin/rm

#  cracklib
find $installroot/usr/share/cracklib \
        -type f | xargs /bin/rm

#  sln
rm -f $installroot/sbin/sln

#  ldconfig
rm -rf $installroot/etc/ld.so.cache
rm -rf $installroot/var/cache/ldconfig/*

# Create fstab file, which is required for VZ installtions
cat > /etc/fstab << __FSTAB__
none /dev/pts devpts rw,gid=5,mode=620 0 0
none /dev/shm tmpfs defaults 0 0
__FSTAB__

# GMT to be default, but change for requirement
cp /usr/share/zoneinfo/GMT /etc/localtime

# Misc post stuff for VZ
ln -s /proc/mounts /etc/mtab
rm -f /dev/null
mknod -m 600 /dev/console c 5 1

# Add a temporary yum repository to the config
cat > /etc/yum.repo.d/centos.repo << __YUMCONF__
[centos7]
name=centos 7 x86_64
baseurl=http://buildlogs.centos.org/centos/7/os/x86_64-latest/
enabled=1
gpgcheck=0
__YUMCONF__

%end
