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
# Requires: anaconda lorax
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
PACKAGES=( anaconda-tui lorax yum-langpacks)
for Element in "${PACKAGES[@]}"
  do
    TEST=`rpm -q --whatprovides $Element`
    if [ "$?" -gt 0 ]
    then echo "RPM $Element missing"
    exit 1
    fi
done

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

# Build the rootfs
time livemedia-creator --logfile=/tmp/"$KSNAME"-"$BUILDDATE".log \
     --no-virt --make-tar --ks "$KICKSTART" \
     --image-name="$KSNAME"-docker.tar.xz --project "CentOS 7 Docker" \
     --releasever "7"

# Put the rootfs someplace
mkdir -p $BUILDROOT/docker
mv /var/tmp/"$KSNAME"-docker.tar.xz $BUILDROOT/docker/

# Create a Dockerfile to go along with the rootfs.

cat << EOF > $BUILDROOT/docker/Dockerfile
FROM scratch
ADD $KSNAME-docker.tar.xz /

LABEL org.label-schema.schema-version = "1.0" \\
    org.label-schema.name="CentOS Base Image" \\
    org.label-schema.vendor="CentOS" \\
    org.label-schema.license="GPLv2" \\
    org.label-schema.build-date="$BUILDDATE"

CMD ["/bin/bash"]
EOF

# Create cccp.yaml for testing
cat << EOF > $BUILDROOT/docker/cccp.yaml
job-id: centos-base
test-skip: true
EOF
