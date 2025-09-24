#!/bin/sh
docker run --rm -it \
  --platform=linux/amd64 \
  --name jupytertest \
  -p 8888:8888 \
  -v $HOME/work:/home/mek/work \
  -e JUPYTER_ENABLE_LAB=yes \
  jupyter:test
