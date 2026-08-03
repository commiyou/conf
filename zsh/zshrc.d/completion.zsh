# vi: set ft=sh

zstyle ':completion:*' sort false
zstyle ':completion:*' file-sort 'modification'
## vim advanced completion (e.g. tex and rc files first)
#zstyle ':completion::*:vim:*:*' file-patterns '*Makefile|*(rc|log)|*.(php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3):vi-files:vim\ likes\ these\ files *~(Makefile|*(rc|log)|*.(log|rc|php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3)):all-files:other\ files'

#zstyle ':completion::*:(sh|bash|zsh):*:*' file-patterns '*Makefile|*(rc|log)|*.(php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3):vi-files:vim\ likes\ these\ files *~(Makefile|*(rc|log)|*.(log|rc|php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3)):all-files:other\ files'
zstyle ':completion:*:*:(vim|vi):*:*files' ignored-patterns '*?.o' "*?.pyc"
#zstyle ':completion::*:(sh|bash|zsh):*:*' file-patterns '*.(sh|zsh)' '%p:all-files'
zstyle ':completion::*:source:*:*' file-patterns '*rc|*.(sh|zsh)' '%p:all-files'
zstyle ':completion::*:(vim|vi):*:*' file-patterns \
      '%p:globbed-files' '*:all-files' '*:local-directories' '*:directories'

#zstyle ':completion:*' file-sort access
zstyle ':completion::*:(rg|grep|cat|ls|tac)' file-sort date
#zstyle ':completion:*' sort 'modification'

zstyle ':completion:*:(cd|vi|vim|ls):*' ignore-parents parent pwd

# Ignore what's already in the line
zstyle ':completion:*:(rm|cp|mv|kill|diff|vim|cat|less|more|gzip|gunzip|zcat|tar|fg|bg):*' ignore-line yes
zstyle ':completion:*:*:*:*:processes' command "ps ax -o ppid,pid,user,comm,cmd,time"

# Redirects
zstyle ':completion:*:*:-redirect-,2>,*:*' file-patterns '*.(log|txt)' 'logs/*.log' '%p:all_files'
zstyle ':completion:*:*:-redirect-,2>>,*:*' file-patterns '*.(log|txt)' 'logs/*.log' '%p:all_files'
zstyle ':completion:*:*:-redirect-,>,*:*' file-patterns '*.(log|txt)' 'logs/*.log' '%p:all_files'
zstyle ':completion:*:*:-redirect-,>>,*:*' file-patterns '*.(log|txt)' 'logs/*.log' '%p:all_files'

zstyle ':completion:*' special-dirs true

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion"

zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-min-size 200 8

zcomp-rebuild() {
  emulate -L zsh

  local refresh_rg=
  case ${1:-} in
  '') ;;
  --refresh-rg) refresh_rg=1 ;;
  -h | --help)
    print -r -- 'usage: zcomp-rebuild [--refresh-rg]'
    return
    ;;
  *)
    print -u2 -r -- 'usage: zcomp-rebuild [--refresh-rg]'
    return 1
    ;;
  esac
  (( $# <= 1 )) || {
    print -u2 -r -- 'usage: zcomp-rebuild [--refresh-rg]'
    return 1
  }

  if [[ -n $refresh_rg ]]; then
    if (( ! $+commands[rg] )); then
      print -u2 -r -- 'zcomp-rebuild: rg is unavailable'
      return 1
    fi

    local rg_completion=${ZDOTDIR:-$HOME}/completions/_rg
    local rg_temp
    command mkdir -p -- "${rg_completion:h}" || return 1
    rg_temp=$(command mktemp "$rg_completion.XXXXXX") || return 1
    if ! command rg --generate complete-zsh >|"$rg_temp"; then
      command rm -f -- "$rg_temp"
      print -u2 -r -- 'zcomp-rebuild: failed to generate _rg'
      return 1
    fi
    command chmod 0644 "$rg_temp" || {
      command rm -f -- "$rg_temp"
      return 1
    }
    if [[ -f $rg_completion ]] && command cmp -s -- "$rg_temp" "$rg_completion"; then
      command rm -f -- "$rg_temp"
    else
      command mv -f -- "$rg_temp" "$rg_completion" || return 1
      print -r -- "zcomp-rebuild: refreshed $rg_completion"
    fi
  fi

  local dump_path
  if (( ${+parameters[ZINIT]} )) && [[ -n ${ZINIT[ZCOMPDUMP_PATH]:-} ]]; then
    dump_path=${ZINIT[ZCOMPDUMP_PATH]}
  else
    dump_path=${ZDOTDIR:-$HOME}/.zcompdump
  fi

  command mkdir -p -- "${dump_path:h}" || return 1
  command rm -f -- "$dump_path" "$dump_path.zwc"
  (( $+functions[compinit] )) || autoload -Uz compinit
  compinit -d "$dump_path" || return 1
  print -r -- "zcomp-rebuild: rebuilt $dump_path"
}
