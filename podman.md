# Podman Container Image

This is my version of [Podman
Image](https://github.com/containers/podman/blob/main/contrib/podmanimage/stable/Containerfile).

I will be building with a RH UBI Image (version 9).

## UBI9 Podman Image

### FROM

An `ARG` for the version, `VER` is there. This can be overridden with `--build-arg 'VER=<version>'`.

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
ARG baseUSER="podman"
ARG baseUID=5000
ARG baseGID=5000
ARG baseDIR="/work"
@
```

### Setup and install packages

The container-commons package on UBI9 does not install the storage.conf
thatr we need, so we copy the file here. 

```
<<base.software>>=
RUN dnf -y update && \
    rpm --setcaps shadow-utils 2>/dev/null && \
    dnf -y install podman podman-docker       \
           fuse-overlayfs openssh-clients     \
           ed joe tcl tcllib                  \
        --exclude container-selinux        && \
    rm -rf /var/cache /var/log/dnf*           \
           /var/log/yum.*
ADD files/podman/storage.conf /usr/share/containers/storage.conf
@
```

### Add podman user

You'll need to be careful here to not change a current directory. For example, do not set baseDIR="/bin". 

Add the group, user, (with the home directory of the user ad the work directory) and insure the proper ownership on the work directory.

```
<<base.setupuser>>=
RUN useradd ${baseUSER}; \
 & echo -e "${baseUSER}:1:999" > /etc/subuid \
 & ecoh -e "${baseUSER}:1001:64535" >> /etc/subuid \
 & echo -e "${baseUSER}:1:999" > /etc/subgid \
 & echo -e "${baseUSER}:1001:64535" >> /etc/subgid
@
```

### Additional Podman Changes

Additonal changes are needed to the base image for podman to work as
expected.

```
<<base.podmansetup>>=
ARG _REPO_URL="https://raw.githubusercontent.com/containers/podman/main/contrib/podmanimage/stable"
ADD $_REPO_URL/containers.conf /etc/containers/containers.conf
ADD $_REPO_URL/podman-containers.conf /home/podman/.config/containers/containers.conf

RUN mkdir -p /home/podman/.local/share/containers && \
    chown podman:podman -R /home/podman && \
    chmod 644 /etc/containers/containers.conf

# Copy & modify the defaults to provide reference if runtime changes needed.
# Changes here are required for running with fuse-overlay storage inside container.
RUN sed -e 's|^#mount_program|mount_program|g' \
           -e '/additionalimage.*/a "/var/lib/shared",' \
           -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
           /usr/share/containers/storage.conf \
           > /etc/containers/storage.conf

# Note VOLUME options must always happen after the chown call above
# RUN commands can not modify existing volumes
VOLUME /var/lib/containers
VOLUME /home/podman/.local/share/containers

RUN mkdir -p /var/lib/shared/overlay-images \
             /var/lib/shared/overlay-layers \
             /var/lib/shared/vfs-images \
             /var/lib/shared/vfs-layers && \
    touch /var/lib/shared/overlay-images/images.lock && \
    touch /var/lib/shared/overlay-layers/layers.lock && \
    touch /var/lib/shared/vfs-images/images.lock && \
    touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""
@
```

### Add repos and update software.

First, we'll add the EPEL repo. If you have additional repos you want to 
enable, add them here.

```
<<base.enablerepos>>=
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    /usr/bin/crb enable
@
```

### Addtional root changes

We are still root at this point, this is where we add software, make 
additional changes, etc.

The different sections are setup based on how often they may be changed. 
The more likely some will change, the further down they should be to help 
minimize the layers that need to be rebuilt.

### Make sure we the user, volume, and workdir setup

```
<<base.end>>=
# you can add entry point, etc. here.
@
```

### Pulling it all together

```
<<podman.dockerfile>>=
<<base.image>>
<<base.enablerepos>>
<<base.software>>
<<base.userargs>>
<<base.setupuser>>
<<base.podmansetup>>
<<base.end>>
@
```

## build and test

`docker build -t mek:podman -f podman.dockerfile .`

`docker run --rm -it mek:podman /bin/bash`

```
$ docker run --rm -it mek:podman /bin/bash
```
