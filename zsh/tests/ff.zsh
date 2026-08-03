#!/usr/bin/env zsh

emulate -L zsh
setopt err_return pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr FUNCTIONS_FILE=$ZSH_DIR/zshrc.d/functions.zsh
typeset -ga VIM_ARGS=()

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

fzf() {
  print -r -- 'first file.txt'
  print -r -- 'nested/second.txt'
}

vim() {
  VIM_ARGS=("$@")
}

[[ -r $FUNCTIONS_FILE ]] || fail "missing $FUNCTIONS_FILE"
ZDOTDIR=$ZSH_DIR
source "$FUNCTIONS_FILE"

unset selected selected_files 2>/dev/null || true
ff

(( ${#VIM_ARGS} == 2 )) || fail "expected 2 Vim arguments, got ${#VIM_ARGS}"
[[ $VIM_ARGS[1] == 'first file.txt' ]] || fail "first filename was split: $VIM_ARGS[1]"
[[ $VIM_ARGS[2] == 'nested/second.txt' ]] || fail "unexpected second filename: $VIM_ARGS[2]"
(( ${+parameters[selected]} == 0 )) || fail "selected leaked into the caller"
(( ${+parameters[selected_files]} == 0 )) || fail "selected_files leaked into the caller"

print -r -- PASS
