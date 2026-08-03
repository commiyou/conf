#!/bin/zsh
set -u

PROJECT_DIR="${HOME}/conf/tools/mdit"
PYTHON="${HOME}/.local/bin/python"
OUT_FILE="$(mktemp -t mdit-output.XXXXXX)"
ERR_FILE="$(mktemp -t mdit-error.XXXXXX)"

cleanup() {
  rm -f "$OUT_FILE" "$ERR_FILE"
}
trap cleanup EXIT

cd "$PROJECT_DIR" || {
  echo "Failed: project directory missing"
  exit 1
}

if "$PYTHON" mdit.py --clipboard >"$OUT_FILE" 2>"$ERR_FILE"; then
  if [[ ! -s "$OUT_FILE" ]]; then
    echo "Failed: empty output"
    exit 1
  fi

  pbcopy <"$OUT_FILE"
  char_count="$(wc -m <"$OUT_FILE" | tr -d ' ')"
  echo "Copied ${char_count} chars"
else
  message="$(tr '\n' ' ' <"$ERR_FILE" | cut -c 1-120)"
  [[ -n "$message" ]] || message="unknown error"
  echo "Failed: $message"
  exit 1
fi
