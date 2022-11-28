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

for config_file ($XDG_CONFIG_HOME/rc.d/*.sh) source $config_file
for config_file ($ZDOTDIR/zshrc.d/*.zsh) source $config_file

unset config_file

# To customize prompt, run `p10k configure` or edit 
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh;
[[ ! -f ~/.self.zshrc ]] || source ~/.self.zshrc;

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/bin.you/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#    eval "$__conda_setup"
# else
#    if [ -f "/home/bin.you/miniconda3/etc/profile.d/conda.sh" ]; then
#        . "/home/bin.you/miniconda3/etc/profile.d/conda.sh"
#    else
#        export PATH="/home/bin.you/miniconda3/bin:$PATH"
#    fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

