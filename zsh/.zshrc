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


[[ -n ${ZDOTDIR:-} ]] || ZDOTDIR=${${(%):-%x}:A:h}
export ZDOTDIR

for config_file ($XDG_CONFIG_HOME/rc.d/*rc(N)) source "$config_file"
for config_file ($ZDOTDIR/zshrc.d/*.zsh(N)) source "$config_file"

unset config_file

[[ ! -f ~/.self.sh ]] || source ~/.self.sh

# icode completion
fpath=("$ZDOTDIR/.zsh/completions" $fpath)
if (( $+functions[zicompinit] )); then
  zicompinit
else
  autoload -Uz compinit
  compinit
fi


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/youbin/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/youbin/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/youbin/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/youbin/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# bun completions
[ -s "/Users/youbin/.bun/_bun" ] && source "/Users/youbin/.bun/_bun"
