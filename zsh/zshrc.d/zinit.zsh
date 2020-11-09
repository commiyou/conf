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
  command git clone https://github.com/zdharma/zinit "$ZINIT[BIN_DIR]" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source $ZINIT[BIN_DIR]/zinit.zsh

#### plugins
load=load
[[ $load == light ]] && lightmode=light-mode || lightmode=

zinit ice atclone"!bash install.sh" \
  atpull'%atclone' pick"$XDG_DATA_HOME/lscolors.sh" nocompile'!' \
  atload'!zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' 
zinit $load commiyou/LS_COLORS

zinit $lightmode wait lucid for \
  OMZP::fancy-ctrl-z \
  OMZP::colored-man-pages \
  OMZP::command-not-found \
  OMZP::gnu-utils \
  OMZP::iterm2 \
  OMZP::jsontools \
  OMZP::rsync \
  OMZP::systemadmin \
  OMZP::urltools \
  OMZL::clipboard.zsh \
  OMZL::completion.zsh \
  OMZL::functions.zsh \
  OMZL::grep.zsh \
  #OMZP::vi-mode 

#zplugin ice wait'1' lucid
#zplugin light laggardkernel/zsh-thefuck

# fzf-marks, at slot 0, for quick Ctrl-G accessibility
zinit $lightmode wait lucid for \
  hlissner/zsh-autopair \
  urbainvaes/fzf-marks \
  wfxr/forgit \
  src'shell/key-bindings.zsh'  trackbinds bindmap='^T -> ^X^T; \ec -> ^X\ec' commiyou/fzf \
  atload'export SSHHOME=$XDG_CONFIG_HOME' commiyou/sshrc \
  has"tmux" atload'!ZSH_TMUX_FIXTERM=false ZSH_TMUX_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf'  svn OMZP::tmux

zinit $lightmode wait"1" lucid for \
  atinit"local zew_word_style=whitespace" \
  psprint/zsh-editing-workbench

zinit $lightmode wait"2" lucid as"null" from"gh-r" as"program" for \
  mv"exa* -> exa" ogham/exa \
  mv"fd* -> fd"  @sharkdp/fd \
  mv"ripgrep* -> rg" BurntSushi/ripgrep \
  junegunn/fzf-bin 


zinit $lightmode wait"2" lucid has'lua' for \
  atload'!export _ZL_DATA=$XDG_CACHE_HOME/.zlua; alias zh="z -I -t ."; alias zb="z -b" ' skywind3000/z.lua \
  atload'!function _z() { _zlua "$@"; }' changyuheng/fz

# light-mode within zshrc – for the instant prompt
zinit ice atload"!source ${ZDOTDIR:-$HOME}/.p10k.zsh" lucid nocd depth=1
zinit $load romkatv/powerlevel10k

# completions
zinit $lightmode wait lucid blockf atpull'!zinit creinstall -q .' for \
  zsh-users/zsh-completions \
  as"completion" svn OMZP::fd \
  as"completion" svn OMZP::docker \
  as"completion" svn OMZP::ripgrep \

# Fast-syntax-highlighting & autosuggestions
zpcompinit; zpcdreplay
  #atinit"!zicompinit; zicdreplay" \
zinit $lightmode wait'0b' lucid for \
  Aloxaf/fzf-tab atload"!zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always \$realpath';  zstyle ':fzf-tab:complete:z:*' fzf-preview 'exa -1 --color=always \$realpath'"\
  zdharma/fast-syntax-highlighting \
  atload"!_zsh_autosuggest_start" zsh-users/zsh-autosuggestions 

local cf
if [ -n "$WORK_ENV" ] && [ -d $XDG_CONFIG_HOME/work/$WORK_ENV/ ]; then
  #source $config_file
  #for cf ($XDG_CONFIG_HOME/work/$WORK_ENV/*.sh) zinit snippet $cf
  zinit $lightmode wait'0c' lucid is-snippet for \
    $XDG_CONFIG_HOME/work/$WORK_ENV/functions.sh \
    $XDG_CONFIG_HOME/work/$WORK_ENV/bigo.sh \
    $XDG_CONFIG_HOME/work/$WORK_ENV/bigo-completion.sh
fi
