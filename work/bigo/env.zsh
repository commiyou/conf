#!/usr/bin/env bash

alias nocorrect=""
current_ip=$(echo $SSH_CONNECTION | cut -f3 -d' ')
if [[ $HOSTNAME =~ bigo && $HOSTNAME =~ jump ]]; then
  :
else
  export HOSTNAME_OLD=$HOSTNAME
  export HOSTNAME=$current_ip
fi
if [ $(current_shell) != 'zsh' ]; then
  # defined in zsh/zshrc.d/functions.zsh
  user_color="$Green"; [ $UID -eq 0 ] && user_color="$Red"
  PS1="$user_color\u@$HOSTNAME$Color_Off \w> "
  bash-set-title $HOSTNAME
else 
  local user_color='green'; [ $UID -eq 0 ] && user_color='red'
  if [[ -n "$SSH_CONNECTION" ]]; then
    PROMPT='%n@$HOSTNAME %{$fg[$user_color]%}%~%{$reset_color%}%(!.#.>) '
  fi
fi
