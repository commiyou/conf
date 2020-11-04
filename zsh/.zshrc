# vim: filetype=zsh
#
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/confn/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#
if [[ -n "$ENABLE_P10K" && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ "$ZSH_DEBUG" ]]; then
  # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
  PS4=$'%D{%M%S%.} %N:%i> '
  exec 3>&2 2>/tmp/zsh_startup.$$
  setopt xtrace prompt_subst
fi

[ -n $ZDOTDIR ] || ZDOTDIR=${${(%):-%x}:A:h}

for config_file ($ZDOTDIR/zshrc.d/*.zsh) source $config_file

# for config_file ($ZDOTDIR/zshrc.d/*/*.sh) source $config_file

unset config_file

if [[ "$ZSH_DEBUG" ]]; then
  unsetopt xtrace
  exec 2>&3 3>&-
fi

# To customize prompt, run `p10k configure` or edit 
[[ -z "$ENABLE_P10K" ||  ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh
