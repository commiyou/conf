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

alias cp="nocorrect cp -i"
alias mv="nocorrect mv -i"
alias md="nocorrect mkdir -p"
mdc() {
  nocorrect mkdir -p $1 && cd $1
}
alias rm="nocorrect rm -i"
alias rmr="nocorrect rm -rf"
alias which="nocorrect which -a"
alias touch="nocorrect touch"

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
