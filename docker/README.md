# Docker base images

This directory contains kickstarts and scripts used to build the official CentOS 5, 6 and 7 docker base images, found at  https://registry.hub.docker.com/_/centos/

## Building base images on CentOS 6

The official base images are built on a CentOS 6 host.

**TODO: add instructions**

## Building a CentOS 7 or CentOS 6 base image on CentOS 7

Necessary dependencies:

- pykickstart, system RPM (pykickstart-1.99.43.10-1.el7.noarch at the time of writing)
- ami-creator, master branch, commit f2e31fb7, https://github.com/katzj/ami-creator.git
- python-imgcreate, https://git.fedorahosted.org/cgit/livecd/
  - use tag `livecd-tools-21.2` to build a CentOS 7 image
  - use branch `rhel6-branch` to build a CentOS 6 image
- a checkout of this repository

Checkout the necessary dependencies in a base directory called `$BASE`, then run:

```
# cd $BASE
# env PYTHONPATH=$BASE/livecd python ami-creator/ami_creator/ami_creator.py -n localcentos7 \
       -c sig-cloud-instance-build/docker/centos-7.ks
```

This will produce `$BASE/localcentos7.img` which can be imported into docker:

```
# sig-cloud-instance-build/docker/img2docker.sh localcentos7.img localcentos7
```

Building a CentOS 5 image on CentOS 7 is not yet supported, the kickstart post scripts fail on the RPM database fiddling.
