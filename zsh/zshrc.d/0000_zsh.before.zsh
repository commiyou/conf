typeset -g HISTSIZE=290000 SAVEHIST=290000 HISTFILE=${ZDOTDIR:-$HOME}/.zhistory ABSD=${${(M)OSTYPE:#*(darwin|bsd)*}:+1}

(( ABSD )) && {
    export LSCOLORS=dxfxcxdxbxegedabagacad CLICOLOR="1" 
}

export EDITOR="vim" LESS="-iRFX" CVS_RSH="ssh"
export TERM=xterm-256color
#export OSTYPE=linux-gnu
# Highlight section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";
unset TMOUT

umask 022


