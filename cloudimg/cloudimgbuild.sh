#!/bin/sh

# cloudimgbuild.sh
#
# Build a CentOS cloud image given a kickstart file and a location,
# either local ISO or remote base repository.

set -e

ME=$(basename ${0})
KSFILE="${1}"
LOCATION="${2}"

function usage()
{
    echo "Usage: ${ME} KSFILE LOCATION

KSFILE    kickstart file path
LOCATION  location of ISO or remote base repository"
}

function cleanup()
{
    test -d ${WORKDIR} && {
        rm -rv ${WORKDIR}
    }
}

trap cleanup ERR SIGINT SIGTERM

if test -z ${KSFILE}; then
    echo "ERROR ${ME} requires KSFILE parameter"
    usage
    exit 1
fi

if test -z ${LOCATION}; then
    echo "ERROR ${ME} requires LOCATION parameter"
    usage
    exit 2
fi

TIMESTAMP=$(date -Is)
TOPDIR=$(pwd)
WORKDIR=/var/tmp/${ME%.sh}-${TIMESTAMP}
DISKFILE=$(basename ${KSFILE%.ks}).qcow2
DISKSIZE=10  # in GB
VMNAME=CentOS-${ME%.sh}-${TIMESTAMP}

# install deps
yum -y install qemu-img qemu-kvm virt-install

# make sure services are running
systemctl start libvirtd

mkdir -p ${WORKDIR}

# copy ks file to workdir
cp ${KSFILE} ${WORKDIR}/install.ks

pushd ${WORKDIR} > /dev/null

# create guest disk
qemu-img create -f qcow2 ${DISKFILE} ${DISKSIZE}G

# install guest
virt-install \
    --location="${LOCATION}" \
    --name "${VMNAME}" \
    --vcpus 8 --memory 4096 \
    --disk ${DISKFILE},size=${DISKSIZE},format=qcow2 \
    --os-variant=centos7.0 \
    --extra-args="ks=file:/install.ks console=ttyS0" \
    --initrd-inject=${WORKDIR}/install.ks \
    --graphics none --noreboot

# undefine libvirt domain
virsh undefine ${VMNAME}

# save guest disk outside workdir
mv ${DISKFILE} ${TOPDIR}/${DISKFILE}

popd > /dev/null

# cleanup
cleanup

echo "==> Image was built and saved at ${TOPDIR}/${DISKFILE}"

exit 0
