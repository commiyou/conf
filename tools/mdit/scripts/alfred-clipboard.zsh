#!/bin/zsh
set -u

PROJECT_DIR="${HOME}/conf/tools/mdit"
PYTHON="${HOME}/.local/bin/python"
OUT_FILE="$(mktemp -t mdit-output.XXXXXX)"
ERR_FILE="$(mktemp -t mdit-error.XXXXXX)"

notify() {
  /usr/bin/osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1 || true
}

cleanup() {
  rm -f "$OUT_FILE" "$ERR_FILE"
}
trap cleanup EXIT

notify "mdit" "Converting clipboard to Markdown..."

cd "$PROJECT_DIR" || {
  notify "mdit" "Conversion failed: project directory missing."
  exit 1
}

if "$PYTHON" mdit.py --clipboard >"$OUT_FILE" 2>"$ERR_FILE"; then
  if [[ ! -s "$OUT_FILE" ]]; then
    notify "mdit" "Conversion finished, but output was empty."
    exit 1
  fi

  pbcopy <"$OUT_FILE"
  char_count="$(wc -m <"$OUT_FILE" | tr -d ' ')"
  notify "mdit" "Converted Markdown copied to clipboard (${char_count} chars)."
else
  message="$(tr '\n' ' ' <"$ERR_FILE" | cut -c 1-180)"
  [[ -n "$message" ]] || message="Unknown error. See $ERR_FILE"
  notify "mdit" "Conversion failed: $message"
  echo "$message" >&2
  exit 1
fi
