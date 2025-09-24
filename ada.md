# Creating an Ada Development Container

I am going to base this off Debian, and I'll need 
the following:

* home directory of /home/dev - this is mainly to house config files.

* /data - this is where we'll mount the host filesystem.
  * To help with permissions, we should also be able to change the UID.

* We'll need some basic things to be installed:
  * neovim
  * curl
  * unzip
  * make
  * git 
  * openssh-client
  * python3-pip
  * tcl, tcllib
  * ed

* We'll need to download the alr install script from https://getada.dev.
  * We'll have to download and then run it. 
  * curl > /tmp/getada.sh && sh /tmp/getada.sh -t /tmp -c /etc/getada -b /usr/local/bin 
  * This will make it available to all users.

* Just to be read, we'll need to add the gnat and gprbuild globals for alr. This can be changed per project.
  * alr toolchain --select gnat_native=14.2.1 gprbuild=22.0.1
  * We should make these configuable, and maybe we willl in the future.

## Base of Dockerfile

We'll default to use Debian 12, but that can be changed at build time with 
`--build-arg 'VER=spork'`.

```Dockerfile
<<base.image>>=
ARG VER=12
FROM docker.io/debian:${VER}
@
```

## User Information

We'll default the UID and GID to 5000, with a base name of `dev`. We'll also define the base working directory as `/work'. This can be overridden with build arguments, but one should use care and not set the baseDIR to something like `/bin`. Bad things(tm) will happen.

```Dockerfile
<<base.userinfo>>=
ARG baseUSER=dev
ARG baseUID=1000
ARG baseGID=1000
ARG baseDIR="/work"
@
```

## Directories

```Dockerfile
<<base.userdirsetup>>=
RUN groupadd -g ${baseGID} ${baseUSER} && \
    useradd -m -u ${baseUID} -g ${baseGID} -c "${baseUSER}" -d ${baseDIR} -s /bin/bash ${baseUSER} && \
    mkdir -p ${baseDIR} && \
    chown -R ${baseUID}:${baseGID} ${baseDIR}
@
```
__NOTE__: If the group already exists, the groupadd command will fail.

## Software

Let's install the software that we'll need from the base image.

```Dockerfile
<<base.software>>=
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unzip \
        make \
        git \
        openssh-client \
        python3-pip \
        tcl \
        tcllib \
        ed \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
@
```

## Getada and ALR install

```Dockerfile
<<base.getada>>=
RUN curl --proto '=https' -sSf https://www.getada.dev/init.sh > /tmp/getada.sh && \
    sh /tmp/getada.sh -t /tmp -c /etc/getada -b /usr/local/bin -n && \
    rm /tmp/getada.sh && \
    /usr/local/bin/alr toolchain --select gnat_native=14.2.1 gprbuild=22.0.1
@
```

__NOTE__: This will make the ALR binaries available to all users wihtout needed to sourcing the `/etc/getada/env.sh` file.

## Finally, let's change the user, add the volume, and setup the working directory.

```Dockerfile
<<base.final>>=
USER ${baseUSER}
VOLUME ${baseDIR}
WORKDIR ${baseDIR}
CMD ["/bin/bash"]
@
```

## Final Dockerfile

```Dockerfile
<<ada.dockerfile>>=
<<base.image>>
<<base.userinfo>>
<<base.userdirsetup>>
<<base.software>>
<<base.getada>>
<<base.final>>
@

Now we can build the image:

```shell
<<build.ada.image>>=
docker build -t ada-dev:latest -f ada.dockerfile .
@
```

__NOTE__: Here is were we can add the `--build-arg` flags to change the base image, user information, and directories.

To run the container, using our SuperMaven and Git files. We'll also share oure SSH agent with the container. In this case, using the the work directory from our HOME directory.

```shell
<<run.ada.container>>=
docker run -it --rm \
    -v ~/.supermaven:/home/dev/.supermaven \
    -v ~/.gitconfig:/home/dev/.gitconfig \
    -v $SSH_AUTH_SOCK:/ssh-agent \
    -v $HOME/.config/nvim:/home/dev/.config/nvim \
    -e SSH_AUTH_SOCK=/ssh-agent \
    -v $HOME/work:/work \
    --name ada-dev \
    ada-dev:latest
@
```
