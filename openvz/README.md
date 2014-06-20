# OpenVZ Image

This folder has several files

* openvz-genKS.sh -- A script that generated the kickstart file
* img2vz.sh -- will convert the an VM img to a VZ distributable tar file
* create-yum-openvz.sh -- Script that allows you to create an image from yum
* centos*.include -- packages that need to be installed for the relevant repo
* centos*.exclude -- packages that need to bre removed

## Kickstart file

In order to generate a kickstart file, you need to run the following

```bash
./openvz-genKS.sh -v <centosver> -u <baseurl>
```

where

1. `-v` is the version of centos that we want to build the kickstart for
1. `-u` is the baseurl from where the root of the yum repository is

If the -b is not specified then it will do 2 things

1. Check for a file `centos<centosver>.baseurl` and use that for the baseurl
1. If the above URL is not found, then it will use

```
http://www.mirrorservice.org/sites/mirror.centos.org/$centosver/os/x86_64/
```

The script will automatically append the `centos<centosver>.include` file to be installed, and `centos<centosver>.exclude` to be removed.

The resulting file will be `centos<centosver>.ks`

## Create image using YUM

The script in question here is the `create-yum-openvz.sh`, This again takes 2 arguments as per the above example.

The script will only work on a version of centos that is the same as you are creating the image for, or one version lower. So the one that has been tested is 7 on 7, and 6 on 7

The resulting file will be in `centos-7-x86_64-viayum-20140620.tar.gz` for a centos 7 build in `/root`
