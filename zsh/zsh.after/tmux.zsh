if ! (( $+commands[tmux] )); then
  # print "zsh tmux plugin: tmux not found. Please install tmux before using this plugin." >&2
  return 1
fi

# ALIASES

alias ta='tmux attach -t'
alias tad='tmux attach -d -t'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias tksv='tmux kill-server'
alias tkss='tmux kill-session -t'

# CONFIGURATION VARIABLES
# Automatically start tmux
: ${ZSH_TMUX_AUTOSTART:=false}
# Only autostart once. If set to false, tmux will attempt to
# autostart every time your zsh configs are reloaded.
: ${ZSH_TMUX_AUTOSTART_ONCE:=true}
# Automatically connect to a previous session if it exists
: ${ZSH_TMUX_AUTOCONNECT:=true}
# Automatically close the terminal when tmux exits
: ${ZSH_TMUX_AUTOQUIT:=$ZSH_TMUX_AUTOSTART}
# Set term to screen or screen-256color based on current terminal support
: ${ZSH_TMUX_FIXTERM:=true}
# Set '-CC' option for iTerm2 tmux integration
: ${ZSH_TMUX_ITERM2:=false}
# The TERM to use for non-256 color terminals.
# Tmux states this should be screen, but you may need to change it on
# systems without the proper terminfo
: ${ZSH_TMUX_FIXTERM_WITHOUT_256COLOR:=screen}
# The TERM to use for 256 color terminals.
# Tmux states this should be screen-256color, but you may need to change it on
# systems without the proper terminfo
: ${ZSH_TMUX_FIXTERM_WITH_256COLOR:=screen-256color}

# Determine if the terminal supports 256 colors
if [[ $terminfo[colors] == 256 ]]; then
  export ZSH_TMUX_TERM=$ZSH_TMUX_FIXTERM_WITH_256COLOR
else
  export ZSH_TMUX_TERM=$ZSH_TMUX_FIXTERM_WITHOUT_256COLOR
fi

# Set the correct local config file to use.
if [ ! -e "$_ZSH_TMUX_FIXED_CONFIG" ]; then
  if [ -e $ZDOTDIR/../tmux/tmux.conf ]; then
    export TMUX_DIR=$(cd "$ZDOTDIR/../tmux"; pwd)
    export TMUX_CONF="$TMUX_DIR/tmux.conf"
    _ZSH_TMUX_FIXED_CONFIG="$TMUX_CONF"
  fi
fi


if [[ $(hostname) =~ "\.com$" && $USER == work ]]; then
  if [[ -z "$ZSH_TMUX_SOCKET_NAME" ]]; then
    ZSH_TMUX_SOCKET_NAME=$(basename $(realpath $ZDOTDIR/../..;))
  fi
fi


# Wrapper function for tmux.
function _zsh_tmux_plugin_run() {
  local -a tmux_cmd
  tmux_cmd=(command tmux)
  [[ -n "$ZSH_TMUX_SOCKET_NAME" ]] && tmux_cmd+=(-L "$ZSH_TMUX_SOCKET_NAME")
  if [[ -n "$@" ]]; then
    $tmux_cmd "$@"
    return $?
  fi

  [[ "$ZSH_TMUX_ITERM2" == "true" ]] && tmux_cmd+=(-CC)

  # Try to connect to an existing session.
  [[ "$ZSH_TMUX_AUTOCONNECT" == "true" ]] && $tmux_cmd attach

  # If failed, just run tmux, fixing the TERM variable if requested.
  if [[ $? -ne 0 ]]; then
    [[ "$ZSH_TMUX_FIXTERM" == "true" ]] && tmux_cmd+=(-f "$_ZSH_TMUX_FIXED_CONFIG")
    $tmux_cmd new-session
  fi

  if [[ "$ZSH_TMUX_AUTOQUIT" == "true" ]]; then
    exit
  fi
}

# Use the completions for tmux for our function
compdef _tmux _zsh_tmux_plugin_run
# Alias tmux to our wrapper function.
alias tmux=_zsh_tmux_plugin_run

# Autostart if not already in tmux and enabled.
if [[ -z "$TMUX" && "$ZSH_TMUX_AUTOSTART" == "true" && -z "$INSIDE_EMACS" && -z "$EMACS" && -z "$VIM" ]]; then
  # Actually don't autostart if we already did and multiple autostarts are disabled.
  if [[ "$ZSH_TMUX_AUTOSTART_ONCE" == "false" || "$ZSH_TMUX_AUTOSTARTED" != "true" ]]; then
    export ZSH_TMUX_AUTOSTARTED=true
    _zsh_tmux_plugin_run
  fi
fi
