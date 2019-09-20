#!/bin/bash

####################
#   =>  debug 
#######################

debug() {
  if [ -t 1 ]; then
    tput setaf 2
  fi
  echo "[DEBUG] $@" >&2
  tput sgr0
}

info() {
  if [ -t 1 ]; then
    tput setaf 2
  fi
  echo "[INFO] $@" >&2
  tput sgr0
}

warn() {
  if [ -t 1 ]; then
    tput setaf 3
  fi
  echo "[WARN] $@" >&2
  tput sgr0
}

error() {
  if [ -t 1 ]; then
    tput setaf 1
  fi
  echo "[ERROR] $@" >&2
  tput sgr0
}


############## bash utils

is_baidu_host() {
  if [[ $(hostname) =~ "\.baidu\.com$" ]]; then
    return 0
  else
    return 1
  fi
}

is_sourced() {
  # only bash supported
  [[ "${BASH_SOURCE[0]}" != "${0}" ]] 
}
is_executed() {
  # only bash supported
  [[ "${BASH_SOURCE[0]}" == "${0}" ]] 
}

pip_install() {
  PIP_INSTALL_COMMAND='pip install'
  verbose $PIP_INSTALL_COMMAND
  $PIP_INSTALL_COMMAND "$@"
}

git_clone() {
  local _repo=${1}
  git clone  "$_repo" ${2}
}

bash_version() {
  bash --version | head -1 | awk 'match($0, /version ./) {
  print substr($0, RSTART, RLENGTH)
}' | cut -f2 -d ' '
}

# execute command, exit if not successful
run_or_fail() {
  "$@"
  err=$?
  if [ $err -ne 0 ]; then
    echo "Error: $@ returned $err (aborting this script)" >&2
    exit 1
  fi
  return $err
}

# convert byte-count into human readable K|M|G|..
# bytes2human 1024 #prints 1K
bytes2human() {
  [ -z "${1}" ] && return 1
  #is int?
  case "${1%.*}" in
    *[!0-9]*|"") return 1 ;;
  esac

  printf "%s" "${1}" | awk '{
  split( "B K M G T E P Y Z" , v );
  s=1; while($1>=1024) { $1/=1024; s++ }
  printf("%.2f %s\n", $1, v[s])}' | sed 's:\.00 ::;s:B::;s: ::'
}
# current user is root?
is_root() {
  [ X"$(whoami)" = X"root" ]
}

# _lock "${0}" #locks script till finish
lock() {
  #locks the execution of a program, it should be used at the
  #beggining of it, exit on failure
  exec 9>/tmp/"$(expr "${1}" : '.*/\([^/]*\)')".lock #verify only one instance is running
  [ X"${LOGNAME}" = X"root" ] && chmod 666 /tmp/"$(expr "${1}" : '.*/\([^/]*\)')".lock
  if ! flock -n 9  ; then         #http://mywiki.wooledge.org/BashFAQ/045
    printf "%s\\n" "$(expr "${1}" : '.*/\([^/]*\)'): another instance is running";
    exit 1
  fi
}

# Example:  trap_add 'echo "in trap DEBUG"' DEBUG
# See: http://stackoverflow.com/questions/3338030/multiple-bash-traps-for-the-same-signal
trap_add() {
  local trap_add_cmd
  trap_add_cmd=$1
  shift

  for trap_add_name in "$@"; do
    local existing_cmd
    local new_cmd

    # Grab the currently defined trap commands for this trap
    existing_cmd=$(trap -p "${trap_add_name}" |  awk -F"'" '{print $2}')

    if [[ -z "${existing_cmd}" ]]; then
      new_cmd="${trap_add_cmd}"
    else
      new_cmd="${trap_add_cmd};${existing_cmd}"
    fi

    # Assign the test. Disable the shellcheck warning telling that trap
    # commands should be single quoted to avoid evaluating them at this
    # point instead evaluating them at run time. The logic of adding new
    # commands to a single trap requires them to be evaluated right away.
    # shellcheck disable=SC2064
    trap "${new_cmd}" "${trap_add_name}"
  done
}


