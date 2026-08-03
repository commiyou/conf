#!/usr/bin/env zsh

emulate -L zsh
setopt err_return no_unset pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr FUNCTIONS_FILE=$ZSH_DIR/zshrc.d/functions.zsh
typeset -gr TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/tr0-test.XXXXXX")
typeset -gr WORK_DIR=$TEST_ROOT/work
typeset -gr FAKE_BIN=$TEST_ROOT/fake-bin

cleanup() {
  trap - EXIT INT TERM
  [[ -d $TEST_ROOT ]] && rm -r -- "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

file_mode() {
  local -A file_stat
  zstat -H file_stat -- "$1" || return 1
  print -r -- $(([##8] (${file_stat[mode]} & 8#7777)))
}

[[ -r $FUNCTIONS_FILE ]] || fail "missing $FUNCTIONS_FILE"
ZDOTDIR=$ZSH_DIR
source "$FUNCTIONS_FILE"
zmodload -F zsh/stat b:zstat

mkdir -p -- "$WORK_DIR" "$FAKE_BIN"
cd -- "$WORK_DIR"

typeset readonly_file=$WORK_DIR/readonly.tsv
typeset expected_file=$WORK_DIR/expected.tsv
print -rn -- $'left\x01right\n' >"$readonly_file"
print -rn -- $'left\tright\n' >"$expected_file"
chmod 440 "$readonly_file"

typeset mode_before=$(file_mode "$readonly_file")
tr0 "$readonly_file"
typeset mode_after=$(file_mode "$readonly_file")
command cmp -s "$readonly_file" "$expected_file" || fail "SOH was not converted to a tab"
[[ $mode_after == $mode_before ]] || fail "file mode changed from $mode_before to $mode_after"

typeset failed_file=$WORK_DIR/failed.tsv
typeset failed_copy=$WORK_DIR/failed.copy
print -rn -- $'keep\x01original\n' >"$failed_file"
command cp "$failed_file" "$failed_copy"
print -rl -- '#!/bin/sh' 'exit 23' >"$FAKE_BIN/tr"
chmod 755 "$FAKE_BIN/tr"

typeset original_path=$PATH
PATH="$FAKE_BIN:$PATH"
if tr0 "$failed_file" 2>"$TEST_ROOT/failed.err"; then
  fail "tr failure returned success"
fi
PATH=$original_path
command cmp -s "$failed_file" "$failed_copy" || fail "tr failure changed the original file"
command grep -Fqx -- "tr0: failed to convert: $failed_file" "$TEST_ROOT/failed.err" ||
  fail "tr failure was not reported correctly"

typeset continued_file=$WORK_DIR/continued.tsv
print -rn -- $'one\x01two\n' >"$continued_file"
if tr0 "$WORK_DIR/missing.tsv" "$continued_file" 2>"$TEST_ROOT/missing.err"; then
  fail "missing input returned success"
fi
[[ $(<"$continued_file") == $'one\ttwo' ]] || fail "processing stopped after a missing input"

typeset -a leftovers=("$WORK_DIR"/.*.tr0.*(N))
(( ${#leftovers} == 0 )) || fail "temporary files were not cleaned up: ${leftovers[*]}"

print -r -- PASS
