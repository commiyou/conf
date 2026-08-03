# get the ftp path of files, defalut CWD
fpath+=($ZDOTDIR/functions)
autoload -Uz "$ZDOTDIR"/functions/*(:t)

gconfig() {
  local email name tmp_name
  if [[ $# -eq 1 ]] && echo "$1" | grep -E '.+@.+\..+' -q; then
    email="$1"
    name=${email%@*}
  else
    while true; do
      echo "git user.email?"
      read email
      if echo "$email" | grep -E '.+@.+\..+' -q; then
        break
      fi
    done

    tmp_name=${email%@*}
    echo "git user.name<$tmp_name>?"
    read -t 3 tmp_name
    if [[ -z "$tmp_name" || $tmp_name == "y" || $tmp_name == "Y" ]]; then
      name=${email%@*}
    else
      name=$tmp_name
    fi
  fi

  echo git config user.name "$name", user.email "$email"
  git config user.email "$email"
  git config user.name "$name"
  git config http.postBuffer 524288000
  git config credential.helper "cache --timeout=3600"
  git config alias.a add
  git config alias.amend "commit --amend -C HEAD"
  git config alias.br branch
  git config alias.cb "checkout -b"
  git config alias.ci commit
  git config alias.cim "commit -m"
  git config alias.co checkout
  git config alias.cp cherry-pick
  git config alias.df diff
  git config alias.dh "diff HEAD"
  git config alias.dc "diff --cached"
  git config alias.pl pull
  git config alias.rb rebase
  git config alias.rh reset HEAD
  git config alias.st status
  git config color.grep.filename magenta
  git config pull.rebase true
  git config rebase.autoStash true
}

alias ginit="git init; gconfig"

# edit git ignore with vim
vignore() {
  git status >/dev/null || return 1
  vim $(git rev-parse --show-toplevel)/.gitignore
}

# myip() {
#   if [[ -n "$SSH_CONNECTION" ]]; then
#     echo $SSH_CONNECTION | cut -f3 -d' '
#   else
#     hostname -i | tail -n +1 | xargs -n1
#   fi
# }
#
# run a web server whit port in 8000~8999 in 10 minutes
websvr() {
  local port
  if [[ ${1:-} == '-r' ]]; then
    port=$((8000 + (RANDOM % 1000)))
  elif [[ -n ${1:-} ]]; then
    port=$1
  else
    port=8000
  fi

  local timeout_command
  if (( $+commands[timeout] || $+functions[timeout] )); then
    timeout_command=timeout
  elif (( $+commands[gtimeout] || $+functions[gtimeout] )); then
    timeout_command=gtimeout
  else
    print -u2 -r -- "websvr: timeout is unavailable; install GNU coreutils"
    return 1
  fi

  local ip_ file url_path
  local -a recent_files=(**/*(.DNom[1,10]))
  "$timeout_command" 10m python3 -m http.server "$port" 2>&1 &
  for ip_ in $(myip); do
    for file in "${recent_files[@]}"; do
      url_path=${file//\%/%25}
      url_path=${url_path// /%20}
      url_path=${url_path//\#/%23}
      url_path=${url_path//\?/%3F}
      print -r -- "http://$ip_:$port/$url_path"
    done
    print
    print -r -- "http://$ip_:$port starting..."
    print
  done
}

# symbokic files under TARGET to DEST dir
# args:
#     $1 -> TARGET dir,
#     $2 -> DEST dir
link_dir() {
  [[ $# != 2 ]] && echo "usage: link_dir src dst" && return 1
  local target=$(realpath "$1")
  local dest="$2"
  cp -as "$target/" "$dest"
}

# replace symbolic link with real file
restore_link() {
  for link in "$@"; do
    test -h "$link" || continue
    dir=$(dirname "$link")
    reltarget=$(readlink "$link")
    case $reltarget in
    /*) abstarget=$reltarget ;;
    *) abstarget=$dir/$reltarget ;;
    esac

    rm -fv "$link"
    cp -afv "$abstarget" "$link" || {
      # on failure, restore the symlink
      rm -rfv "$link"
      ln -sfv "$reltarget" "$link"
    }
  done
}

# Compatibility wrapper for exchange.
swap() {
  exchange "$@"
}

set_iterm_profile() {
  local profile=${1:-gbk}
  send-terminal-sequence "\033]50;SetProfile=$profile\a"
}

send-terminal-sequence() {
  local sequence="$1"
  local is_tmux
  if [[ -n $TMUX_PASSTHROUGH ]] || [[ -n $TMUX ]]; then
    is_tmux=1
  fi
  if [[ -n $is_tmux ]]; then
    sequence=${sequence//\\(e|x27|033|u001[bB]|U0000001[bB])/\\e\\e}
    sequence="\ePtmux;$sequence\e\\"
  fi
  print -n "$sequence"
}
alias sip=set_iterm_profile

tr0() {
  zmodload -F zsh/stat b:zstat || {
    print -u2 -r -- "tr0: cannot load zsh/stat"
    return 1
  }

  local f tmp target_dir file_mode
  local -A file_stat
  local result=0
  for f in "$@"; do
    if [[ ! -f $f ]]; then
      print -u2 -r -- "tr0: not a regular file: $f"
      result=1
      continue
    fi

    file_stat=()
    if ! zstat -H file_stat -- "$f"; then
      print -u2 -r -- "tr0: cannot stat: $f"
      result=1
      continue
    fi
    file_mode=$(([##8] (${file_stat[mode]} & 8#7777)))
    target_dir=${f:h:A}
    tmp=
    if ! tmp=$(mktemp "$target_dir/.${f:t}.tr0.XXXXXX"); then
      print -u2 -r -- "tr0: cannot create temporary file for: $f"
      result=1
      continue
    fi

    if ! command tr $'\x01' $'\t' <"$f" >|"$tmp" ||
      ! command chmod -- "$file_mode" "$tmp" ||
      ! command mv -f -- "$tmp" "$f"; then
      print -u2 -r -- "tr0: failed to convert: $f"
      command rm -f -- "$tmp"
      result=1
    fi
  done
  return $result
}

field_match() {
  local f="${1:?no field}"
  local v="${2?no value}"
  awk -F"\t" '$'"$f"'~/'"$v"'/'
}
alias f1m="field_match 1 "
alias f2m="field_match 2 "
alias f3m="field_match 3 "
alias f4m="field_match 4 "
alias f5m="field_match 5 "
alias f6m="field_match 6 "
alias ftm="field_match 'NF' " # NF is global alias of newest file

# extract with new dir
if typeset -f extract >/dev/null; then
  extractd() {
    local result=0
    for f in "$@"; do
      local real_path=${f:A}
      local file_name=${real_path:t}
      local real_file_name="${file_name:r}"
      if [[ -e $real_file_name ]]; then
        print -u2 -r -- "extractd: target already exists: $real_file_name"
        result=1
        continue
      fi
      if ! mkdir -- "$real_file_name"; then
        print -u2 -r -- "extractd: cannot create target directory: $real_file_name"
        result=1
        continue
      fi
      (
        cd -- "$real_file_name" && extract "$real_path"
      ) || result=1
    done
    return $result
  }
fi

bash-set-title() {
  if [[ -z "$ORIG" ]]; then
    ORIG=$PS1
  fi
  TITLE="\[\e]2;$*\a\]"
  PS1=${ORIG}${TITLE}
}

# Search history for entries containing every keyword.
h() {
  if (( $# == 0 )); then
    history -i 1
    return
  fi

  local -a entries=("${(@f)$(history -i 1)}")
  local -a matches
  local keyword entry
  for keyword in "$@"; do
    matches=()
    for entry in "${entries[@]}"; do
      [[ $entry == *"$keyword"* ]] && matches+=("$entry")
    done
    entries=("${matches[@]}")
    (( ${#entries} )) || return 1
  done
  print -rl -- "${entries[@]}"
}
