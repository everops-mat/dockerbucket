# A simple base docker image for free pascal

A simple free pascal based docker image

## Free Pascal Docker Image

[Free Pascal](https://freepascal.org/)

### Setup FROM and enable a version choice.

First let's set the where we'll pull from. I use `podman` and `docker` 
equally, so on I give the full path to the FROM image.

An `ARG` for the version, `VER` is there. This can be overridden 
with `--build-arg 'VER=<version>'`.

```
<<base.image>>=
ARG VER=12
FROM docker.io/debian:${VER}
@  % def VER
```

### Setup user specific arguments.

Setup a base username, uid, gid, and work directory with some 
defaults. All of these can be overridden with `-build-arg "ARG=VALUE"`.

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

First, we'll add any additional repo. If you have additional repos you 
want to enable, add them here.

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
    DEBIAN_FRONTEND=noninteractive apt-get -qq install ed joe tcl yacc git vim \
    sqlite3 gnat gprbuild fpc unzip 
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
<<fpc.dockerfile>>=
<<base.image>>
<<base.userargs>>
<<base.setupuser>>
<<base.enablerepos>>
<<base.addsoftware>>
<<base.end>>
@
```

## build and test

`docker build -t mek:fpc -f fpc.dockerfile .`

`docker run --rm -it -v $HOME/src/<project>:/work mek:fpc /bin/bash`

