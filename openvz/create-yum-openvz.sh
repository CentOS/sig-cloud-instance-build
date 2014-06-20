#!/bin/bash

usage() { echo "$0 -v <centosver> [-u <baseurl>]" 1>&2; exit 1; }

while getopts u:v:? flag; do
  case $flag in
    v)
      centosver=$OPTARG
      reponame=centos${centosver}
      ;;
    u)
      repourl=$OPTARG
      ;;
    ?)
      usage
      ;;
  esac
done

[[ -z $centosver ]] && usage
if [[ -z $repourl ]] ; then
  if [[ -e ${reponame}.baseurl ]] ; then
    repourl=$(cat ${reponame}.baseurl)
  else
    repourl=http://www.mirrorservice.org/sites/mirror.centos.org/$centosver/os/x86_64/
  fi
fi

# Variables
mount="$(mktemp -d --tmpdir)"
installroot="$mount/installroot"
tmpyumconf=$mount/yum.conf

# Create the installroot
mkdir -p $installroot

# Yum conf to use for the installation
cat > $tmpyumconf << __YUMCONF__
[$reponame]
name=centos $centosver x86_64
baseurl=$repourl
enabled=1
gpgcheck=0
__YUMCONF__

# Install the Core group
yum \
--installroot $installroot \
--disablerepo "*" \
--enablerepo $reponame \
-c $tmpyumconf \
-y groupinstall \
  Core

# Install the necessary rpms
yum \
--installroot $installroot \
--disablerepo "*" \
--enablerepo $reponame \
-c $tmpyumconf \
-y install \
  $(cat ${reponame}.include | xargs)

# Remove firmware files if installed
yum \
--installroot $installroot \
--disablerepo "*" \
--enablerepo $reponame \
-c $tmpyumconf \
-y remove \
  $(cat ${reponame}.exclude | xargs)

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

# Create fstab file, which is required for VZ installations
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
tar -C $installroot -cpzf /root/centos-${centosver}-x86_64-viayum-$(date '+%Y%m%d').tar.gz .

# Cleanup temporary directory
rm -rf $mount
