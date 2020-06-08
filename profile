# vim: set ft=sh
export XDG_CONFIG_HOME=~/confn
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_RUNTIME_DIR="${HOME}/.local/run"

export EDITOR=vim

export LESS="-igRFX"

export TERM="xterm-256color"

export ZDOTDIR=${XDG_CONFIG_HOME}/zsh

unset TMOUT

umask 022
