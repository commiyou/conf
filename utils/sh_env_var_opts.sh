#!/bin/bash -e
# A SHORT DESCRIPTION OF YOUR SCRIPT GOES HERE
# USAGE:
#    DESCRIPTION OF ENV VARS HERE
###############################################################################
set -e          # exit on command errors (so you MUST handle exit codes properly!)
set -o pipefail # capture fail exit codes in piped commands
#set -x         # execution tracing debug messages

# Get command info
CMD_PWD=$(pwd)
CMD="$0"
CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"

# Defaults and command line options
[ "$VERBOSE" ]  ||  VERBOSE=
[ "$DEBUG" ]    ||  DEBUG=
[ "$THING" ]    ||  THING=123	# assuming that you have a thing
# >>>> PUT YOUR ENV VAR DEFAULTS HERE <<<<

# Basic helpers
out() { echo "$(date +%Y%m%dT%H%M%SZ): $*"; }
err() { out "$*" 1>&2; }
vrb() { [ ! "$VERBOSE" ] || out "$@"; }
dbg() { [ ! "$DEBUG" ] || err "$@"; }
die() { err "EXIT: $1" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }
usage() { [ "$0" = "bash" ] || sed '2,/^##/p;d' "$0"; echo "$*"; exit 1; }

[ "$DEBUG" ]  &&  set -x

###############################################################################

# Validate some things
[ "$1" = "--help" -o "$1" = "-h" ]  &&  usage ""

# >>>> PUT YOUR SCRIPT HERE <<<<
