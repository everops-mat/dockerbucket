#!/bin/sh
set -euax

## check the usage and get the image to test
if [ $# -ne 1 ] ; then
  echo 1>&2 "usage: $0 image"
  exit 1
fi
image=$1

# Get the toplevel directory of the git repo
repo_dir=`git rev-parse --show-toplevel`

# See if the file for the image is available

if [ ! -f "${repo_dir}/${image}.md" ] ; then
  echo 1>&2 "could not find the file for ${image}"
  exit 1
fi

# Let's try to build it.
echo "attempting to build ${image} in ${repo_dir}"
${repo_dir}/scripts/tangle.tcl -R "${image}.dockerfile" "${image}.md" | \
  docker build -t test:${image} -f - .

exit 0
