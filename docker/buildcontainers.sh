#!/bin/bash -x
# 
# buildcontainers.sh
#
# Script to build containers using kickstarts
#

# The associative array will keep tabs on name:tag images so 
# we can build many at once


declare -A containers

containers['centos']='6'

# Clean out old containers from current working dir
rm *.tar.xz

for name in ${!containers[@]}
do
  rm -rf /tmp/${name}*

  appliance-creator -c ${name}-${containers["${name}"]}.ks \
    -d -v -t /tmp -o /tmp \
    --name ${name}-${containers["${name}"]} \
    --release ${containers["${name}"]} \
    --format=qcow2

  virt-tar-out -a \
    /tmp/${name}-${containers["${name}"]}/${name}-${containers["${name}"]}-sda.qcow2 / - | \
    xz --best > centos-6-docker.tar.xz

done

