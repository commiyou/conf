# Register interactive shells so reloads never target arbitrary zsh children.

autoload -Uz add-zsh-hook

if [[ -z ${ZSH_RELOAD_REGISTRY_DIR:-} ]]; then
  typeset -g _zsh_reload_host=${HOST:-unknown}
  _zsh_reload_host=${_zsh_reload_host//[^[:alnum:]_.-]/_}
  typeset -g ZSH_RELOAD_REGISTRY_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/zsh-reload-${EUID}/${_zsh_reload_host}"
  unset _zsh_reload_host
fi

typeset -g _ZSH_RELOAD_PENDING=0

_zsh_reload_prepare_registry() {
  command mkdir -p -m 700 -- "$ZSH_RELOAD_REGISTRY_DIR" 2>/dev/null || return 1
  [[ -d $ZSH_RELOAD_REGISTRY_DIR && -O $ZSH_RELOAD_REGISTRY_DIR && ! -L $ZSH_RELOAD_REGISTRY_DIR ]] || return 1
  command chmod 700 -- "$ZSH_RELOAD_REGISTRY_DIR" 2>/dev/null
}

_zsh_reload_zdotdir() {
  local dir=${ZDOTDIR:-$HOME}
  print -r -- "${dir:A}"
}

_zsh_reload_process_start() {
  local pid=$1 start stat_line
  local -a stat_fields
  if [[ -r /proc/$pid/stat ]]; then
    stat_line=$(< /proc/$pid/stat)
    stat_fields=(${=stat_line})
    start=$stat_fields[22]
  else
    start=$(LC_ALL=C command ps -p "$pid" -o lstart= 2>/dev/null) || return 1
  fi
  [[ -n $start ]] || return 1
  print -r -- "$start"
}

_zsh_reload_register() {
  _zsh_reload_prepare_registry || return 1

  local entry="$ZSH_RELOAD_REGISTRY_DIR/$$.entry"
  local tmp_entry="$entry.tmp"
  local process_start=$(_zsh_reload_process_start $$) || return 1
  local zdotdir=$(_zsh_reload_zdotdir)

  {
    print -r -- "$process_start"
    print -r -- "$zdotdir"
    print -r -- "${TMUX_PANE:-}"
    print -r -- "${TMUX:-}"
  } >| "$tmp_entry" || return 1
  command mv -f -- "$tmp_entry" "$entry" || {
    command rm -f -- "$tmp_entry"
    return 1
  }
}

_zsh_reload_unregister() {
  [[ -n ${ZSH_RELOAD_REGISTRY_DIR:-} ]] || return 0
  command rm -f -- "$ZSH_RELOAD_REGISTRY_DIR/$$.entry" 2>/dev/null
}

TRAPUSR1() {
  typeset -g _ZSH_RELOAD_PENDING=1
}

_zsh_reload_at_precmd() {
  (( ${_ZSH_RELOAD_PENDING:-0} )) || return 0
  typeset -g _ZSH_RELOAD_PENDING=0

  local zsh_bin=${commands[zsh]:-zsh}
  if [[ -o login ]]; then
    builtin exec "$zsh_bin" -l
  else
    builtin exec "$zsh_bin"
  fi
  print -u2 -r -- "reload_zshrcs: failed to exec $zsh_bin"
}

reload_zshrcs() {
  emulate -L zsh
  local verbose=0 dry_run=0 arg
  for arg in "$@"; do
    case "$arg" in
      -n|--dry-run) dry_run=1 ;;
      -v|--verbose) verbose=1 ;;
      *) print -u2 -r -- "usage: reload_zshrcs [-n|--dry-run] [-v|--verbose]"; return 2 ;;
    esac
  done

  _zsh_reload_prepare_registry || {
    print -u2 -r -- "reload_zshrcs: registry is unavailable: $ZSH_RELOAD_REGISTRY_DIR"
    return 1
  }

  local current_zdotdir=$(_zsh_reload_zdotdir)
  local entry pid process_start registered_start registered_zdot registered_pane registered_tmux
  local notified=0 skipped=0 stale=0

  for entry in "$ZSH_RELOAD_REGISTRY_DIR"/*.entry(N); do
    pid=${entry:t:r}
    [[ $pid == <-> ]] || continue

    if ! {
      IFS= read -r registered_start
      IFS= read -r registered_zdot
      IFS= read -r registered_pane
      IFS= read -r registered_tmux
    } < "$entry"; then
      (( dry_run )) || command rm -f -- "$entry"
      ((stale++))
      continue
    fi

    process_start=$(_zsh_reload_process_start "$pid")
    if [[ -z $process_start || $process_start != "$registered_start" ]]; then
      (( dry_run )) || command rm -f -- "$entry"
      ((stale++))
      continue
    fi

    if [[ $registered_zdot != "$current_zdotdir" ]]; then
      ((skipped++))
      continue
    fi

    if (( dry_run )); then
      print -r -- "would notify pid=$pid pane=${registered_pane:-?}"
    elif kill -USR1 "$pid" 2>/dev/null; then
      ((notified++))
      (( verbose )) && print -r -- "notified pid=$pid pane=${registered_pane:-?}"
    else
      (( dry_run )) || command rm -f -- "$entry"
      ((stale++))
    fi
  done

  (( verbose || dry_run )) && print -r -- "reload_zshrcs: notified=$notified skipped=$skipped stale=$stale"
  return 0
}

if [[ -o interactive ]]; then
  # Remove the old HUP trap when reloading this file in an existing shell.
  unfunction TRAPHUP 2>/dev/null || true
  add-zsh-hook -d precmd _zsh_reload_at_precmd 2>/dev/null || true
  add-zsh-hook precmd _zsh_reload_at_precmd
  add-zsh-hook -d zshexit _zsh_reload_unregister 2>/dev/null || true
  add-zsh-hook zshexit _zsh_reload_unregister
  _zsh_reload_register || print -u2 -r -- "reload_zshrcs: unable to register $$"
fi
