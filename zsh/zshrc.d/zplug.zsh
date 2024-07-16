# vim: filetype=zsh
#
#
return
SHELL=zsh

export ZPLUG_HOME=${XDG_DATA_HOME:-$HOME/.local/share}/zplug

if [[ ! -d $ZPLUG_HOME ]]; then
  git clone https://github.com/zplug/zplug $ZPLUG_HOME
fi

source $ZPLUG_HOME/init.zsh

# fix zplug bug
export ZSH="$ZPLUG_REPOS/$_ZPLUG_OHMYZSH"

zplug "commiyou/LS_COLORS", hook-build:"bash install.sh; cp $XDG_DATA_HOME/lscolors.sh .", use:"lscolors.sh", as:plugin

_OHMYZSH_PLUGINS=( fancy-ctrl-z
  fancy-ctrl-z \
  colored-man-pages \
  command-not-found \
  gnu-utils \
  iterm2 \
  fd \
  docker \
  ripgrep \
  jsontools \
  rsync \
  systemadmin \
  urltools \
  clipboard.zsh \
  completion.zsh \
  functions.zsh \
  grep.zsh \
)
for _plugin in "${_OHMYZSH_PLUGINS[@]}"; do
  zplug "plugins/$_plugin", from:oh-my-zsh
done

zplug 'plugins/tmux', hook-load:'ZSH_TMUX_FIXTERM=false ZSH_TMUX_CONFIG=${XDG_CONFIG_HOME}/tmux/tmux.conf', from:oh-my-zsh
zplug 'wfxr/forgit'
zplug 'commiyou/sshrc', as:command, use:sshrc, hook-load:'export SSHHOME=$XDG_CONFIG_HOME'
zplug "psprint/zsh-editing-workbench", hook-build:"local zew_word_style=whitespace"

zplug "ogham/exa"

zplug "junegunn/fzf-bin", \
  from:gh-r, \
  as:command, \
  rename-to:fzf

zplug "antonmedv/fx", \
  from:gh-r, \
  as:command, \
  rename-to:fx

zplug 'commiyou/fzf', as:command, use:bin/fzf-tmux, hook-load:"source $ZPLUG_REPOS/commiyou/fzf/shell/key-bindings.zsh", on:"junegunn/fzf-bin"


zplug "sharkdp/fd", \
  from:gh-r, \
  as:command, \
	hook-build:"cp $ZPLUG_REPOS/sharkdp/fd/**/fd.1 $ZPLUG_HOME/doc/man/man1"

zplug "BurntSushi/ripgrep", \
  from:gh-r, \
  as:command, \
  rename-to:rg, \
  hook-build:"cp $ZPLUG_REPOS/BurntSushi/ripgrep/**/rg.1 $ZPLUG_HOME/doc/man/man1"

zplug "skywind3000/z.lua", hook-load:"export _ZL_DATA=$XDG_CACHE_HOME/.zlua; alias zh='z -I -t .'; alias zb='z -b';", if:'lua -v'
zplug "changyuheng/fz", hook-load:'function _z() { _zlua \"\$@\"; }', on:"skywind3000/z.lua"

[[ $(zsh --version | cut -f2 -d " ") > 5.3  && -n "$ENABLE_P10K" ]] && zplug 'romkatv/powerlevel10k', as:theme, depth:1
zplug "zsh-users/zsh-completions"

zplug "LuRsT/hr", as:command, hook-build:"cp $ZPLUG_REPOS/LuRsT/hr/hr.1 $ZPLUG_HOME/doc/man/man1"
zplug "Aloxaf/fzf-tab", on:"junegunn/fzf-bin", defer:3
zplug 'zdharma/fast-syntax-highlighting', defer:3
zplug 'zsh-users/zsh-autosuggestions', hook-load:'_zsh_autosuggest_start', defer:3

zstyle ':completion:*:*:*:*:processes' command "ps ax -o ppid,pid,user,comm,cmd,time"
zstyle ':fzf-tab:*' fzf-flags '--no-sort'
zstyle ':completion:*' sort 'false'

if ! zplug check; then
  zplug install
fi

zplug load 

if zplug check commiyou/LS_COLORS; then
  zstyle ":completion:*" list-colors ${(s.:.)LS_COLORS}
fi
