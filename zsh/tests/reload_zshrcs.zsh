#!/usr/bin/env zsh

emulate -L zsh
setopt err_return no_unset pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr RELOAD_MODULE=$ZSH_DIR/zshrc.d/reload.zsh
typeset -gr TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/reload-zshrcs-test.XXXXXX")
typeset -gr REGISTRY_DIR=$TEST_ROOT/registry
typeset -gr CONFIG_A=$TEST_ROOT/config-a
typeset -gr CONFIG_B=$TEST_ROOT/config-b
typeset -ga CHILD_PIDS=()

cleanup() {
  trap - EXIT INT TERM
  if (( ${#CHILD_PIDS} )); then
    kill -TERM -- "${CHILD_PIDS[@]}" 2>/dev/null || true
    sleep 0.05
    kill -KILL -- "${CHILD_PIDS[@]}" 2>/dev/null || true
    wait "${CHILD_PIDS[@]}" 2>/dev/null || true
  fi
  [[ -d $TEST_ROOT ]] && rm -r -- "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

wait_for_path() {
  local target_path=$1
  repeat 100; do
    [[ -e $target_path ]] && return 0
    sleep 0.02
  done
  return 1
}

start_registered_shell() {
  local zdotdir=$1 marker=$2
  env \
    ZDOTDIR="$zdotdir" \
    ZSH_RELOAD_MODULE="$RELOAD_MODULE" \
    ZSH_RELOAD_REGISTRY_DIR="$REGISTRY_DIR" \
    ZSH_RELOAD_TEST_MARKER="$marker" \
    zsh -dfi -c '
      source "$ZSH_RELOAD_MODULE"
      TRAPUSR1() { print -r -- "$$" >| "$ZSH_RELOAD_TEST_MARKER" }
      zmodload zsh/zselect
      while true; do zselect -t 100 || true; done
    ' >/dev/null 2>&1 &
  CHILD_PIDS+=($!)
  REPLY=$!
}

mkdir -p -- "$REGISTRY_DIR" "$CONFIG_A" "$CONFIG_B"

[[ -r $RELOAD_MODULE ]] || fail "missing $RELOAD_MODULE"

typeset marker_a=$TEST_ROOT/target-a.hit
typeset marker_b=$TEST_ROOT/target-b.hit
typeset marker_unregistered=$TEST_ROOT/unregistered.hit

start_registered_shell "$CONFIG_A" "$marker_a"
typeset pid_a=$REPLY
start_registered_shell "$CONFIG_B" "$marker_b"
typeset pid_b=$REPLY

env ZSH_RELOAD_TEST_MARKER="$marker_unregistered" zsh -dfc '
  TRAPUSR1() { print -r -- "$$" >| "$ZSH_RELOAD_TEST_MARKER" }
  zmodload zsh/zselect
  while true; do zselect -t 100 || true; done
' >/dev/null 2>&1 &
CHILD_PIDS+=($!)
typeset pid_unregistered=$!

wait_for_path "$REGISTRY_DIR/$pid_a.entry" || fail "shell $pid_a did not register"
wait_for_path "$REGISTRY_DIR/$pid_b.entry" || fail "shell $pid_b did not register"

{
  print -r -- stale-start-time
  print -r -- "${CONFIG_A:A}"
  print -r -- no-pane
} >| "$REGISTRY_DIR/$pid_unregistered.entry"

ZDOTDIR=$CONFIG_A
ZSH_RELOAD_REGISTRY_DIR=$REGISTRY_DIR
source "$RELOAD_MODULE"

reload_zshrcs --dry-run
[[ ! -e $marker_a && ! -e $marker_b && ! -e $marker_unregistered ]] || fail "dry-run notified a shell"
[[ -e $REGISTRY_DIR/$pid_unregistered.entry ]] || fail "dry-run removed a stale entry"

reload_zshrcs
wait_for_path "$marker_a" || fail "matching registered shell was not notified"
sleep 0.1

[[ ! -e $marker_b ]] || fail "different ZDOTDIR shell was notified"
[[ ! -e $marker_unregistered ]] || fail "unregistered shell was notified"
[[ ! -e $REGISTRY_DIR/$pid_unregistered.entry ]] || fail "stale entry was not removed"
kill -0 "$pid_a" "$pid_b" "$pid_unregistered" 2>/dev/null || fail "reload terminated a zsh process"

print -r -- PASS