lockdir=/tmp/myscript.lock
if mkdir "$lockdir"
then
  echo >&2 "successfully acquired lock"

  # Remove lockdir when the script finishes, or when it receives a signal
  trap 'rm -rf "$lockdir"' 0    # remove directory when script finishes

  # Optionally create temporary files in this directory, because
  # they will be removed automatically:
  tmpfile=$lockdir/filelist

else
  echo >&2 "cannot acquire lock, giving up on $lockdir"
  exit 0
fi

# verbose "hello"           # print nothing
#VERBOSE=1 verbose "hello" # print verbose
verbose() { #print a message when in verbose mode
  [ -z "${1}" ] && return 1
  [ -n "${VERBOSE}" ] && printf "%s\\n" "${*}"
}

############## swtich functions
# define a switch
# $1 => switch name
# $2 => switch value, 0 or 1, default 1
define_switch() {
  local switch_name=DYNC_${1?no switch name}
  local switch_value=${2:-1}
  eval "${switch_name}=${switch_value}"
}

# return 0 if switch_name is defined
test_switch() {
  local switch_name=DYNC_${1?no switch name}
  [[ "${!switch_name}" -eq 1 ]]
}

# 
set_switch(){
  for switch_name in "$@"
  do
    define_switch "$switch_name"
  done
}

clear_switch() {
  for switch_name in "$@"
  do
    define_switch "$switch_name" 0
  done
}

# run cmds if switch is on
# $1 => switch name
# $2 $3 .. => cmd and args
switch_do() {
  local switch_name=${1?no switch name}
  shift
  local cmd=$1
  shift
  local args="$@"
  if test_switch "$switch_name"
  then
    "$cmd" "$args"
  fi
}

############## str functions
# replace param in string, return 1 on failure
# http://www.unix.com/shell-programming-and-scripting/124160-replace-word-string.html
# example:
#     hello="hello world"
#     bye="$(_strreplace "${hello}" "hello" "bye")"
#     printf "%s\\n" "${bye}"   #prints "bye world"
strreplace() {
  _strreplace__orig="${1}"
  [ -n "${3}" ] || return 1 #nothing to search for: error
  _strreplace__srch="${2}"  #pattern to replace
  _strreplace__rep="${3}"   #replacement string
  case "${_strreplace__orig}" in
    *"${_strreplace__srch}"*) #if pattern exists in the string
      _strreplace__sr1="${_strreplace__orig%%$_strreplace__srch*}" #take the string preceding the first match
      _strreplace__sr2="${_strreplace__orig#*$_strreplace__srch}"  #and the string following the first match
      _strreplace__orig="${_strreplace__sr1}${_strreplace__rep}${_strreplace__sr2}" #and sandwich the replacement string between them
      ;;
  esac
  printf "%s" "${_strreplace__orig}"
}

# print n character in string
# substr "abcdef" 0 4 #print "abcd"
subchar() {
  [ -z "${1}" ] && return 1
  [ -z "${2}" ] && return 1

  if [ "${2}" -lt "0" ]; then
    _subchar__pos="$((${#1} + ${2}))"
  else
    _subchar__pos="${2}"
  fi

  [ "${_subchar__pos}" -ge "${#1}" ] && return 1
  [ "${_subchar__pos}" -lt "0" ]     && return 1

  _subchar__string="${1}"

  i="0"; while [ "${i}" -le "${_subchar__pos}" ]; do
  _subchar__char="${_subchar__string#?}"
  _subchar__char="${_subchar__string%$_subchar__char}"
  i="$((i+1))"
  _subchar__string="${_subchar__string#?}"
done
#_subchar__retval="${_subchar__char}"
# printf "%s\\n" "${_subchar__char}"
}
if is_executed; then
  "$@"
  echo 11
fi
