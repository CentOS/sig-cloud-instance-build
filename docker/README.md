CentOS Docker build scripts
===========================

This repository contains the kickstart files needed to build a CentOS Docker container from scratch

## Necessary tools

The Docker base containers for 6 and 7 are now created with tools included in CentOS itself. This means we're no longer dependent on the 3rd party [ami-creator](https://github.com/katzj/ami-creator).
This method does NOT work for CentOS-5 base containers.

The following packages and dependencies are needed:

 * libguestfs-tools-c
 * lorax
 * virt-install


## Build

In order to build the container, a rootfs tarball and Dockerfile are required.
We use lorax's livemedia-creator to create the rootfs tarball, but you'll need
a boot.iso start the process. Below you can find a set of example commands
that will produce a suitable rootfs tarball. Additionally you can also run the
containerbuild.sh script, which will fetch the iso, create the rootfs, and
generate a Dockerfile for you.

### The hard way
--
```bash
# curl http://mirror.centos.org/centos/7/os/x86_64/images/boot.iso -o /tmp/boot7.iso
# sudo livemedia-creator --make-tar --iso=/tmp/boot7.iso --ks=/path/to/centos-7.ks --image-name=centos-7-docker.tar.xz
```
--

Once livemedia-creator has finished, you can use the Dockerfile-TEMPLATE to
create a suitable Dockerfile.

### The easy way

After you've run this command, your rootfs tarball and Dockerfile will be
waiting for you in `/var/tmp/containers/<datestamp>/`

--
```bash
# sudo ./containerbuild.sh centos-7.ks
```
--

Once this is done, you can delete the `boot.iso` files in /tmp if you wish.


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
