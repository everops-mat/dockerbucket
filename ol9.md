# A simple base docker image for Oralcle Linux 9 (OL9)

## OL9 EPEL Docker Image

### Setup FROM and enable a version choice.

First let's set the where we'll pull from. I use `podman` and
`docker` equally, so on I give the full path to the FROM image.

An `ARG` for the version, `VER` is there. This can be overridden
 with `--build-arg 'VER=<version>'`.

```
<<base.image>>=
ARG VER=9
FROM docker.io/oraclelinux:9
@
```

### Setup user specific arguments.

Setup a base username, uid, gid, and work directory with some
defaults. All of these can be overridden with `-build-arg "ARG=VALUE"`.

```
<<base.userargs>>=
ARG baseUSER="mek"
ARG baseUID=5000
ARG baseGID=20
ARG baseDIR="/work"
@
```

### Add user and work directory

You'll need to be careful here to not change a current directory.
For example, do not set baseDIR="/bin".

Add the group, user, (with the home directory of the user and
the work directory) and insure the proper ownership on the work
directory.

```
<<base.setupuser>>=
RUN useradd -c 'work user' -m -u ${baseUID} -g ${baseGID} ${baseUSER} \
 && mkdir -p /work \
 && chown -R ${baseUID}:${baseGID} ${baseDIR}
@
```

### Addtional root changes

We are still root at this point, this is where we add software, make
additional changes, etc.

```
<<base.addsoftware>>=
RUN dnf install oracle-epel-release-el9 -y \
 && dnf update -y \
 && dnf install -y ed joe tcl tcllib gcc make git gcc-gnat gprbuild \
  gfortran fossil unzip python-pip golang awscli fpc fpc-src tcltls \
  tcl-tclreadline tcl-thread tk
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
<<ol9.dockerfile>>=
<<base.image>>
<<base.userargs>>
<<base.setupuser>>
<<base.addsoftware>>
<<base.end>>
@
```

## build and test

`docker build -t mek:ol9 -f ol9-epel.dockerfile .`

`docker run --rm -it mek:ol9 /bin/bash`

