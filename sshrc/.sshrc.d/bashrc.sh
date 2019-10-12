if ls --color > /dev/null 2>&1; then # GNU `ls`
	colorflag="--color"
else # macOS `ls`
	colorflag="-G"
	export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
fi
alias ls=" ls ${colorflag}"
alias l="ls -lF"
alias ll="ls -lhF"
alias lrt="ls -lrth"
alias lrS="ls -lrSh"
alias ld="ls -lF | grep --color=never '^d'"

alias cp="cp -i"
alias mv="mv -i"
alias md="mkdir -p"
mdc() {
  mkdir -p $1 && cd $1
}
alias rm="rm -i"
alias rmr="rm -rf"
alias which="which -a"
alias touch="touch"

alias history=" history"

alias vi=vim
alias wcl="wc -l"
alias df=" df -lh"
alias pytest="py.test --cache-clear"

alias k1="kill %1"
alias k2="kill %2"
alias k3="kill %3"
alias k4="kill %4"
alias k91="kill -9 %1"
alias k92="kill -9 %2"
alias k93="kill -9 %3"
alias k94="kill -9 %4"
alias grep="grep --color -a"
alias ack="ack --color"

alias gsa="git submodule add"

# fix sort bug
alias sort="LC_ALL=C sort"  
alias uniq="LC_ALL=C uniq"
alias grep="LC_ALL=C grep"

alias awkt='LC_ALL=C awk -F"\t"'
alias cutt="cut -d$'\t'"
alias sortt="LC_ALL=C sort -t$'\t'"

alias ..="cd .."
alias ...="cd ../.."

alias t="tail -f"

alias dud='du -d 1 -h'
alias sortnr='sort -n -r -k'
alias sortnrt="sort -n -r -t$'\t' -k"

alias ga='git add'
alias gau='git add --update'
alias gba='git branch -a'
alias gbr='git branch --remote'
alias gc!='git commit -v --amend'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gca!='git commit -v -a --amend'
alias gdca='git diff --cached'
alias gupa='git pull --rebase --autostash'
alias gup='git pull --rebase'
alias gst='git status'

myip() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    echo $SSH_CONNECTION | cut -f3 -d' '
  else 
    /sbin/ifconfig eth0 | grep 'inet addr' | cut -f12 -d ' ' | cut -f2 -d':'
  fi
}

# run a web server whit port in 8000~8999 in 10 minutes
websvr() {
  LPORT=8000;
  UPORT=1000;
  MPORT=$[$LPORT + ($RANDOM % $UPORT)];
  timeout 10m python -m SimpleHTTPServer $MPORT > /dev/null 2>&1   &
  echo http://$(myip):$MPORT starting...
}


# calc expresion
C() {
	python -c "from __future__ import division;print '%.3f' % ($@)"
}

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
