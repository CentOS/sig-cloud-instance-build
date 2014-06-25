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

cat > $reponame.ks << __KSFILE__
install
url --url=$repourl
lang en_GB.UTF-8
keyboard uk
network --device eth0 --bootproto dhcp
rootpw --iscrypted \$1\$UKLtvLuY\$kka6S665oCFmU7ivSDZzU.
authconfig --enableshadow --passalgo=sha512 --enablefingerprint
selinux --enforcing
timezone --utc Europe/London
skipx

clearpart --all --initlabel
part / --fstype ext4 --size=1024 --grow
reboot
%packages --excludedocs --nobase
@Core
$(cat ${reponame}.include)
$(cat ${reponame}.exclude | awk '{print "-"$1}')
%end

%post
# cleanup unwanted stuff, that might still get installed
yum -y remove grub* centos-logos plymouth* kernel*

# Remove /boot, as that is not required
rm -rf /boot

# Remove files that are known to take up lots of space but leave
# directories intact since those may be required by new rpms.

# locales
find /usr/{{lib,share}/{i18n,locale},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \\
        -type f \( ! -iname "*utf*" ! -name "en_US" \) | xargs /bin/rm

#  cracklib
find /usr/share/cracklib \\
        -type f | xargs /bin/rm

#  sln
rm -f /sbin/sln

#  ldconfig
rm -rf /etc/ld.so.cache
rm -rf /var/cache/ldconfig/*

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
[${reponame}]
name=centos ${centosver} x86_64
baseurl=${repourl}
enabled=1
gpgcheck=0
__YUMCONF__

%end
__KSFILE__
