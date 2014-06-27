install
url --url=http://mirror.centos.org/centos/6/os/x86_64/
lang en_US.UTF-8
keyboard uk
network --device eth0 --bootproto dhcp
rootpw --iscrypted $1$UKLtvLuY$kka6S665oCFmU7ivSDZzU.
authconfig --enableshadow --passalgo=sha512 --enablefingerprint
selinux --enforcing
timezone --utc Europe/London
repo --name="CentOS" --baseurl=http://mirror.centos.org/centos/6/os/x86_64/ --cost=100
repo --name="Updates" --baseurl=http://mirror.centos.org/centos-6/6/updates/x86_64/ --cost=100
# CentOSPlus is here ONLY for a libselinux patch.
# Once 6.6 is released, this should be removed
# http://lists.centos.org/pipermail/centos-devel/2014-May/010345.html
repo --name="CentOSPlus" --baseurl=http://mirror.centos.org/centos-6/6/centosplus/x86_64/ --cost=1000

clearpart --all --initlabel
part / --fstype ext4 --size=1024 --grow
reboot
%packages  --excludedocs --nobase
vim-minimal
yum
bash
bind-utils
grub
centos-release
shadow-utils
findutils
iputils
grub
-*-firmware

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
rpm -e grub redhat-logos
rm -rf /boot

# some packages get installed even though we ask for them not to be,
# and they don't have any external dependencies that should make
# anaconda install them
rpm -e ethtool policycoreutils iptables \
    iproute

# Keep yum from installing documentation. It takes up too much space.
sed -i '/distroverpkg=centos-release/a tsflags=nodocs' /etc/yum.conf

# Remove files that are known to take up lots of space but leave
# directories intact since those may be required by new rpms.

# locales
#find /usr/{{lib,share}/{i18n,locale},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
#        -type f \( ! -iname "*utf*" ! -name "en_US" ! -name\) | xargs /bin/rm

rm -f /usr/lib/locale/locale-archive

#  man pages and documentation
find /usr/share/{man,doc,info,gnome/help} \
        -type f | xargs /bin/rm

#  cracklib
#find /usr/share/cracklib \
#        -type f | xargs /bin/rm

#  sln
rm -f /sbin/sln

#  ldconfig
rm -rf /etc/ld.so.cache
rm -rf /var/cache/ldconfig/*

%end
