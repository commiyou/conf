# vim: set filetype=zsh
#

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
