install
url --url=http://mirror.centos.org/centos/5/os/x86_64/
lang en_US.UTF-8
keyboard uk
network --device eth0 --bootproto dhcp
rootpw --iscrypted $1$UKLtvLuY$kka6S665oCFmU7ivSDZzU.
authconfig --enableshadow --passalgo=sha512
selinux --enforcing
timezone --utc UTC
repo --name="CentOS" --baseurl=http://mirror.centos.org/centos/5.11/os/x86_64/ --cost=100
repo --name="selinux" --baseurl=http://mirror.centos.org/centos/5.11/centosplus/x86_64/ --cost=100

clearpart --all --initlabel
part / --fstype ext4 --size=1024 --grow
reboot
%packages  --nobase
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
libselinux-utils
-kernel
rootfiles

%end

%post --nochroot --erroronfail
# We need to convert the rpmdb, because rpm in c5 gets confused
if file "$INSTALL_ROOT"/var/lib/rpm/Packages | grep -q "version 9"; then
  pushd "$INSTALL_ROOT"/var/lib/rpm 2>/dev/null || exit 1
  rm -f __db*
  for f in * ; do
    db_dump "$f" | db43_load "$f".43 || exit 1
    mv "$f".43 "$f"
  done
  popd 2>/dev/null
fi
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
rpm -e policycoreutils passwd openldap libuser iscsi-initiator-utils \
  mkinitrd


# Can't remove docs on c5 due to a bug similar to 
# https://bugzilla.redhat.com/show_bug.cgi?id=515911
# Keep yum from installing documentation. It takes up too much space.
#sed -i '/distroverpkg=centos-release/a tsflags=nodocs' /etc/yum.conf

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME



# nuking the locales breaks things. Lets not do that anymore strip
# most of the languages from the archive. stolen from
# https://bugzilla.redhat.com/show_bug.cgi?id=156477#c28
localedef --delete-from-archive $(localedef --list-archive | \
    grep -v -i ^en | xargs )
# prep the archive template
mv /usr/lib/locale/locale-archive  /usr/lib/locale/locale-archive.tmpl
# rebuild archive
/usr/sbin/build-locale-archive
#empty the template
:>/usr/lib/locale/locale-archive.tmpl

#  man pages and documentation
find /usr/share/{man,doc,info,gnome/help} -type f -delete

#  sln
rm -f /sbin/sln

#  ldconfig
rm -rf /etc/ld.so.cache
rm -rf /var/cache/ldconfig/*

# Add centosplus repo enabled by default, with includepkg for
# libselinux updates until this patch lands in upstream.


cat >/etc/yum.repos.d/libselinux.repo <<EOF
[libselinux]
name=CentOS-\$releasever - libselinux
mirrorlist=http://mirrorlist.centos.org/?release=\$releasever&arch=\$basearch&repo=centosplus
#baseurl=http://mirror.centos.org/centos/\$releasever/centosplus/\$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
includepkgs=libselinux*

EOF

# Clean up after the installer.
rm -f /etc/rpm/macros.imgcreate



%end
