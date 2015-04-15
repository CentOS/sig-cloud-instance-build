install
keyboard us
network  --bootproto=dhcp --device=eth0 --onboot=on
rootpw --iscrypted $1$UKLtvLuY$kka6S665oCFmU7ivSDZzU.
timezone UTC --isUtc 
selinux --enforcing
firewall --disabled
repo --name="CentOS" --baseurl=http://mirror.centos.org/centos/7/os/x86_64/ --cost=100
repo --name="Updates" --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/ --cost=100
repo --name="systemdcontainer" --baseurl=http://dev.centos.org/centos/7/systemd-container/ --cost=100


clearpart --all --initlabel
part / --fstype ext4 --size=1024 --grow
reboot

%packages  --excludedocs --nobase
bind-utils
bash
yum
vim-minimal
centos-release
shadow-utils
less
-kernel*
-*firmware
grub2
-os-prober
-gettext*
-bind-license
-freetype
iputils
iproute
-systemd
systemd-container
firewalld
rootfiles

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

# some packages get installed even though we ask for them not to be,
# and they don't have any external dependencies that should make
# anaconda install them


yum -y remove  grub2 centos-logos hwdata os-prober gettext* \
  bind-license freetype kmod dracut


# firewalld is necessary for building on centos7 but it is not
# necessary in the image. remove it and its requirements.

yum -y remove  firewalld dbus-glib dbus-python ebtables \
  gobject-introspection libselinux-python pygobject3-base \
  python-decorator python-slip python-slip-dbus
rm -rf /etc/firewalld


rm -rf /boot

#delete a few systemd things
rm -rf /etc/machine-id

# Add tsflags to keep yum from installing docs

sed -i '/distroverpkg=centos-release/a tsflags=nodocs' /etc/yum.conf

# Remove files that are known to take up lots of space but leave
# directories intact since those may be required by new rpms.

# locales
# nuking the locales breaks things. Lets not do that anymore
# strip most of the languages from the archive.
localedef --delete-from-archive $(localedef --list-archive | \
grep -v -i ^en | xargs )
# prep the archive template
mv /usr/lib/locale/locale-archive  /usr/lib/locale/locale-archive.tmpl
# rebuild archive
/usr/sbin/build-locale-archive
#empty the template
:>/usr/lib/locale/locale-archive.tmpl


#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME



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
rm -rf /var/cache/yum/* 

# Create repo for systemd-container
cat >/etc/yum.repos.d/systemd.repo <<EOF
[systemdcontainer]
name=CentOS-\$releasever - systemd-container
baseurl=http://dev.centos.org/centos/7/systemd-container/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

EOF



# Clean up after the installer.
rm -f /etc/rpm/macros.imgcreate

# temp fix for systemd /run/lock


%end
