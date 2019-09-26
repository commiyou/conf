#!/usr/bin/env bash
if uname -r | grep -q 'Microsoft'; then
  # Fix the ls and cd colours
  #Change ls colours
  LS_COLORS="ow=01;36;40" && export LS_COLORS

  #make cd use the ls colours
  zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
  autoload -Uz compinit
  compinit
fi
