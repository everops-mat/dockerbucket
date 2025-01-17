# A simple base docker image for OpenSuse 
20230410

My OpenSuse Docker Images are pretty standard. Nothing specific here. 
Currently the default version is opensuse/leap:15.

Note: I run OpenSuse Tumbleweed on my desktop, but my container work 
with OpenSuse is using OpenSuse Leap.

## OpenSuse Leap Docker Image

### Setup FROM and enable a version choice.

First let's set the where we'll pull from. I use `podman` and 
`docker` equally, so on I give the full path to the FROM image.

An `ARG` for the version, `VER` is there. This can be overridden 
with `--build-arg 'VER=<version>'`.

```Dockerfile
<<base.image>>=
ARG VER=15
FROM docker.io/opensuse/leap:${VER}
@  % def VER
```

### Setup user specific arguments.

Setup a base username, uid, gid, and work directory with some defaults. All of these can be overridden with `-build-arg "ARG=VALUE"`.

```Dockerfile
<<base.userargs>>=
ARG baseUSER="mek"
ARG baseUID=501
ARG baseGID=501
ARG baseDIR="/work"
@
```

### Add user and work directory

You'll need to be careful here to not change a current directory. For 
example, do not set baseDIR="/bin". 

Add the group, user, (with the home directory of the user ad the work 
directory) and insure the proper ownership on the work directory.

```
<<base.setupuser>>=
RUN groupadd -g ${baseGID} ${baseUSER} &&      \
    useradd -c 'work user' -m -u ${baseUID}    \
    -g ${baseGID} -d ${baseDIR} ${baseUSER} && \ 
    chown -R ${baseUID}:${baseGID} ${baseDIR}
@
```

### Add repos and update software.

First, we'll add any additional repo. If you have additional repos 
you want to enable, add them here.

```
<<base.enablerepos>>=
RUN zypper -n ar -cfp 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_$releasever/' packman \
 && zypper --gpg-auto-import-keys ref \
 && zypper dup --from packman --allow-vendor-change
@
```

### Addtional root changes

We are still root at this point, this is where we add software, make 
additional changes, etc.

```
<<base.addsoftware>>=
RUN zypper ref &&             \
    zypper -n up &&           \
    zypper -n in ed joe tcl vim gcc13 gcc13-c++ gcc13-ada gcc13-fortran \
      make git fossil groff wget curl hostname fpc fpc-src
@
```

The different sections are setup based on how often they may be changed. 
The more likely some will change, the further down they should be to help 
minimize the layers that need to be rebuilt.

### Make sure we the user, volume, and workdir setup

```
<<base.end>>=
USER ${baseUSER}
VOLUME ${baseDIR}
WORKDIR ${baseDIR}
# you can add entry point, etc. here.
@
```

### Pulling it all together

```
<<opensuse.dockerfile>>=
<<base.image>>
<<base.userargs>>
<<base.setupuser>>
<<base.enablerepos>>
<<base.addsoftware>>
<<base.end>>
@
```
## build and test
`docker build -t mek:opensuse -f opensuse.dockerfile .`
`docker run --rm -it mek:opensuse /bin/bash`
```
