#!/usr/bin/env bash
#
BASEDIR=$(dirname "$0")
local user_color='green'; [ $UID -eq 0 ] && user_color='red'
if [[ -n "$SSH_CONNECTION" ]]; then
  current_ip=$(echo $SSH_CONNECTION | cut -f3 -d' ')
  export HOSTNAME=$current_ip
  PROMPT='%n@$current_ip %{$fg[$user_color]%}%~%{$reset_color%}%(!.#.>) '
fi


