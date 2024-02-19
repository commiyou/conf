
typeset -g HISTSIZE=290000 SAVEHIST=290000 HISTFILE=${XDG_CACHE_HOME:-$HOME/.cache}/zhistory-${(%):-%n}

[[ "$OSTYPE" == "linux-musl" ]] && OSTYPE=linux
#export OSTYPE=linux-gnu
# Highlight section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";
unset TMOUT

umask 022

export ARTISTIC_STYLE_OPTIONS=${XDG_CONFIG_HOME}/astylerc

export RIPGREP_CONFIG_PATH=${XDG_CONFIG_HOME}/ripgreprc
