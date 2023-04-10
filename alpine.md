# A simple base docker image for Alpine. 
20230410

My Alpine Docker Images are pretty standard. Nothing specific here.


## Alpine Docker Image

### Setup FROM and enable a version choice.

First let's set the where we'll pull from. I use `podman` and `docker` equally, so on I give the full path to the FROM image.

An `ARG` for the version, `VER` is there. This can be overridden with `--build-arg 'VER=<version>'`.

```
<<base.image>>=
ARG VER=latest
FROM docker.io/alpine:${VER}
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

*Alpine requies you add the `shadow` package before using `groupadd`.*

```
<<base.alpinepre>>=
RUN apk add --no-cache shadow
@
```


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
RUN apk update && apk upgrade --no-cache && \
         apk add --no-cache ed tcl joe 
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
<<alpine.dockerfile>>=
<<base.image>>
<<base.userargs>>
<<base.alpinepre>>
<<base.setupuser>>
<<base.enablerepos>>
<<base.addsoftware>>
<<base.end>>
@
```
## build and test
`docker build -t mek:alpine -f alpine.dockerfile .`
`docker run --rm -it mek:alpine /bin/sh`
```
