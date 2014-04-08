~/docker/
=========

scripts, configs, kickstarts and utils we need to build
docker images

How to use these files:
----------------------
There is an associative array in the buildcontainers.sh script that needs
an entry for each docker container to be built.

The format is `containers['name']='tag'`

When building on a CentOS host you will need [EPEL](https://fedoraproject.org/wiki/EPEL)
 enabled with the following packages installed:

    appliance-tools
    libguestfs-tools-c

NOTE - At this time, applliance-tools is still working on making its way into 
EPEL official and can be obtained from [here](http://maxamillion.fedorapeople.org/epel/el6/appliance-tools/)
in the mean time.

This script needs to be run as root or with sudo privs

    ./buildcontainers.sh 

The resulting container image(s) will be located in the current working dir 
with the format `name-tag.tar.xz` (example: `centos-6.tar.xz`)


