#!/bin/bash
#--------------------------------------------------------------------
# Author: Jim Perrin
# Script: containerbuild.sh
# Desc: This script generates a rootfs tarball, and base Dockerfile
#       Run this script from the directory where the kickstarts are
#       located.
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
# Do we have livemedia-creator
if [ ! -f /usr/sbin/livemedia-creator ]; then
    echo "please install lorax"
    exit 1
fi
# Is the buildroot already present
if [ -d "$BUILDROOT" ]; then
    echo "Buildroot already exists please delete if you wish to build again"
    exit 1
fi

# Fetch the boot.iso for the build.
curl http://mirror.centos.org/centos/"${KSNAME##*-}"/os/x86_64/images/boot.iso -o /tmp/boot-"${KSNAME##*-}".iso

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
