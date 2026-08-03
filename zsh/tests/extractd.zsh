#!/usr/bin/env zsh

emulate -L zsh
setopt err_return no_unset pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr FUNCTIONS_FILE=$ZSH_DIR/zshrc.d/functions.zsh
typeset -gr TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/extractd-test.XXXXXX")
typeset -gr WORK_DIR=$TEST_ROOT/work
typeset -gr EXTRACT_LOG=$TEST_ROOT/extract.log
typeset -g EXTRACT_STATUS=0

cleanup() {
  trap - EXIT INT TERM
  [[ -d $TEST_ROOT ]] && rm -r -- "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

extract() {
  print -r -- "$PWD|$1" >>"$EXTRACT_LOG"
  return $EXTRACT_STATUS
}

[[ -r $FUNCTIONS_FILE ]] || fail "missing $FUNCTIONS_FILE"
source "$FUNCTIONS_FILE"

mkdir -p -- "$WORK_DIR/existing"
cd -- "$WORK_DIR"
typeset -r original_dir=$PWD

if extractd "$TEST_ROOT/existing.zip" 2>"$TEST_ROOT/existing.err"; then
  fail "existing target returned success"
fi
[[ $PWD == $original_dir ]] || fail "existing target changed the caller directory"
[[ ! -e $EXTRACT_LOG ]] || fail "extract ran for an existing target"
[[ $(<"$TEST_ROOT/existing.err") == "extractd: target already exists: existing" ]] ||
  fail "existing target error was not reported correctly"

EXTRACT_STATUS=42
if extractd "$TEST_ROOT/failing.zip"; then
  fail "extract failure returned success"
fi
[[ $PWD == $original_dir ]] || fail "extract failure changed the caller directory"
[[ -d $WORK_DIR/failing ]] || fail "failed extraction directory was removed"
[[ $(<"$EXTRACT_LOG") == "$WORK_DIR/failing|$TEST_ROOT/failing.zip" ]] ||
  fail "extract did not run inside the target directory"

print -r -- PASS
