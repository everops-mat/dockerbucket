#!/usr/bin/env tclsh
# vim: filetype=tcl tabstop=2 shiftwidth=2 sts=2 expandtab number
# Copyright (c) 2021 Mat Kovach
# A Tcl script for opinionated Docker operations using literate
# programming for Docker definitions

# Specify minimum Tcl version explicitly
if {[package require Tcl] < 8.5} {
  puts stderr "This script requires Tcl 8.6 or higher."
	exit 1
}

# Default settings
set BASE_DIR [expr {[info exists env(DOCKER_BASE_DIR)] ? $env(DOCKER_BASE_DIR) : "$env(HOME)/eo/git/everops-mat/dockerbucket/main"}]
set TANGLE_SCRIPT "$env(HOME)/bin/tangle.tcl"
set TARGET_PLATFORM [expr {[info exists env(DOCKER_PLATFORM)] ? $env(DOCKER_PLATFORM) : "linux/amd64"}]

# Error handling
proc Err {msg} {
  puts stderr "Error: $msg"
}

proc Fail {msg} {
  Err $msg
  exit 1
}

proc usage {} {
  puts "Usage: [file tail $::argv0] \[OPTIONS\] CMD \[DOCKER ARGUMENTS\]

OPTIONS:
  -h,  --help           Show this help message
  -b,  --basedir DIR    Set the base directory (default: $::env(HOME)/git/dockerbucket)
  -l,  --list           List available container definitions
  -dl, --imagelist      List Docker images created by this script
  -c,  --container      Specify the container to run

COMMANDS:
  build                Build the Docker image
  run                  Run the Docker container
  edit                 Edit the container markdown file
  buildrun             Build and run the Docker container

ENVIRONMENT VARIABLES:
  DOCKER_BASE_DIR      Directory for Docker definitions (default: $::env(HOME)/git/dockerbucket)
  DOCKER_PLATFORM      Docker platform (default: linux/amd64)
"
  exit 1
}

proc generate_dockerfile {container doc} {
	set cmd "$::TANGLE_SCRIPT -R ${container}.dockerfile $doc"
  set dockerfile_content [exec {*}$cmd]
  if {$? != 0} {
    Fail "Failed to generate Dockerfile from $doc"
  }
  return $dockerfile_content
}

proc sanitize {value} {
  return [string map {" " "\\ " "\t" "\\t" "\n" "\\n" "\"" "\\\""} $value]
}

proc op_build {container doc image args} {
  cd $::BASE_DIR
  set dockerfile [generate_dockerfile $container $doc]
  set sanitized_image [sanitize $image]
  set sanitized_args [list]
  foreach arg $args {
    lappend sanitized_args [sanitize $arg]
  }
  set cmd [list docker build --platform=$::TARGET_PLATFORM -t $sanitized_image {*}$sanitized_args . -f -]
  exec {*}$cmd < $dockerfile
}

proc op_run {image args} {
	set sanitized_image [sanitize $image]
  set sanitized_args [list]
  foreach arg $args {
		lappend sanitized_args [sanitize $arg]
  }
  set cmd [list docker run --rm -it -v "$::env(HOME)/work:/data" -e "DISPLAY=host.docker.internal:0" --platform=$::TARGET_PLATFORM $sanitized_image {*}$sanitized_args]
  exec {*}$cmd
}

proc check_for_doc {doc} {
  if {![file exists $doc]} {
    Err "Could not find $doc, exiting"
    usage
  }
}

# Parse command-line arguments
set container ""
set args [list]
set i 0

while {[llength $argv]} {
	set argv [lassign $argv[set argv {}] flag]
  switch -- $flag {
    -h - --help - -? {
      usage
    }
    -b - --basedir {
      set argv [lassign $argv[set argv {}] BASE_DIR]
    }
    -l - --list {
      foreach file [glob -nocomplain "$::BASE_DIR/*.md"] {
        if {[file tail $file] ne "README.md"} {
          puts [file rootname [file tail $file]]
        }
      }
      exit 0
    }
    -dl - --imagelist {
      puts "Showing docker list"
      exec sh -c "docker image ls | awk '$2 ~ /my-docker/ {print $2}'"
      exit 0
    }
    -c - --container {
      set argv [lassign $argv[set argv {}] container]
    }
    -- break
    -* {
      Err "unknown option $flag"
      usage
    }
    default {
      set argv [list $flag {*}$argv]
      break
    }
  }
}

if {![string is alnum $container]} {
	Fail "Invalid container name given, exiting"
}

set doc "$::BASE_DIR/$container.md"
set image "$container:my-docker"

if {[llength $argv] == 0} {
	usage
}

set op [lindex $argv 0]
set op_args [lrange $argv 1 end]

switch -- $op {
	build {
		check_for_doc $doc
    op_build $container $doc $image $op_args
  }
  run {
		check_for_doc $doc
    op_run $image $op_args
  }
  edit {
		exec $::env(EDITOR) $doc
  }
  buildrun {
		check_for_doc $doc
    op_build $container $doc $image $op_args
     op_run $image $op_args
  }
	default {
		Err "illegal option $op, exiting"
		usage
  }
}

exit 0
