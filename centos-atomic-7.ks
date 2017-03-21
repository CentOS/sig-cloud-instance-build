# This is a minimal CentOS install to serve as the docker atomic container image.
#
# To keep this image minimal it only installs English language. You need to change
# dnf configuration in order to enable other languages.

url --url="http://mirrors.kernel.org/centos/7/os/x86_64/"
install
bootloader --disabled
timezone --isUtc --nontp UTC
rootpw --lock --iscrypted locked

keyboard us
lang en_US

firewall --disabled
network --bootproto=dhcp --device=link --activate --onboot=on

shutdown

# Disk setup
zerombr
clearpart --all --initlabel
part / --size 3000 --fstype ext4 --grow

# Add nessasary repo for microdnf
repo --name="microdnf" --baseurl="https://buildlogs.centos.org/cah-0.0.1" --cost=100
repo --name="updates" --baseurl="http://mirror.centos.org/centos/7/updates/x86_64"

%packages --excludedocs --instLangs=en --nocore
bash
centos-release
microdnf
-audit-libs
-basesystem
-bind-libs-lite
-bind-license
-bind-license
-binutils
-cpio
-cracklib
-cracklib-dicts
-cryptsetup-libs
-dbus
-dbus-libs
-device-mapper
-device-mapper-libs
-dhclient
-dhcp-common
-dhcp-libs
-diffutils
-dosfstools
-dracut
-dracut-network
-e2fsprogs
-ethtool
-firewalld-filesystem
-*firmware
-freetype
-fuse-libs
-GeoIP
-gettext*
-gpg-pubkey
-gzip
-hardlink
-hostname
-initscripts
-iproute
-iptables
-iputils
-kernel
-kexec-tools
-kmod
-kmod-libs
-kpartx
-libblkid
-libmnl
-libmount
-libnetfilter_conntrack
-libnfnetlink
-libpwquality
-libsemanage
-libss # used by e2fsprogs
-libteam
-libuser
-libutempter
-libuuid
-lzo
-os-prober
-pam
-procps-ng
-qrencode-libs
-shadow-utils
-snappy
-systemd
-systemd-libs
-sysvinit-tools
-tar
-teamd
-ustr

%end

%post --log=/anaconda-post.log --erroronfail
# Post configure tasks for Docker
set -eux

# Remove packages anaconda is insistent on installing
# This list includes packages installed under all modes
microdnf remove acl audit-libs binutils cpio cracklib cracklib-dicts cryptsetup-libs dbus dbus-glib dbus-libs dbus-python device-mapper device-mapper-libs diffutils dracut e2fsprogs e2fsprogs-libs ebtables elfutils-libs firewalld firewalld-filesystem gdbm gzip hardlink ipset ipset-libs iptables kmod kmod-libs kpartx libcap-ng libmnl libnetfilter_conntrack libnfnetlink libpwquality libselinux-python libsemanage libss libuser libutempter pam procps-ng python python-decorator python-firewall python-gobject-base python-libs python-slip python-slip-dbus qemu-guest-agent qrencode-libs shadow-utils systemd systemd-libs tar ustr util-linux xz

microdnf clean all

# Set install langs macro so that new rpms that get installed will
# only install langs that we limit it to.
LANG="en_US"
echo "%_install_langs ${LANG}" > /etc/rpm/macros.image-language-conf
for dir in locale i18n; do
    find /usr/share/${dir} \
      -mindepth  1 -maxdepth 1 -type d \
      -not \( -name "${LANG}" -o -name POSIX \) \
      -exec rm -rfv {} +
done

echo 'container' > /etc/yum/vars/infra

# clear fstab
echo "# fstab intentionally empty for containers" > /etc/fstab

## Remove some things we don't need
rm -rf /boot /etc/firewalld  # unused directories
rm -rf /etc/sysconfig/network-scripts/ifcfg-*
rm -fv usr/share/gnupg/help*.txt
rm /usr/lib/rpm/rpm.daily
rm -rfv /usr/lib64/nss/unsupported-tools/  # unsupported
rm -rfv /var/lib/yum  # dnf info
rm -rfv /usr/share/icons/*  # icons are unused
rm -fv /usr/bin/pinky  # random not-that-useful binary

# statically linked stuff
rm -fv /usr/sbin/{glibc_post_upgrade.x86_64,sln}
ln /usr/bin/ln usr/sbin/sln

# we lose presets by removing /usr/lib/systemd but we do not care
rm -rfv /usr/lib/systemd

# if you want to change the timezone, bind-mount it from the host or reinstall tzdata
rm -fv /etc/localtime
mv /usr/share/zoneinfo/UTC /etc/localtime
rm -rfv  /usr/share/zoneinfo

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

## Systemd fixes
# no machine-id by default.
:> /etc/machine-id

# The file that specifies the /run/lock tmpfile is
# /usr/lib/tmpfiles.d/legacy.conf, which is part of the systemd
# rpm that isn't included in this image. We'll create the /run/lock
# file here manually with the settings from legacy.conf
install -d /run/lock -m 0755 -o root -g root


## Final Pruning
rm -rfv /var/{cache,log}/* /tmp/*

%end
