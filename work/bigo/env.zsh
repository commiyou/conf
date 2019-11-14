#!/usr/bin/env bash
#
BASEDIR=$(dirname "$0")
current_ip=$(echo $SSH_CONNECTION | cut -f3 -d' ')
export HOSTNAME=$current_ip
if [ $0 == 'zsh' ]; then
  local user_color='green'; [ $UID -eq 0 ] && user_color='red'
  if [[ -n "$SSH_CONNECTION" ]]; then
    PROMPT='%n@$current_ip %{$fg[$user_color]%}%~%{$reset_color%}%(!.#.>) '
  fi
else 
  # defined in zsh/zshrc.d/functions.zsh
  user_color="$Green"; [ $UID -eq 0 ] && user_color="$Red"
  PS1="$user_color\u@$current_ip$Color_Off \w> "
fi
