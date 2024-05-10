# A simple base docker image for CentOS

There are a few other things I liked to do with my docker images to help
make development and usage a bit more standardized.

## CentOS Docker Image

### Setup FROM and enable a version choice.

First let's set the where we'll pull from. I use `podman` and `docker` equally, so on I give the full path to the FROM image.

An `ARG` for the version, `VER` is there. This can be overridden with `--build-arg 'VER=<version>'`.

```
<<base.image>>=
ARG VER=stream9
FROM quay.io/centos/centos:${VER}
@  % def VER
```

### Setup user specific arguments.

Setup a base username, uid, gid, and work directory with some defaults. All of these can be overridden with `-build-arg "ARG=VALUE"`.

```
<<base.userargs>>=
ARG baseUSER="mek"
ARG baseUID=501
ARG baseGID=501
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

First, we'll add the EPEL repo. If you have additional repos you want to
enable, add them here.

```
<<base.enablerepos>>=
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    /usr/bin/crb enable && \
    dnf update -y
@
```

### Addtional root changes

We are still root at this point, this is where we add software, make
additional changes, etc.

```
<<base.addsoftware>>=
RUN dnf install -y epel-release && dnf update \
 && dnf group install -y "Development Tools" \
 && dnf install -y ed joe tcl tcllib vim gcc flex byacc sqlite-devel make gcc git \
    valgrind gdb ltrace strace perf papi sysstat
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
<<centos.dockerfile>>=
<<base.image>>
<<base.userargs>>
<<base.setupuser>>
<<base.addsoftware>>
<<base.end>>
@
```

## build and test

`docker build -t mek:centos -f centos.dockerfile .`

`docker run --rm -it mek:centos /bin/bash`

```
$ docker run --rm -it mek:centos /bin/bash
[mat.kovach@4bd996f669b2 ~]$ pwd
/work
[mat.kovach@4bd996f669b2 ~]$ id -a
uid=5000(mat.kovach) gid=5000(mat.kovach) groups=5000(mat.kovach)
```

Now let's try using my current working directory inside the container.

```
$ docker run --rm -it -v $(PWD):/work mek:centos /bin/bash
bash-5.1$ pwd
/work
bash-5.1$ ls -l *.md
-rw-r--r-- 1 mat.kovach mat.kovach 3474 Apr  5 14:57 UBI9-DOCKER.md
bash-5.1$ touch test
bash-5.1$ exit
exit
Mats-MBP:docker mek$ ls -l test
-rw-r--r--@ 1 mek  staff  0 Apr  5 11:06 test
```
