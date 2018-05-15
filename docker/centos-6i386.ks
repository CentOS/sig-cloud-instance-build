# This is a minimal CentOS kickstart designed for docker.
# It will not produce a bootable system
# To use this kickstart, run the following command
# livemedia-creator --make-tar \
#   --iso=/path/to/boot.iso  \
#   --ks=centos-6i386.ks \
#   --image-name=centos-root.tar.xz
#
# Once the image has been generated, it can be imported into docker
# by using: cat centos-root.tar.xz | docker import -i imagename

# Basic setup information
url --url="http://mirrors.kernel.org/centos/6/os/i386/"
install
keyboard us
lang en_US.UTF-8
rootpw --lock --iscrypted locked
authconfig --enableshadow --passalgo=sha512
timezone --isUtc Etc/UTC
selinux --enforcing
firewall --disabled
network --bootproto=dhcp --device=eth0 --activate --onboot=on
reboot
bootloader --location=none

# Repositories to use
repo --name="CentOS" --baseurl=http://mirror.centos.org/centos/6/os/i386/ --cost=100
repo --name="Updates" --baseurl=http://mirror.centos.org/centos/6/updates/i386/ --cost=100

# Disk setup
zerombr
clearpart --all
part / --size 3000 --fstype ext4

%packages  --excludedocs --nobase --nocore
vim-minimal
yum
bash
bind-utils
centos-release
shadow-utils
findutils
iputils
iproute
grub
-*-firmware
passwd
rootfiles
util-linux-ng
yum-plugin-ovl

%end

%post --log=/tmp/anaconda-post.log
# Post configure tasks for Docker

# remove stuff we don't need that anaconda insists on
# kernel needs to be removed by rpm, because of grubby
rpm -e kernel

yum -y remove dhclient dhcp-libs dracut grubby kmod grub2 centos-logos \
  hwdata os-prober gettext* bind-license freetype kmod-libs dracut

yum -y remove  firewalld dbus-glib dbus-python ebtables \
  gobject-introspection libselinux-python pygobject3-base \
  python-decorator python-slip python-slip-dbus kpartx kernel-firmware \
  device-mapper* e2fsprogs-libs sysvinit-tools kbd-misc libss upstart

#clean up unused directories
rm -rf /boot
rm -rf /etc/firewalld

# Randomize root's password and lock
dd if=/dev/urandom count=50 | md5sum | passwd --stdin root
passwd -l root

#LANG="en_US"
#echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

awk '(NF==0&&!done){print "override_install_langs='$LANG'\ntsflags=nodocs";done=1}{print}' \
    < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf
echo 'container' > /etc/yum/vars/infra

rm -f /usr/lib/locale/locale-archive

#Setup locale properly
localedef -v -c -i en_US -f UTF-8 en_US.UTF-8

#disable services
for serv in `/sbin/chkconfig|cut -f1`; do /sbin/chkconfig "$serv" off; done;
mv /etc/rc1.d/S26udev-post /etc/rc1.d/K26udev-post


rm -rf /var/cache/yum/*
rm -f /tmp/ks-script*
rm -rf /etc/sysconfig/network-scripts/ifcfg-*

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

%end

