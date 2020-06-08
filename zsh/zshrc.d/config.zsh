# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/confn/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit .p10k.zsh.
# [[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

typeset -g HISTSIZE=290000 SAVEHIST=290000 HISTFILE=${XDG_CACHE_HOME:-$HOME/.cache}/zhistory-${(%):-%n}

#export OSTYPE=linux-gnu
# Highlight section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";
unset TMOUT

umask 022
