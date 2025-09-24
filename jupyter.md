# Jupyter Notebook for Python and TCL devlopment

I'm going to be working a bit more in Python and TCL is my default
scripting language, so I want to develop a docker container that 
I can use to work on both languages and type out Jupyter Notebooks
a bit.

## Start the Docker Image

This is going to use my `dockerbucket` setup to create the 
docker image, so let's start with some of my common configurations.

First I want to be able to control the version I'll be using 
of the base Jupyter Notebook docker image.

```Dockerfile
<<base.image>>=
ARG VER=latest
FROM docker.io/jupyter/base-notebook:${VER}
@
```

Now, I setup some base user and group configuration so I don't 
run into permission issues when using the container on my development
machine. So, first I have to look at the base container definition,
[base-notebook](https://github.com/jupyter/docker-stacks/tree/main/images/base-notebook), and see if there are strict requiremenst and user and
group information already setup. 

Looking at the base, I see:

```Dockerfile
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG REGISTRY=quay.io
ARG OWNER=jupyter
ARG BASE_IMAGE=$REGISTRY/$OWNER/docker-stacks-foundation
FROM $BASE_IMAGE
```

And the things I need to check into are:

* `NB_UID`

Which come from `ARG BASE_IMAGE=$REGISTRY/$OWNER/docker-stacks-foundation`.

Looking at [docker-stacks-foundation](https://github.com/jupyter/docker-stacks/tree/main/images/docker-stacks-foundation) we see that:
* `NB_*` is an docker argument that can be overridden using 
`--build-args`.

So, when building a docker image based on this configuration, we'll need
to build with `NB_UID` equal to our `UID`.

```Dockerfile
<<base.userinfo>>=
ARG baseUID=1000
ARG NB_UID=${baseUID}
@
```

Now we should be able to install the additional software and any 
additionall python packages. The base docker definition ends 
with us being the NB user, so make sure to switch to root and 
switch back before we are done with our additions to the docker 
definitions. Per the base image, we are using Ubuntu, so adding 
software will require using Ubuntu packaging commands.

```Dockerfile
<<base.software>>=
USER root
RUN apt-get update -y \
 && apt-get install -y tcl tcl-dev tk tk-dev tcllib \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
  notebook
@
```

Now we have the custom changes created, let's start expose the port
and start the notebook, remembering to switch to the proper user 
or user id.

```Dockerfile
<<base.startjupyter>>=
RUN chown -R ${NB_UID} /home/jovyan
USER ${NB_UID}
EXPOSE 8888
CMD ["start-notebook.py"]
@
```

So, the entire customer Juypter notebook dockerfile will look like:

```Dockerfile
<<jupyter.dockerfile>>=
<<base.image>>
<<base.userinfo>>
<<base.software>>
<<base.startjupyter>>
@
```
