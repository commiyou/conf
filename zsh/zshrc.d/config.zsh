# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/confn/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

typeset -g HISTSIZE=290000 SAVEHIST=290000 HISTFILE=${XDG_CACHE_HOME:-$HOME/.cache}/zhistory-${(%):-%n}

[[ "$OSTYPE" == "linux-musl" ]] && OSTYPE=linux
#export OSTYPE=linux-gnu
# Highlight section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";
unset TMOUT

umask 022
