#!/bin/sh
set -e # immediately fail when a command fails

cd ~/sync
vagrant up

UpdtPkgs=$(vagrant ssh -c "sudo yum clean all && sudo yum -d0 list updates | wc -l")
echo 'Updates backlog :' ${UpdtPkgs}
#if [ $UpdtPkgs -gt 10 ]; then
#    echo 'More than 10 packages due an update!'
#    exit 1
#else
    vagrant ssh -c 'cd sync; sudo env "PATH=$PATH" ./runtests.sh'
#fi
