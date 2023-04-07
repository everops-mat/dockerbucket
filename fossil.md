# Fossil docker image.

I am copy from the Fossil Dockerfile here, but it is a good expeirment is building a good, secure, docker image. But wait, there is more! 

It is also extermetely small.

## Fossil SCM

[Fossil](https://www.fossil-scm.org/home/doc/trunk/www/index.wiki) is a source control manager used but Sqlite, TCL, and others. 

They also have some good [information](https://www.fossil-scm.org/home/doc/trunk/www/containers.md) about how they designed and recommend usage of containers. 

Here I am writing up my own notes about their docker image.

## Fossil Docker Image

Several stages are used to build the container. 

### Build the app

The first part uses alpine to build a static version of the fossil binary. The binary will be copied to the final image. 

We are building for a source, but a static binary. A builder stage is used so the development tools won't be on the final docker image. 

```
<<fossil.builder>>=
FROM alpine:latest AS builder
WORKDIR /tmp
RUN set -x                                                             \
    && apk update                                                      \
    && apk upgrade --no-cache                                          \
    && apk add --no-cache                                              \
         gcc make                                                      \
         linux-headers musl-dev                                        \
         openssl-dev openssl-libs-static                               \
         zlib-dev zlib-static
ARG FSLCFG=""
ARG FSLVER="trunk"
ARG FSLURL="https://fossil-scm.org/home/tarball/src?r=${FSLVER}"
ENV FSLSTB=/tmp/fsl/src.tar.gz
ADD $FSLURL $FSLSTB
RUN set -x                                                             \
    && if [ -d $FSLSTB ] ; then mv $FSLSTB/src fsl ;                   \
       else tar -C fsl -xzf fsl/src.tar.gz ; fi                        \
    && m=fsl/src/src/main.mk                                           \
    && fsl/src/configure --static CFLAGS='-Os -s' $FSLCFG && make -j11
@
```

### Setup the OS.

Here, busybox is used to create the directoires needed `/log` and `/museum`.

The `root` and `fossil` users are setup by manually created a `passwd` and `group` file.

```
<<fossil.ossetup>>=
FROM busybox AS os
ARG UID=499
RUN set -x                                                              \
    && mkdir log museum                                                 \
    && echo "root:x:0:0:Admin:/:/false"                   > /tmp/passwd \
    && echo "root:x:0:root"                               > /tmp/group  \
    && echo "fossil:x:${UID}:${UID}:User:/museum:/false" >> /tmp/passwd \
    && echo "fossil:x:${UID}:fossil"                     >> /tmp/group
@
```

### Create the thing!

We now have build the application and setup the needed user info. Fossil runs as a single binary, so there isn't much needed. So, let's create a container using the `scratch` docker image. 

first we'll copy the `group` and `passwd` files as well as the `/log` and `/museum` directories. Copy the user information first and THEN copy the directories and changing ownership when you do. Also make sure we have a `/tmp` directory.

Once user informaiton and directories are there, copy the binary to `/bin`.

Why? Scratch is blank. It has no commands. Basically it is an image that needs to be hand-crafted. 

But after things are copied, we setup the entry point and have a working container that only has one binary `/bin/fossil`.

```
<<fossil.run>>=
FROM scratch AS run
COPY --from=os /tmp/group /tmp/passwd /etc/
COPY --from=os --chown=fossil:fossil /log    /log/
COPY --from=os --chown=fossil:fossil /museum /museum/
COPY --from=os --chmod=1777          /tmp    /tmp/
COPY --from=builder /tmp/fossil /bin/
ENV PATH "/bin"
EXPOSE 8080/tcp
USER fossil
ENTRYPOINT [ "fossil", "server", "museum/repo.fossil" ]
CMD [ \
    "--create",             \
    "--jsmode", "bundled",  \
    "--user", "admin" ]
@
```

## The final docker file

```
<<fossil.dockerfile>>=
<<fossil.builder>>
<<fossil.ossetup>>
<<fossil.run>>
@
```

## Building and taking a look at the final docker container

```
$ docker build -t mek:fossil-trunk -f fossil.dockerfile .
```

While it would be nice to just jump into the container and poke around, we can't. WE DON'T HAVE A SHELL!

So, let's run a container, and export the filesystem.

```
$ docker run --name fossil -d --rm -it -p 9999:8080 mek:fossil-trunk
$ docker export fossil | tar t
.dockerenv
bin/
bin/fossil
dev/
dev/console
dev/pts/
dev/shm/
etc/
etc/group
etc/hostname
etc/hosts
etc/mtab
etc/passwd
etc/resolv.conf
log/
museum/
museum/repo.cache
museum/repo.fossil
proc/
sys/
tmp/
tmp/group
tmp/passwd

$ curl -LsSf -o /dev/null -w '%{http_code}\n'  http://localhost:9999
200
```