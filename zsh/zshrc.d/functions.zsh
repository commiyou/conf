# get the ftp path of files, defalut CWD
#
[ -f "$XDG_CONFIG_HOME/rc.d/functionrc" ] && source $XDG_CONFIG_HOME/rc.d/functionrc

fpath+=( $ZDOTDIR/functions )
autoload -Uz $ZDOTDIR/functions/*(:t)


gconfig() {
  local email name tmp_name
  while true;
  do
    echo "git user.email?" 
    read email
    if echo "$email" |  grep -E '.+@.+\..+' -q
    then
      break
    fi
  done

  tmp_name=${email%@*}
  echo "git user.name<$tmp_name>?" 
  read  -t 3 tmp_name
  if [[ -z "$tmp_name" || $tmp_name == "y" || $tmp_name == "Y" ]]; then
    name=${email%@*}
  else
    name=$tmp_name
  fi

  echo git config user.name $name, user.email $email
	git config user.email $email
	git config user.name $name
	git config http.postBuffer 524288000
	git config  credential.helper "cache --timeout=3600"
	git config  alias.a add
	git config  alias.amend "commit --amend -C HEAD"
	git config  alias.br branch
	git config  alias.cb "checkout -b"
	git config  alias.ci commit
	git config  alias.cim "commit -m"
	git config  alias.co checkouout
	git config  alias.cp cherry-pick
	git config  alias.df diff
	git config  alias.dh "diff HEAD"
	git config  alias.dc "diff --cached"
	git config  alias.pl pull
	git config  alias.rb rebase
	git config  alias.rh reset HEAD
	git config  alias.st status
	git config  color.grep.filename magenta
  git config pull.rebase true
  git config rebase.autoStash true
}

alias ginit="git init; gconfig"


# edit git ignore with vim
vignore() {
	git status > /dev/null || return 1
	vim $(git rev-parse --show-toplevel)/.gitignore
}


myip() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    echo $SSH_CONNECTION | cut -f3 -d' '
  else 
    /sbin/ifconfig eth0 | grep 'inet addr' | cut -f12 -d ' ' | cut -f2 -d':'
  fi
}

# run a web server whit port in 8000~8999 in 10 minutes
websvr() {
  if [[ "$1" == '-r' ]]; then
    LPORT=8000;
    UPORT=1000;
    MPORT=$[$LPORT + ($RANDOM % $UPORT)];
  elif [[ -n "$1" ]]; then
    MPORT=$1
  else
    MPORT=8000
  fi
  timeout 10m python -m SimpleHTTPServer $MPORT > /dev/null 2>&1   &
  if [[ $(ls | wc -l) -lt 10 ]]; then
    for l in "$(ls)"
    do
      echo http://$(myip):$MPORT/$l
    done
  fi

  echo http://$(myip):$MPORT starting...
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
  for link in "$@"
  do
    test -h "$link" || continue
    dir=$(dirname "$link")
    reltarget=$(readlink "$link")
    case $reltarget in
        /*) abstarget=$reltarget;;
        *)  abstarget=$dir/$reltarget;;
    esac

    rm -fv "$link"
    cp -afv "$abstarget" "$link" || {
        # on failure, restore the symlink
        rm -rfv "$link"
        ln -sfv "$reltarget" "$link"
      }
  done
}


# zsh trap function when recive HUG signal
TRAPHUP() {
  source $ZDOTDIR/.zshrc
}

# reload zshrcs
reload_zshrcs() {
  for pid in $(pgrep zsh -u $USER)
  do
    if [ -n "$1" ]; then
      echo "sending HUP to pid $pid .."
    fi
    if [[ $OSTYPE =~ darwin ]]; then
      kill -HUP $pid
    else
      # for Accounts used by multiple people
      cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -q "ZDOTDIR=$ZDOTDIR" && kill -HUP $pid
    fi
  done
}

# swap file from src to dst
# args:
#   $1 -> src file path
#   $2 -> dst file path
swap() {
    local TMPFILE=tmp.$$
    mv "$1" $TMPFILE && mv "$2" "$1" && mv $TMPFILE $2
}

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

echor () {
  echo -e "${Red}$*${Color_Off}"
}

echog () {
  echo -e "${Green}$*${Color_Off}"
}

set_iterm_profile () {
	local profile=${1:-gbk}
	send-terminal-sequence "\033]50;SetProfile=$profile\a"
}

send-terminal-sequence () {
	local sequence="$1"
	local is_tmux
	if [[ -n $TMUX_PASSTHROUGH ]] || [[ -n $TMUX ]]
	then
		is_tmux=1
	fi
	if [[ -n $is_tmux ]]
	then
		sequence=${sequence//\\(e|x27|033|u001[bB]|U0000001[bB])/\\e\\e}
		sequence="\ePtmux;$sequence\e\\"
	fi
	print -n "$sequence"
}
alias sip=set_iterm_profile

tr0() {
  for f in "$@"
  do
    TMPFILE=`mktemp`
    cat "$f" | tr '' '\t' > $TMPFILE && mv -f $TMPFILE "$f" || "tr $f error, skip.."
  done
}

field_match() {
  local f="${1:?no field}"
  local v="${2?no value}"
  awk -F"\t" '$'$f'~/'$v'/'
}
alias f1m="field_match 1 "
alias f2m="field_match 2 "
alias f3m="field_match 3 "
alias f4m="field_match 4 "
alias f5m="field_match 5 "
alias f6m="field_match 6 "
alias ftm="field_match 'NF' "  # NF is global alias of newest file

# extract with new dir
extractd() {
  for f in "$@"; do
    local real_path=$(realpath "$f")
    local file_name=$(basename "$real_path")
    local real_file_name="${file_name%%.*}"
    if ! mkdir "$real_file_name" 
    then
      "dir $real_file_name is exist, skip ..."
      continue
    fi
    cd "$real_file_name"
    extract "$real_path"
    cd ..
  done
}



bash-set-title() {
  if [[ -z "$ORIG" ]]; then
    ORIG=$PS1
  fi
  TITLE="\[\e]2;$*\a\]"
  PS1=${ORIG}${TITLE}
}
