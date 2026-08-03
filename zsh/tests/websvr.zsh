#!/usr/bin/env zsh

emulate -L zsh
setopt err_return no_unset pipe_fail

typeset -gr TEST_DIR=${0:A:h}
typeset -gr ZSH_DIR=${TEST_DIR:h}
typeset -gr FUNCTIONS_FILE=$ZSH_DIR/zshrc.d/functions.zsh
typeset -gr TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/websvr-test.XXXXXX")
typeset -gr WORK_DIR=$TEST_ROOT/work
typeset -gr TIMEOUT_LOG=$TEST_ROOT/timeout.log
typeset -gr GTIMEOUT_LOG=$TEST_ROOT/gtimeout.log

cleanup() {
  trap - EXIT INT TERM
  [[ -d $TEST_ROOT ]] && rm -r -- "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  print -u2 -r -- "FAIL: $*"
  return 1
}

timeout() {
  print -r -- "$@" >"$TIMEOUT_LOG"
}

myip() {
  print -r -- 192.0.2.10
}

[[ -r $FUNCTIONS_FILE ]] || fail "missing $FUNCTIONS_FILE"
ZDOTDIR=$ZSH_DIR
source "$FUNCTIONS_FILE"

mkdir -p -- "$WORK_DIR/nested"
cd -- "$WORK_DIR"

for index in {01..11}; do
  typeset file_name="nested/file-$index.txt"
  [[ $index == 11 ]] && file_name='nested/.hidden-11.txt'
  print -r -- "$index" >"$file_name"
  touch -t "2026010100${index}.00" "$file_name"
done
typeset newest_file='nested/newest 100%.txt'
print -r -- 12 >"$newest_file"
touch -t 202601010012.00 "$newest_file"

unset LPORT UPORT MPORT
websvr 8123 >"$TEST_ROOT/output"
wait

[[ $(<"$TIMEOUT_LOG") == '10m python3 -m http.server 8123' ]] ||
  fail "unexpected server command: $(<"$TIMEOUT_LOG")"

unfunction timeout
gtimeout() {
  print -r -- "$@" >"$GTIMEOUT_LOG"
}
typeset original_path=$PATH
PATH=$TEST_ROOT
websvr 8124 >"$TEST_ROOT/gtimeout.output"
wait
PATH=$original_path
[[ $(<"$GTIMEOUT_LOG") == '10m python3 -m http.server 8124' ]] ||
  fail "unexpected gtimeout command: $(<"$GTIMEOUT_LOG")"

unfunction gtimeout
PATH=$TEST_ROOT
if websvr 8125 >"$TEST_ROOT/missing.output" 2>"$TEST_ROOT/missing.err"; then
  fail "missing timeout command returned success"
fi
PATH=$original_path
command grep -Fqx -- 'websvr: timeout is unavailable; install GNU coreutils' "$TEST_ROOT/missing.err" ||
  fail "missing timeout command was not reported"

(( ${+parameters[LPORT]} == 0 && ${+parameters[UPORT]} == 0 && ${+parameters[MPORT]} == 0 )) ||
  fail "websvr leaked port variables"

typeset -a links=("${(@f)$(command grep '^http://192\.0\.2\.10:8123/' "$TEST_ROOT/output")}")
(( ${#links} == 10 )) || fail "expected 10 file links, got ${#links}"
[[ $links[1] == 'http://192.0.2.10:8123/nested/newest%20100%25.txt' ]] ||
  fail "newest file link was not first or URL-encoded: $links[1]"
(( ${links[(I)*.hidden-11.txt]} )) || fail "hidden files were omitted"
if command grep -Fq -- 'file-01.txt' "$TEST_ROOT/output"; then
  fail "oldest file was included"
fi
if command grep -Fq -- 'file-02.txt' "$TEST_ROOT/output"; then
  fail "second-oldest file was included"
fi
command grep -Fqx -- 'http://192.0.2.10:8123 starting...' "$TEST_ROOT/output" ||
  fail "server URL was not printed"

print -r -- PASS
