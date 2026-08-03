#!/usr/bin/env zsh

emulate -L zsh
setopt err_return no_unset pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr CONF_DIR=${ZSH_DIR:h}
typeset -gr FUNCTIONS_FILE=$ZSH_DIR/zshrc.d/functions.zsh
typeset -gr FUNCTIONRC=$CONF_DIR/rc.d/functionrc
typeset -gr TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/exchange-test.XXXXXX")
typeset -gr WORK_DIR=$TEST_ROOT/work
typeset -gr FAKE_BIN=$TEST_ROOT/fake-bin
typeset -gr MV_COUNT_FILE=$TEST_ROOT/mv.count
typeset -gr REAL_MV=${commands[mv]}
typeset -g MV_FAIL_AT=0

cleanup() {
  trap - EXIT INT TERM
  [[ -d $TEST_ROOT ]] && rm -r -- "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

assert_content() {
  [[ $(<"$1") == "$2" ]] || fail "unexpected content in $1: $(<"$1")"
}

reset_mv_failure() {
  print -r -- 0 >"$MV_COUNT_FILE"
  MV_FAIL_AT=$1
  export MV_FAIL_AT
}

[[ -r $FUNCTIONS_FILE ]] || fail "missing $FUNCTIONS_FILE"
[[ -r $FUNCTIONRC ]] || fail "missing $FUNCTIONRC"
ZDOTDIR=$ZSH_DIR
source "$FUNCTIONRC"
source "$FUNCTIONS_FILE"

mkdir -p -- "$WORK_DIR" "$FAKE_BIN"
cd -- "$WORK_DIR"

print -r -- left >left
print -r -- right >right
exchange left right
assert_content left right
assert_content right left

swap left right
assert_content left left
assert_content right right

print -r -- current >config
print -r -- backup >config.bak
swapf config
assert_content config backup
assert_content config.bak current

print -rl -- \
  '#!/bin/sh' \
  'count=0' \
  '[ ! -r "$MV_COUNT_FILE" ] || read count < "$MV_COUNT_FILE"' \
  'count=$((count + 1))' \
  'printf "%s\n" "$count" > "$MV_COUNT_FILE"' \
  '[ "$count" -ne "$MV_FAIL_AT" ] || exit 23' \
  'exec "$REAL_MV" "$@"' >"$FAKE_BIN/mv"
chmod 755 "$FAKE_BIN/mv"
export MV_COUNT_FILE REAL_MV
typeset original_path=$PATH
PATH="$FAKE_BIN:$PATH"

print -r -- left-2 >left-2
print -r -- right-2 >right-2
reset_mv_failure 2
if exchange left-2 right-2 2>"$TEST_ROOT/step-2.err"; then
  fail "second move failure returned success"
fi
assert_content left-2 left-2
assert_content right-2 right-2

print -r -- left-3 >left-3
print -r -- right-3 >right-3
reset_mv_failure 3
if exchange left-3 right-3 2>"$TEST_ROOT/step-3.err"; then
  fail "third move failure returned success"
fi
assert_content left-3 left-3
assert_content right-3 right-3

PATH=$original_path
typeset -a leftovers=("$WORK_DIR"/.exchange.*(/N))
(( ${#leftovers} == 0 )) || fail "temporary directories were not cleaned up: ${leftovers[*]}"

print -r -- PASS
