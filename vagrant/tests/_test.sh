#!/bin/bash
basedir=$(pwd)
for x in 6 7;do 
  echo testing $x
  mkdir ${basedir}/${x} && cd ${basedir}/${x}
  vagrant init centos/${x}
  vagrant up --provider libvirt
  vagrant ssh --command "rpm -qa --last | head -n1 && uname -a"
  vagrant destroy --force
done
