CentOS Docker build scripts
===========================

This repository contains the kickstart files needed to build a CentOS Docker container from scratch

## Necessary tools

This README uses [ami-creator](https://github.com/katzj/ami-creator), however other tools will work as well.
The ami-creator was chosen early on, working well for 5, 6, and 7 when run on a CentOS-6 host. You will at least 10G of free space for the build.

Additionally, the following packages are needed:

 * libguestfs-tools-c
 * python-imgcreate
 * compat-db43 ( for CentOS-5 containers only )


## Build

Building the docker container is a two step procesure. First, we generate an image. Second, we tar it up.

--
```bash
/path/to/ami_creator.py -c /path/to/centos-kickstart.ks -n centos-version-name
```
--

The ami_creator will use the kickstart and the repositories listed inside to create and install the image. If it completes successfully, you will have a container named `centos-version-name.img` in your directory.

From here, this must be extracted and compressed. This is done using `virt-tar-out`.

--
```bash
virt-tar-out -a centos-version-name.img / - | xz --best > centos-version-docker.tar.xz
```
--

Once this is done, you can delete the `.img` file as it is no longer needed.


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
