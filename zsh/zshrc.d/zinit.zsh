SHELL=zsh

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

typeset -g ABSD=${${(M)OSTYPE:#*(darwin|bsd)*}:+1}

(( ABSD )) && {
  BPICK='*(darwin|apple|mac)*'
} || {
  BPICK='*(linux|musl)*'
}



autoload -Uz allopt zed zmv zcalc colors
colors

#### plugins
load=light

zinit light-mode for \
  zinit-zsh/z-a-submods \
  zinit-zsh/z-a-bin-gem-node \

zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
  atpull'%atclone' pick"clrs.zsh" nocompile'!' \
  atload'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' \
  zinit light-mode trapd00r/LS_COLORS

  #OMZP::sudo \
zinit light-mode wait"2" lucid for \
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

# zsh-autopair
# fzf-marks, at slot 0, for quick Ctrl-G accessibility
zinit light-mode wait lucid for \
  hlissner/zsh-autopair \
  urbainvaes/fzf-marks \
  wfxr/forgit \
  sbin'bin/fzf-tmux' src'shell/key-bindings.zsh'  bindmap='^T -> ^X^T; \ec -> ^X\ec' commiyou/fzf \
  atload'ZSH_TMUX_FIXTERM=false ZSH_TMUX_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf'  svn OMZP::tmux

zinit light-mode wait"1" lucid for \
  atinit"local zew_word_style=whitespace" \
  psprint/zsh-editing-workbench

zinit light-mode wait"2" lucid as"null" from"gh-r" for \
  mv"exa* -> exa" sbin ogham/exa \
  mv"fd* -> fd" sbin"fd/fd" bpick"$BPICK" @sharkdp/fd \
  mv"ripgrep* -> rg" sbin"rg/rg" bpick"$BPICK"  BurntSushi/ripgrep \
  sbin"fzf" bpick"$BPICK" junegunn/fzf-bin 

zinit light-mode wait"2" lucid for \
  atload'export _ZL_DATA=$XDG_CACHE_HOME/.zlua; alias zh="z -I -t ."; alias zb="z -b" ' skywind3000/z.lua \
  atload'function _z() { _zlua "$@"; }' changyuheng/fz
# light-mode within zshrc – for the instant prompt
zinit ice atload"!source ${ZDOTDIR:-$HOME}/.p10k.zsh" lucid nocd
zinit light romkatv/powerlevel10k

# completions
zinit wait lucid blockf for \
  zsh-users/zsh-completions \
  as"completion" svn OMZP::fd \
  as"completion" svn OMZP::docker \
  as"completion" svn OMZP::ripgrep \


zpcompinit; zpcdreplay

# (experimental, may change in the future)
# some boilerplate code to define the variable `extract` which will be used later
# please remember to copy them
local extract="
# trim input(what you select)
local in=\${\${\"\$(<{f})\"%\$'\0'*}#*\$'\0'}
# get ctxt for current completion(some thing before or after the current word)
local -A ctxt=(\"\${(@ps:\2:)CTXT}\")
# real path
local realpath=\${ctxt[IPREFIX]}\${ctxt[hpre]}\$in
realpath=\${(Qe)~realpath}
"

# give a preview of commandline arguments when completing `kill`
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
zstyle ':fzf-tab:complete:kill:argument-rest' extra-opts --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap

# give a preview of directory by exa when completing cd
zstyle ':fzf-tab:complete:cd:*' extra-opts --preview=$extract'exa -1 --color=always $realpath'
zstyle ':fzf-tab:*'    extra-opts '--no-sort'
zstyle ':completion:*' sort       'false'

# Fast-syntax-highlighting & autosuggestions
zinit light-mode wait lucid for \
  Aloxaf/fzf-tab \
  zdharma/fast-syntax-highlighting \
  atload"!_zsh_autosuggest_start" \
  zsh-users/zsh-autosuggestions 

