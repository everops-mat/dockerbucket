# A simple base docker image for RH's UBI9 Docker Image

Redhat has recently made their Universal Base Image (UBI) availabe 
on the Docker Registery (docker.io/libarary/redhat/ubi9). 

Of course, it doesn't have the ELPL repository enabled on it, which is 
something I use consistently with the RHel based images.

There are a few other things I liked to do with my docker images to help 
make development and usage a bit more standardized.

## UBI9 EPEL Docker Image

### Setup FROM and enable a version choice.

First let's set the where we'll pull from. I use `podman` and `docker` equally, so on I give the full path to the FROM image.

An `ARG` for the version, `VER` is there. This can be overridden with 
`--build-arg 'VER=<version>'`.

```
<<base.image>>=
ARG VER=latest
FROM docker.io/redhat/ubi9:${VER}
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
RUN dnf install -y ed joe tcl tcllib gcc make git gcc-gnat gprbuild \
  gfortran fossil cvs lua unzip zip bzip2 tar gzip
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
<<ubi9epel.dockerfile>>=
<<base.image>>
<<base.userargs>>
<<base.setupuser>>
<<base.enablerepos>>
<<base.addsoftware>>
<<install_tfenv>>
<<base.end>>
@
```

## build and test

`docker build -t mek:ubi9 -f ubi9-epel.dockerfile .`

`docker run --rm -it mek:ubi9 /bin/bash`

```
$ docker run --rm -it mek:ubi9 /bin/bash
[mat.kovach@4bd996f669b2 ~]$ pwd
/work
[mat.kovach@4bd996f669b2 ~]$ id -a
uid=5000(mat.kovach) gid=5000(mat.kovach) groups=5000(mat.kovach)
$ dnf repolist
Not root, Subscription Management repositories not updated

This system is not registered with an entitlement server. You can use subscription-manager to register.

repo id                 repo name
epel                    Extra Packages for Enterprise Linux 9 - x86_64
ubi-9-appstream-rpms    Red Hat Universal Base Image 9 (RPMs) - AppStream
ubi-9-baseos-rpms       Red Hat Universal Base Image 9 (RPMs) - BaseOS
ubi-9-codeready-builder Red Hat Universal Base Image 9 (RPMs) - CodeReady Builder
```

Now let's try using my current working directory inside the container.

```
$ docker run --rm -it -v $(PWD):/work mek:ubi9 /bin/bash
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
