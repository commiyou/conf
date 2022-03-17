# vi : syntax=sh
#
: ${XDG_CONFIG_HOME:=~/conf}
export XDG_CONFIG_HOME
: ${XDG_CACHE_HOME:="${HOME}/.cache"}
export XDG_CACHE_HOME
: ${XDG_DATA_HOME:="${HOME}/.local/share"}
export XDG_DATA_HOME
: ${XDG_RUNTIME_DIR:="${HOME}/.local/run"}
export XDG_RUNTIME_DIR

export EDITOR=vim
[ -f $XDG_CONFIG_HOME/vim/vimrc ] && export VIMINIT="source $XDG_CONFIG_HOME/vim/vimrc"

export LESS="-igRFX"

#export TERM="xterm-256color"

[ -f $XDG_CONFIG_HOME/zsh/.zshrc ] && export ZDOTDIR=${XDG_CONFIG_HOME}/zsh

unset TMOUT

umask 022

# load work rcfiles
export WORK_ENV=allride
#[ -f ~/.Xmodmap ] && xmodmap ~/.Xmodmap
