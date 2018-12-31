# This is a minimal CentOS kickstart designed for docker.
# It will not produce a bootable system
# To use this kickstart, run the following command
# livemedia-creator --make-tar \
#   --iso=/path/to/boot.iso  \
#   --ks=centos-7.ks \
#   --image-name=centos-root.tar.xz
#
# Once the image has been generated, it can be imported into docker
# by using: cat centos-root.tar.xz | docker import -i imagename

# Basic setup information
url --url="http://mirror.centos.org/altarch/7/os/i386/"
install
keyboard us
rootpw --lock --iscrypted locked
timezone --isUtc --nontp UTC
selinux --enforcing
firewall --disabled
network --bootproto=dhcp --device=link --activate --onboot=on
shutdown
bootloader --disable
lang en_US

# Repositories to use
repo --name="CentOS" --baseurl=http://mirror.centos.org/altarch/7/os/i386/ --cost=100
## Uncomment for rolling builds
repo --name="Updates" --baseurl=http://mirror.centos.org/altarch/7/updates/i386/ --cost=100

# Disk setup
zerombr
clearpart --all --initlabel
part / --size 3000 --fstype ext4

# Package setup
%packages --excludedocs --instLangs=en --nocore
bind-utils
bash
yum
vim-minimal
centos-release
less
-kernel*
-*firmware
-firewalld-filesystem
-os-prober
-gettext*
-GeoIP
-bind-license
-freetype
iputils
iproute
systemd
rootfiles
-libteam
-teamd
tar
passwd
yum-utils
yum-plugin-ovl


%end

%post --log=/anaconda-post.log
# Post configure tasks for Docker

# remove stuff we don't need that anaconda insists on
# kernel needs to be removed by rpm, because of grubby
rpm -e kernel

yum -y remove bind-libs bind-libs-lite dhclient dhcp-common dhcp-libs \
  dracut-network e2fsprogs e2fsprogs-libs ebtables ethtool file \
  firewalld freetype gettext gettext-libs groff-base grub2 grub2-tools \
  grubby initscripts iproute iptables kexec-tools libcroco libgomp \
  libmnl libnetfilter_conntrack libnfnetlink libselinux-python lzo \
  libunistring os-prober python-decorator python-slip python-slip-dbus \
  snappy sysvinit-tools which linux-firmware GeoIP firewalld-filesystem

yum clean all

#clean up unused directories
rm -rf /boot
rm -rf /etc/firewalld

# Lock roots account, keep roots account password-less.
passwd -l root

#LANG="en_US"
#echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

awk '(NF==0&&!done){print "override_install_langs=en_US.utf8\ntsflags=nodocs";done=1}{print}' \
    < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf
echo 'container' > /etc/yum/vars/infra
echo -e 'i386\n' > /etc/yum/vars/basearch


##Setup locale properly
# Commenting out, as this seems to no longer be needed
#rm -f /usr/lib/locale/locale-archive
#localedef -v -c -i en_US -f UTF-8 en_US.UTF-8

## Remove some things we don't need
rm -rf /var/cache/yum/x86_64
rm -f /tmp/ks-script*
rm -rf /var/log/anaconda
rm -rf /tmp/ks-script*
rm -rf /etc/sysconfig/network-scripts/ifcfg-*
# do we really need a hardware database in a container?
rm -rf /etc/udev/hwdb.bin
rm -rf /usr/lib/udev/hwdb.d/*

## Systemd fixes
# no machine-id by default.
:> /etc/machine-id
# Fix /run/lock breakage since it's not tmpfs in docker
umount /run
systemd-tmpfiles --create --boot
# Make sure login works
rm /var/run/nologin


#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME


%end
