#!/bin/bash

# Variables
mount="$(mktemp -d --tmpdir)"
installroot="$mount/installroot"
tmpyumconf=$mount/yum.conf

# Re-create the installroot
mkdir -p $installroot

# Yum conf to use for the installation
cat > $tmpyumconf << __YUMCONF__
[centos7]
name=centos 7 x86_64
baseurl=http://buildlogs.centos.org/centos/7/os/x86_64-latest/
enabled=1
gpgcheck=0
__YUMCONF__

# Install the Core group
yum \
--installroot $installroot \
-c $tmpyumconf \
-y groupinstall \
  Core

# Install the necessary rpms
yum \
--installroot $installroot \
-c $tmpyumconf \
-y install \
  yum-utils \
  wget

# Remove firmware files if installed
yum \
--installroot $installroot \
-c $tmpyumconf \
-y remove \
  ModemManager-glib \
  NetworkManager* \
  alsa-lib \
  centos-logos \
  dracut-network \
  efibootmgr \
  ethtool \
  gsettings-desktop-schemas \
  grub* \
  kbd* \
  kernel* \
  libteam \
  mozjs17 \
  parted \
  pciutils-libs \
  plymouth \
  plymouth-scripts \
  postfix \
  policycoreutils \
  ppp \
  selinux-policy \
  selinux-policy-targeted \
  sudo \
  teamd \
  upstart \
  wpa_supplicant \
  *-firmware

# Clean the yum configuration
yum --installroot $installroot -c $tmpyumconf clean all

# Remove /boot, as that is not required
chroot $installroot rm -rf /boot

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
cat > $installroot/etc/fstab << __FSTAB__
none /dev/pts devpts rw,gid=5,mode=620 0 0
none /dev/shm tmpfs defaults 0 0
__FSTAB__

# GMT to be default, but change for requirement
chroot $installroot cp /usr/share/zoneinfo/GMT /etc/localtime

# Misc post stuff for VZ
ln -s /proc/mounts $installroot/etc/mtab
rm -f $installroot/dev/null
mknod -m 600 $installroot/dev/console c 5 1

# Copy the yum config to the system
cp $tmpyumconf $installroot/etc/yum.repos.d/centos.repo

# Now compress the image
tar -C $installroot -cpzf /root/centos-7-x86_64-viayum-$(date '+%Y%m%d').tar.gz .

rm -rf $mount
