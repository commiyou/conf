# vim: filetype=zsh

SHELL=zsh
#command -v ruby > /dev/null && command -v gem >/dev/null || return
[ -n "$USE_ZPLUG" ] && return

typeset -A ZINIT=(
  BIN_DIR         ${XDG_DATA_HOME:-$HOME/.local/share}/zinit/bin
  HOME_DIR        ${XDG_DATA_HOME:-$HOME/.local/share}/zinit
  ZCOMPDUMP_PATH  ${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-${(%):-%n}
  COMPINIT_OPTS   -C
)

hash -d zinit=$ZINIT[HOME_DIR]

### Added by Zinit's installer
if [[ ! -f $ZINIT[BIN_DIR]/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  command mkdir -p "$ZINIT[HOME_DIR]" && command chmod g-rwX "$ZINIT[HOME_DIR]"
  command git clone https://github.com/commiyou/zinit "$ZINIT[BIN_DIR]" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source $ZINIT[BIN_DIR]/zinit.zsh

#### plugins
load=load
[[ $load == light ]] && lightmode=light-mode || lightmode=

zinit ice atclone"bash install.sh" \
  atpull'%atclone' pick"$XDG_DATA_HOME/lscolors.sh" nocompile'!' \
  atload'!zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' 
zinit $load commiyou/LS_COLORS

zinit $lightmode wait lucid for \
  OMZP::fancy-ctrl-z \
  OMZP::colored-man-pages \
  OMZP::command-not-found \
  OMZP::gnu-utils \
  OMZP::iterm2 \
  OMZP::rsync \
  OMZP::systemadmin \
  OMZP::urltools \
  OMZP::jsontools \
  OMZP::extract \
  OMZP::thefuck \
  OMZL::clipboard.zsh \
  OMZL::completion.zsh \
  OMZL::functions.zsh \
  OMZL::grep.zsh 

#zplugin ice wait'1' lucid
#zplugin light laggardkernel/zsh-thefuck

# $'string'  quote https://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings/16605140#16605140
# fzf-marks, at slot 0, for quick Ctrl-G accessibility
zinit $lightmode wait lucid for \
  hlissner/zsh-autopair \
  urbainvaes/fzf-marks \
  atload$'!FORGIT_LOG_FZF_OPTS=\'--bind="ctrl-e:execute(echo {} |grep -Eo [a-f0-9]+ |head -1 |xargs git show |vim -)"\'; \
    alias gdca="forgit::diff --cached"; \
    alias glog="forgit::log --oneline --decorate --graph"; \
    compdef _git gco=git-checkout; \
    ' wfxr/forgit \
  as"program" pick'bin/fzf-tmux' src'shell/key-bindings.zsh'  trackbinds bindmap='^T -> ^X^T; \ec -> ^X\ec' commiyou/fzf \
  as"program" atload'export SSHHOME=$XDG_CONFIG_HOME' pick'sshrc' commiyou/sshrc \
  has"tmux" atload$'!ZSH_TMUX_FIXTERM=false; \
    ZSH_TMUX_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf; \
    compdef _zsh_tmux_plugin_run=tmux; \
    ' svn OMZP::tmux

zinit $lightmode wait"1" lucid for \
  atinit"local zew_word_style=whitespace" \
  commiyou/zsh-editing-workbench

zinit $lightmode wait"1" lucid from"gh-r" as"program" for \
  if'[[ ! ${commands[exa]} ]]' mv"exa* -> exa" pick'exa' ogham/exa \
  if'[[ ! ${commands[fd]} ]]' mv"fd* -> fd"  pick'fd/fd' @sharkdp/fd \
  if'[[ ! ${commands[rg]} ]]' mv"ripgrep* -> rg" pick'rg/rg' BurntSushi/ripgrep \
  junegunn/fzf


zinit $lightmode wait"1" lucid has'lua' for \
  atload'!export _ZL_DATA=$XDG_CACHE_HOME/.zlua; alias zh="z -I -t ."; alias zb="z -b" ' skywind3000/z.lua \
  atload'!function _z() { _zlua "$@"; }; alias z="nocorrect _fz"' changyuheng/fz

# light-mode within zshrc – for the instant prompt
zinit ice atload"!source ${ZDOTDIR:-$HOME}/.p10k.zsh" lucid nocd depth=1
zinit $load romkatv/powerlevel10k

# completions
zinit $lightmode wait lucid as"completion" for \
  svn OMZP::fd \
  svn OMZP::docker \
  svn OMZP::ripgrep 

local cf
if [ -n "$WORK_ENV" ] && [ -d $XDG_CONFIG_HOME/work/$WORK_ENV/ ]; then
  #source $config_file
  #for cf ($XDG_CONFIG_HOME/work/$WORK_ENV/*.sh) zinit snippet $cf
  zinit $lightmode wait'0c' lucid is-snippet for \
    $XDG_CONFIG_HOME/work/$WORK_ENV/functions.sh 
fi

# Fast-syntax-highlighting & autosuggestions
zinit $lightmode wait'0b' lucid for \
  atinit"zicompinit; zicdreplay" commiyou/fast-syntax-highlighting \
  atload"!zstyle ':fzf-tab:complete:(cd|z):*' fzf-preview 'exa -1 --color=always \$realpath';" Aloxaf/fzf-tab \
  atload"!_zsh_autosuggest_start" zsh-users/zsh-autosuggestions 

zinit $lightmode wait lucid blockf atpull'zinit creinstall -q .' for zsh-users/zsh-completions 
