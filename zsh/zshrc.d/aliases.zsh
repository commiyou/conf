# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
	colorflag="--color"
else # macOS `ls`
	colorflag="-G"
	export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
fi
alias ls=" ls ${colorflag}"
alias l="ls -lF"
alias ll="ls -lhF"
alias la="ls -lhFa"
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

alias dud='du -m -h -s -c -- * | sort -h'
alias sortnr='sort -n -r -k'
alias sortnrt="sort -n -r -t$'\t' -k"

# TODO auto
if [ $(sh -c 'ps -p $$ -o ppid=' | xargs ps -o comm= -p) = "zsh" ]; then
  alias valias="vim $ZDOTDIR/zshrc.d/alias.zsh"
  alias vfunctions="vim $ZDOTDIR/zshrc.d/functions.zsh"
  alias vexports="vim $ZDOTDIR/zsh.before/exports.zsh"
  alias vzsh="(cd $ZDOTDIR; f)"

  hash -d conf=$ZDOTDIR/..
  hash -d vim=$ZDOTDIR/../vim
  hash -d tmux=$ZDOTDIR/../tmux
  hash -d zsh=$ZDOTDIR
  hash -d bin=$ZDOTDIR/bin
  hash -d h=$ZDOTDIR/../..
  # vim last modified file in current dir
  alias -g NF='*(.om[1])'  # newest file
  alias -g ND='*(/om[1])'  # newest directory
  alias vn='vim *(.om[1]^D)'

  alias -g L=" | less"
  alias -g LR="| command less -R"  # less with colors support
  alias -g G=" | LC_ALL=C command grep -i --color=auto -a"
  alias -g P=" | pprint | less"
  alias -g NE="2> /dev/null"
  alias -g NUL="> /dev/null 2>&1"
  alias -g GBK=" | iconv -f utf8 -t gb18030 -c"
  alias -g UTF=" | iconv -f gb18030 -t utf8 -c"
  alias -g LU=" | iconv -f utf8 -t gb18030 -c | less"
  alias -g LG=" | iconv -f gb18030 -t utf8 -c | less"
  alias -g TR1=" | tr '' '\t'"
  alias -g TR,=" | tr ',' '\t'"
  alias -g CSV=" | tr '\t' ',' "

  alias -g E="luit -encoding gb18030"  # env gb18030 to utf
fi

alias ..="cd .."
alias ...="cd ../.."

alias t="tail -f"

alias ln="ln -si"
alias lnf="ln -sf"
alias rgc='rg -t cpp -t protobuf -t c'
alias rgp='rg -t py'
alias rgs='rg -t sh'
alias rga='rg -t sh -t cpp -t py -t protobuf -t c'
alias ipython="BETTER_EXCEPTIONS=0 ipython"  # better exceptions raise exceptions in ipython

alias gst="git status"
alias gl="git pull"
alias gco="git checkout"
alias gcb='git checkout -b'
alias grbc='git rebase --continue'
alias gc='git commit -v'
alias 'gc!'='git commit -v --amend'
alias gd='git diff'
alias gdca='git diff --cached'
alias glog='git log --oneline --decorate --graph'
alias gau='git add --update'
alias gcmsg='git commit -m'
alias ga='git add'

