#!/usr/bin/env zsh

emulate -L zsh
setopt err_return no_unset pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr COMPLETION_MODULE=$ZSH_DIR/zshrc.d/completion.zsh
typeset -gr TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/completion-rebuild-test.XXXXXX")
typeset -gr TEST_ZDOTDIR=$TEST_ROOT/zdotdir
typeset -gr DUMP_PATH=$TEST_ROOT/cache/zcompdump-test
typeset -gr COMPINIT_LOG=$TEST_ROOT/compinit.log
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

compinit() {
  [[ ! -e $DUMP_PATH && ! -e $DUMP_PATH.zwc ]] ||
    fail 'old completion cache was not removed before compinit'
  print -r -- "$@" >"$COMPINIT_LOG"
  print -r -- rebuilt >"$DUMP_PATH"
}

[[ -r $COMPLETION_MODULE ]] || fail "missing $COMPLETION_MODULE"
mkdir -p -- "$TEST_ZDOTDIR/completions" "${DUMP_PATH:h}" "$FAKE_BIN"
ZDOTDIR=$TEST_ZDOTDIR
typeset -gA ZINIT=(ZCOMPDUMP_PATH "$DUMP_PATH")
source "$COMPLETION_MODULE"

print -r -- old >"$DUMP_PATH"
print -r -- compiled >"$DUMP_PATH.zwc"
zcomp-rebuild
[[ $(<"$COMPINIT_LOG") == "-d $DUMP_PATH" ]] || fail "unexpected compinit args: $(<"$COMPINIT_LOG")"
[[ $(<"$DUMP_PATH") == rebuilt ]] || fail 'completion cache was not rebuilt'

print -rl -- \
  '#!/bin/sh' \
  'printf "%s\n" "#compdef rg" "_rg() { :; }"' >"$FAKE_BIN/rg"
chmod 755 "$FAKE_BIN/rg"
print -r -- stale >"$TEST_ZDOTDIR/completions/_rg"
PATH="$FAKE_BIN:$PATH"
zcomp-rebuild --refresh-rg
[[ $(<"$TEST_ZDOTDIR/completions/_rg") == $'#compdef rg\n_rg() { :; }' ]] ||
  fail '_rg was not refreshed'

if zcomp-rebuild --unknown >/dev/null 2>&1; then
  fail 'unknown option returned success'
fi

print -r -- PASS
