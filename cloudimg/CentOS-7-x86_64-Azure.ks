auth --enableshadow --passalgo=sha512
reboot
url --url="mirror.centos.org/centos/7/os/x86_64"
firewall --enabled --service=ssh
firstboot --disable
ignoredisk --only-use=vda
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
repo --name "os" --baseurl="http://mirror.centos.org/centos/7/os/x86_64/" --cost=100
repo --name "updates" --baseurl="http://mirror.centos.org/centos/7/updates/x86_64/" --cost=100
repo --name "extras" --baseurl="http://mirror.centos.org/centos/7/extras/x86_64/" --cost=100
# Network information
network  --bootproto=dhcp
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted thereisnopasswordanditslocked
selinux --enforcing
services --disabled="kdump" --enabled="NetworkManager,sshd,rsyslog,chronyd"
timezone UTC --isUtc --ntpservers 0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org
# Disk
bootloader --append="console=tty0" --location=mbr --timeout=1 --boot-drive=vda
zerombr
clearpart --all --initlabel
# use a separate /boot partition with recommended 1GiB size and xfs filesystem
part /boot --fstype="xfs" -ondisk=vda --size=1000
part / --fstype="xfs" --ondisk=vda --size=4096 --grow

%post --erroronfail
passwd -d root
passwd -l root

# setup systemd to boot to the right runlevel
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

yum -C -y remove linux-firmware

sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF

echo "virtual-guest" > /etc/tuned/active_profile

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

systemctl mask tmp.mount

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

yum clean all

# XXX instance type markers - MUST match CentOS Infra expectation
echo 'azure' > /etc/yum/vars/infra

# chance dhcp client retry/timeouts to resolve #6866
cat  >> /etc/dhcp/dhclient.conf << EOF

timeout 300;
retry 60;
EOF

echo "Fixing SELinux contexts."
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

# reorder console entries
sed -i 's/console=tty0/console=tty0 console=ttyS0,115200n8/' /boot/grub2/grub.cfg

%end

%packages
@core
chrony
WALinuxAgent
dracut-config-generic
dracut-norescue
firewalld
grub2
kernel
nfs-utils
rsync
tar
yum-utils
-NetworkManager
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-biosdevname
-iprutils
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
-plymouth

%end

