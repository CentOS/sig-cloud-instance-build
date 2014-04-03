#!/bin/bash
#
# This script imports a raw image into Docker consumeable tarball.  It takes one
# arguments: the name of the image file

usage() {
    echo "usage: $(basename $0) <image>"
    exit 1
}

image="$1"

if [[ -z $1 ]]; then
    usage
fi

mount="$(mktemp -d --tmpdir)"
mount -o loop "$image" "$mount"

cd "$mount"
tar -cpSf - --acls --selinux --xattrs * | bzip2 > ${image}.tar.bz2
cd - >& /dev/null
umount "$mount"
rmdir "$mount"
