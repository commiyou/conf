#!/usr/bin/env zsh

emulate -L zsh
setopt err_return no_unset pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/conf-tools-completion-test.XXXXXX")
typeset -gr DUMP_PATH=$TEST_ROOT/zcompdump

cleanup() {
  trap - EXIT INT TERM
  [[ -d $TEST_ROOT ]] && rm -r -- "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

fpath=("$ZSH_DIR/completions" $fpath)
autoload -Uz compinit
compinit -D -d "$DUMP_PATH"

typeset command_name
for command_name in reload_zshrcs websvr exchange swap swapf tr0 ff; do
  [[ ${_comps[$command_name]:-} == _conf-tools ]] ||
    fail "$command_name is not mapped to _conf-tools"
done

autoload +X _conf-tools || fail '_conf-tools could not be loaded'

typeset -ga captured_arguments
_arguments() {
  captured_arguments=("$@")
}
_message() {
  return 0
}

for command_name in reload_zshrcs websvr exchange swap swapf tr0 ff; do
  service=$command_name
  captured_arguments=()
  _conf-tools
  (( ${#captured_arguments} )) || fail "$command_name has no argument specifications"
done

print -r -- PASS
