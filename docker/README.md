CentOS Docker build scripts
===========================

This repository contains the kickstart files needed to build a CentOS Docker container from scratch

## Necessary tools

The Docker base containers for 6 and 7 are now created with tools included in CentOS itself. This means we're no longer dependent on the 3rd party [ami-creator](https://github.com/katzj/ami-creator). 

The following packages and dependencies are needed:

 * libguestfs-tools-c
 * lorax
 * virt-install


## Build

Building the docker container is a 3 step procesure. First we fetch the boot.iso for the version we're building. Next, we generate an image. Finally, we tar it up. In the example below, we'll build a base archive for 7.

--
```bash
# curl http://mirror.centos.org/centos/7/os/x86_64/images/boot.iso -o /tmp/boot7.iso
# livemedia-creator --make-disk --iso=/tmp/boot7.iso --ks=/path/to/centos-7.ks --image-name=centos-7-base
# virt-tar-out -a /var/tmp/centos-7-base / - | xz --best > centos-version-docker.tar.xz
```
--




Once this is done, you can delete the `boot.iso` and `/var/tmp/centos-7-base` file as it is no longer needed.


## Usage

From here, you can either import the docker container via

```
cat centos-version-docker.tar.xz | docker import - container-name
```

Or you can create a Dockerfile to build the image directly in docker.

```
FROM scratch
MAINTAINER you<your@email.here> - ami_creator
ADD centos-version-docker.tar.xz /
```
