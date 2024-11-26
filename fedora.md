# A simple base docker image for Fedora Docker Image

There are a few other things I liked to do with my docker images to help 
make development and usage a bit more standardized.

## Fedora EPEL Docker Image

### Setup FROM and enable a version choice.

First let's set the where we'll pull from. I use `podman` and 
`docker` equally, so on I give the full path to the FROM image.

An `ARG` for the version, `VER` is there. This can be overridden with 
`--build-arg 'VER=<version>'`.

```
<<base.image>>=
ARG VER=latest
FROM docker.io/fedora:${VER}
@ 
```

### Setup user specific arguments.

Setup a base username, uid, gid, and work directory with some defaults. 
All of these can be overridden with `-build-arg "ARG=VALUE"`.

```
<<base.userargs>>=
ARG baseUSER="fedora"
ARG baseUID=5000
ARG baseGID=5000
ARG baseDIR="/work"
@
```

### Add user and work directory

You'll need to be careful here to not change a current directory. 
For example, do not set baseDIR="/bin". 

Add the group, user, (with the home directory of the user and the
 work directory) and insure the proper ownership on the work directory.

```
<<base.setupuser>>=
RUN groupadd -g ${baseGID} ${baseUSER} &&      \
    useradd -c 'work user' -m -u ${baseUID}    \
    -g ${baseGID} -d ${baseDIR} ${baseUSER} && \ 
    chown -R ${baseUID}:${baseGID} ${baseDIR}
@
```

### Addtional root changes

We are still root at this point, this is where we add software, make 
additional changes, etc.

```
<<base.addsoftware>>=
RUN dnf install -y ed joe tcl tcllib gcc make git gcc-gnat gprbuild \
  gfortran fossil cvs lua unzip zip bzip2 tar gzip valgrind \
  perl-Data-Dumper perl-Test-Harness perl-Test-Simple \
  fpc fpc-ide fpc-src 
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

```
<<install_tfenv>>=
ARG TFVER="1.6.6"
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git ${baseDIR}/.tfenv && \
    echo export PATH=\"${baseDIR}/.tfenv/bin:$PATH\" >> ${baseDIR}/.bashrc && \
    ${baseDIR}/.tfenv/bin/tfenv install ${TFVER} && \
    ${baseDIR}/.tfenv/bin/tfenv use ${TFVER}
@
```
### Pulling it all together

```
<<fedora.dockerfile>>=
<<base.image>>
<<base.userargs>>
<<base.setupuser>>
<<base.addsoftware>>
<<install_tfenv>>
<<base.end>>
@
```

## build and test

* Create the docker image
`tangle.tcl -R fedora.dockerfile fedora.md > fedora.dockerfile` 

* Build the docker image
`docker build -t mek:fedora -f fedora.dockerfile .`

* Run the docker image
`docker run --rm -it mek:fedora /bin/bash`

```
