#!/bin/bash

# This should work on any CentOS Linux 7 machine
# assuming it is either a baremetal box or has nested virt
# capability

yum -y install rsync libvirt qemu-kvm centos-release-scl
service libvirtd start
yum -y install sclo-vagrant1
scl enable sclo-vagrant1 _test.sh

