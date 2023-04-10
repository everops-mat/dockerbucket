# A simple base docker image for Ubuntu

My Ubuntu Docker Images are pretty standard. Nothing specific here. Currently
the default version is 22.04

## Ubuntu 22.04 Docker Image

### Setup FROM and enable a version choice.

First let's set the where we'll pull from. I use `podman` and `docker` equally, so on I give the full path to the FROM image.

An `ARG` for the version, `VER` is there. This can be overridden with `--build-arg 'VER=<version>'`.

```
<<base.image>>=
ARG VER=22.04
FROM docker.io/ubuntu:${VER}
@  % def VER
```

### Setup user specific arguments.

Setup a base username, uid, gid, and work directory with some defaults. All of these can be overridden with `-build-arg "ARG=VALUE"`.

```
<<base.userargs>>=
ARG baseUSER="mat.kovach"
ARG baseUID=5000
ARG baseGID=5000
ARG baseDIR="/work"
@
```

### Add user and work directory

You'll need to be careful here to not change a current directory. For example, do not set baseDIR="/bin". 

Add the group, user, (with the home directory of the user ad the work directory) and insure the proper ownership on the work directory.

```
<<base.setupuser>>=
RUN groupadd -g ${baseGID} ${baseUSER} &&      \
    useradd -c 'work user' -m -u ${baseUID}    \
    -g ${baseGID} -d ${baseDIR} ${baseUSER} && \ 
    chown -R ${baseUID}:${baseGID} ${baseDIR}
@
```

### Add repos and update software.

First, we'll add any additional repo. If you have additional repos you want to 
enable, add them here.

```
<<base.enablerepos>>=
# nothing to do here, carry on!
@
```

### Addtional root changes

We are still root at this point, this is where we add software, make 
additional changes, etc.

```
<<base.addsoftware>>=
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install ed joe tcl 
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
<<ubuntu.dockerfile>>=
<<base.image>>
<<base.userargs>>
<<base.setupuser>>
<<base.enablerepos>>
<<base.addsoftware>>
<<base.end>>
@
```

## build and test

`docker build -t mek:ubuntu -f ubuntu.dockerfile .`

`docker run --rm -it mek:ubuntu /bin/bash`

```
docker run --rm -it mek:ubuntu /bin/bash 
mat.kovach@1026b0a03fb4:~$ pwd
/work
mat.kovach@1026b0a03fb4:~$ id -a
uid=5000(mat.kovach) gid=5000(mat.kovach) groups=5000(mat.kovach)
mat.kovach@1026b0a03fb4:~$ grep -rhE ^deb /etc/apt/sources.list* 
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy universe
deb http://archive.ubuntu.com/ubuntu/ jammy-updates universe
deb http://archive.ubuntu.com/ubuntu/ jammy multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb http://security.ubuntu.com/ubuntu/ jammy-security universe
deb http://security.ubuntu.com/ubuntu/ jammy-security multiverse
```
