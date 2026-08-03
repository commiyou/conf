#!/usr/bin/env zsh

emulate -L zsh
setopt err_return no_unset pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr FUNCTIONS_FILE=$ZSH_DIR/zshrc.d/functions.zsh

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

history() {
  print -r -- '1  2026-08-03 10:00  git status'
  print -r -- '2  2026-08-03 10:01  git diff'
  print -r -- '3  2026-08-03 10:02  docker status'
  print -r -- '4  2026-08-03 10:03  git show literal [ value'
}

[[ -r $FUNCTIONS_FILE ]] || fail "missing $FUNCTIONS_FILE"
ZDOTDIR=$ZSH_DIR
source "$FUNCTIONS_FILE"

typeset all_entries=$(h)
(( ${#${(f)all_entries}} == 4 )) || fail "h without keywords did not return all entries"

typeset and_result=$(h git status)
[[ $and_result == '1  2026-08-03 10:00  git status' ]] ||
  fail "multiple keywords did not use AND semantics: $and_result"

typeset literal_result=$(h git '[')
[[ $literal_result == '4  2026-08-03 10:03  git show literal [ value' ]] ||
  fail "pattern characters were not treated literally: $literal_result"

if h git missing >/dev/null; then
  fail "a missing keyword returned success"
fi

print -r -- PASS
