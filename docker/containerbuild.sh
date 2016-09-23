#!/bin/bash
#--------------------------------------------------------------------
# Author: Jim Perrin
# Script: containerbuild.sh
# Desc: This script generates a rootfs tarball, and base Dockerfile
#       Run this script from the directory where the kickstarts are
#       located.
# Modified: Carl Thompson
# Update: Updated to use local boot.iso instead of downloading
# require preperation but is faster in building the image
# Requires: lorax libvirt-daemon libvirt-client virt-install qemu-kvm
#           systemctl start libvirtd
#--------------------------------------------------------------------
#### Basic VAR definitions
USAGE="USAGE: $(basename "$0") kickstart"
KICKSTART="$1"
KSNAME=${KICKSTART%.*}
BUILDDATE=$(date +%Y%m%d)
BUILDROOT=/var/tmp/containers/$BUILDDATE/$KSNAME
CONT_ARCH=$(uname -m)

#### Test for script requirements
# Did we get passed a kickstart
if [ "$#" -ne 1 ]; then
    echo "$USAGE"
    exit 1
fi

# Test for package requirements
PACKAGES=( lorax libvirt-daemon libvirt-client virt-install qemu-kvm )
for Element in "${PACKAGES[@]}"
  do
    TEST=`rpm -q $Element`
    if [ "$?" -gt 0 ]
    then echo "RPM $Element missing"
    exit 1
    fi
done

# Test for active libvirtd
if [ ! `systemctl is-active libvirtd` ne "is-active" ]
then echo "libvirtd must be running"
exit 1
fi

# Is the buildroot already present
if [ -d "$BUILDROOT" ]; then
    echo "The Build root, $BUILDROOT, already exists.  Would you like to remove it? [y/N] "
    read REMOVE
    if [ "$REMOVE" == "Y" ] || [ "$REMOVE" == "y" ]
      then
      if [ ! "$BUILDROOT" == "/" ]
        then
        rm -rf $BUILDROOT
      fi
    else
      exit 1
    fi
fi

# Fetch the boot.iso for the build.
if [ ! -e "/tmp/boot-${KSNAME##*-}.iso" ]
  then
  curl http://mirror.centos.org/centos/"${KSNAME##*-}"/os/x86_64/images/boot.iso -o /tmp/boot-"${KSNAME##*-}".iso
fi

# Build the rootfs
time livemedia-creator --logfile=/tmp/"$KSNAME"-"$BUILDDATE".log --make-tar --ks "$KICKSTART" --image-name="$KSNAME"-docker.tar.xz  --iso /tmp/boot-"${KSNAME##*-}".iso

# Put the rootfs someplace
mkdir -p $BUILDROOT/docker
mv /var/tmp/"$KSNAME"-docker.tar.xz $BUILDROOT/docker/

# Create a Dockerfile to go along with the rootfs.

cat << EOF > $BUILDROOT/docker/Dockerfile
FROM scratch
MAINTAINER https://github.com/CentOS/sig-cloud-instance-images
ADD $KSNAME-docker.tar.xz /

LABEL name="CentOS Base Image" \\
    vendor="CentOS" \\
    license="GPLv2" \\
    build-date="$BUILDDATE"

CMD ["/bin/bash"]
EOF

# Create cccp.yaml for testing
cat << EOF > $BUILDROOT/docker/cccp.yaml
job-id: centos-base
test-skip: true
EOF
