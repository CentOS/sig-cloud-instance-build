#!/bin/sh
#To see all options in koji -p command check "koji -p cbs image-build --help"
set -eu

usage()
{
  cat << EOF
usage: $(basename $0) <argument>
  where <argument> is one of:
    6   -- build Vagrant images for CentOS 6
    7   -- build Vagrant images for CentOS 7
    all -- build Vagrant images for both CentOS 6 and 7
EOF
  exit 1
}


build_vagrant_image()
{
  # The kickstart files are in the same directory as this script
  KS_DIR=$(dirname $0)
  EL_MAJOR=$1
  koji -p cbs image-build \
    centos-${EL_MAJOR} 1  bananas${EL_MAJOR}-el${EL_MAJOR} \
    http://mirror.centos.org/centos/${EL_MAJOR}/os/x86_64/ x86_64 \
    --release=1 \
    --distro RHEL-${EL_MAJOR}.0 \
    --ksver RHEL${EL_MAJOR} \
    --kickstart=${KS_DIR}/centos${EL_MAJOR}.ks \
    --format=qcow2 \
    --format=vsphere-ova \
    --format=rhevm-ova \
    --ova-option vsphere_ova_format=vagrant-virtualbox \
    --ova-option rhevm_ova_format=vagrant-libvirt \
    --ova-option vagrant_sync_directory=/vagrant \
    --repo http://mirror.centos.org/centos/${EL_MAJOR}/extras/x86_64/\
    --repo http://mirror.centos.org/centos/${EL_MAJOR}/updates/x86_64/\
    --scratch \
    --nowait \
    --disk-size=40
}


if [ $# -ne 1 ]; then
  usage
fi

case $1 in
  6)
    build_vagrant_image 6
    ;;
  7)
    build_vagrant_image 7
    ;;
  all)
    build_vagrant_image 6
    build_vagrant_image 7
    ;;
  *)
    usage
    ;;
esac

