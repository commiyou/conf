# vim: filetype=zsh
#
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/confn/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#
#zmodload zsh/zprof
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


[ -n $ZDOTDIR ] || ZDOTDIR=${${(%):-%x}:A:h}

for config_file ($ZDOTDIR/zshrc.d/*.zsh) source $config_file

unset config_file

# To customize prompt, run `p10k configure` or edit 
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh;
[[ ! -f ~/.self.zshrc ]] || source ~/.self.zshrc;
