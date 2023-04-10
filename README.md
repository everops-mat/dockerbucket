# Mat's Docker Image collection

Various Docker files that I use.

NOTE: You'll need TCL installed on your system. I use my own copy of `tangle`
based on literate programming. If you want to use a docker file, you'll have
to generate it.

## Standard Docker Stuff

I like to insure that my containers follow a few simple rules.

 * Never run as root.
   * For containers, I liked to have a single user I run in.
   * Needed software and configuration that requires root should be done first.
   * At the end, the container should default to be running as that user.

 * A set working directory that can be a docker volume or a volume passed from the host.
   * This present a challenge in make sure that that uid/gid is correct between the active user and the directory.
   * When using a host volume, I also have to make sure the UID/GID matches to not have any permission issues.

 * While we also like to use the latest version of a base docker image, that isn't always possible.
   * We should default to building the latest version, but allow for changing that.

## Docker Files

 * [ubi9epel](ubi9epel.md)
   * Redhat's Universal Base Image (UBI) for RHEL9, with epel installed and read for use.
 * [ubuntu](ubuntu.md)
   * Yes, I use Ubuntu from time to time. 
 * [fossil](fossil.md)
   * I use fossil quite a bit. Nice to have an easy way to run it. I would recommend use the Dockerfile provide by fossil. I have this one here to highlight the usage of the scratch docker image. 
 * [opensuse](opensuse.md)
   * OpenSuse is my favorite development Linux distrobution. 
 * [alpine](alpine.md)
   * Need a good base alpine image to use for deployments.

## As always, go Guardians!

