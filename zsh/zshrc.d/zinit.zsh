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
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} \
    Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  command mkdir -p "$ZINIT[HOME_DIR]" && command chmod g-rwX "$ZINIT[HOME_DIR]"
  command git clone https://github.com/zdharma-continuum/zinit "$ZINIT[BIN_DIR]" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source $ZINIT[BIN_DIR]/zinit.zsh

zt(){ zinit depth'3' light-mode lucid "${@}"; }
#### plugins
## light is parallel & load is sequential.
#load=load
#[[ $load == light ]] && lightmode=light-mode || lightmode=


zt for \
  romkatv/powerlevel10k \
  atload"source ${ZDOTDIR:-$HOME}/.p10k.zsh" \
  zdharma-continuum/null


zt for \
  zdharma-continuum/z-a-patch-dl \
  zdharma-continuum/z-a-submods \
  NICHOLAS85/z-a-linkman \
  NICHOLAS85/z-a-linkbin \
  atinit'Z_A_USECOMP=1' \
  NICHOLAS85/z-a-eval

# use zinit recache to reeval
zt wait for \
  eval'dircolors -b LS_COLORS' \
  atload'zstyle ":completion:*" list-colors ${(s.:.)LS_COLORS}' \
  commiyou/LS_COLORS

zt wait for \
  trigger-load'!zhooks' \
  agkozak/zhooks \
  trigger-load'!gencomp' blockf \
  atload"!export GENCOMP_DIR=${ZDOTDIR:-$HOME}/completions/" Aloxaf/gencomp \
  blockf compile'lib/*f*~*.zwc' \
  pick'autoenv.zsh' nocompletions \
  Tarrasch/zsh-autoenv 

zinit ice wait="0" lucid from="gh-r" as="program" pick="zoxide-*/zoxide -> zoxide" cp="zoxide-*/completions/_zoxide -> _zoxide" atclone="./zoxide init zsh > init.zsh" atpull="%atclone" src="init.zsh"
zinit light ajeetdsouza/zoxide

zt wait for \
  OMZP::fancy-ctrl-z \
  OMZP::colored-man-pages \
  OMZP::command-not-found \
  OMZP::gnu-utils \
  OMZP::iterm2 \
  OMZP::rsync \
  OMZP::systemadmin \
  OMZP::urltools \
  trigger-load'!pp_json;!is_json;!urlencode_json;!urldecode_json;!pp_ndjson;!is_ndjson;' \
  OMZP::jsontools \
  trigger-load'!x;!extract;' \
  OMZP::extract \
  trigger-load"!fuck" OMZP::thefuck \
  OMZL::clipboard.zsh \
  OMZL::completion.zsh \
  OMZL::functions.zsh \
  OMZL::grep.zsh \
  has'tmux' atload$'!ZSH_TMUX_FIXTERM=false; \
    ZSH_TMUX_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf; \
    compdef _zsh_tmux_plugin_run=tmux; ' \
  OMZP::tmux 

#if'[[ -z "$commands[tig]" ]]' @jonas/tig \
zt wait binary from"gh-r" lman lbin for \
  if'[[ -z "$commands[exa]" ]]' @ogham/exa \
  if'[[ -z "$commands[fd]" ]]' @sharkdp/fd  \
  if'[[ -z "$commands[gron]" ]]' @tomnomnom/gron  \
  if'[[ -z "$commands[jless]" ]]' PaulJuliusMartinez/jless \
  if'[[ -z "$commands[bat]" ]]' @sharkdp/bat  \
  if'[[ -z "$commands[mdcat]" ]]' @swsnr/mdcat \
  if'[[ -z "$commands[xsv]" ]]' BurntSushi/xsv \
  if'[[ -z "$commands[sad]" ]]' ms-jpq/sad



zt wait binary from"gh-r" for \
  lman lbin"**/rg -> rg" \
  if'[[ -z "$commands[rg]" ]]' @BurntSushi/ripgrep \
  dl'https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf.1' \
  id-as'fzf-bin' lman lbin \
  if'[[ -z "$commands[fzf]" ]]' junegunn/fzf \
  id-as'cheat-bin' lman lbin"**/cheat* -> cheat" \
  cheat/cheat 


# # Always starting with insert mode for each command line
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode
#
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT


zinit ice as"program" pick"$ZPFX/bin/git-*" src"etc/git-extras-completion.zsh" make"PREFIX=$ZPFX"
zinit light tj/git-extras
#
#zinit ice if'[[ -n "$commands[rg]" ]]' binary from"gh-r" lman lbin"**/rg -> rg" 
#zinit load @BurntSushi/ripgrep
#
#zinit ice if'[[ -n "$commands[cheat]" ]]' binary id-as'cheat-bin' lman lbin"**/cheat* -> cheat"
#zinit load cheat/cheat
#

export AUTOSWITCH_DEFAULT_CONDAENV="base"
zt wait for \
  atinit"local zew_word_style=whitespace" \
  zdharma-continuum/zsh-editing-workbench \
  multisrc'shell/*.zsh' \
  trackbinds bindmap='^T -> ^X^T; \ec -> ^X^C' \
  junegunn/fzf  \
  bckim92/zsh-autoswitch-conda

# zt wait for \
#   atload'!export CHEAT_USE_FZF=true' pick'scripts/cheat.zsh' \
#   cheat/cheat \
#   id-as'cheat.sh' \
#   binary \
#   nocompile \
#   dl'https://cht.sh/:cht.sh -> cht.sh' \
#   atinit'chmod +x cht.sh' lbin'cht.sh' \
#   zdharma-continuum/null

# zt wait has'lua' for \
#   atload'!export _ZL_DATA=$XDG_CACHE_HOME/.zlua;' \
#   skywind3000/z.lua \
#   atload'!function _z() { _zlua "$@"; }; alias z="nocorrect _fz"' \
#   commiyou/fz.sh

#zplugin ice wait'1' lucid
#zplugin light laggardkernel/zsh-thefuck

#as"program" pick'bin/fzf-tmux' src'shell/key-bindings.zsh'  trackbinds bindmap='^T -> ^X^T; \ec -> ^X\ec' commiyou/fzf \
# $'string'  quote https://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings/16605140#16605140
#ptavares/zsh-direnv \

__forgit_atload() {
    export FORGIT_INSTALL_DIR="$PWD"
    export FORGIT_NO_ALIASES=1
    export FORGIT_LOG_FZF_OPTS='--bind="ctrl-e:execute(echo {} |grep -Eo [a-f0-9]+ |head -1 |xargs command git show |vim -)"'
    alias gdca="forgit::diff --cached"
    alias gds="forgit::diff --cached"
    alias glog="forgit::log --oneline --decorate --graph"
}
#__forgit_atload

zt wait for \
  hlissner/zsh-autopair \
  Tarrasch/zsh-functional \
  Tarrasch/zsh-colors \
  atload'ZSH_COMMAND_TIME_EXCLUDE=(vim v); ZSH_COMMAND_TIME_COLOR=red' \
  popstas/zsh-command-time \
  atpull$'git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"; \
    git config --global interactive.diffFilter "diff-so-fancy --patch";' \
  z-shell/zsh-diff-so-fancy \
  atload$'!__forgit_atload;compdef _git gco=git-checkout;' wfxr/forgit \
  as"program" atload'export SSHHOME=$XDG_CONFIG_HOME' pick'sshrc' IngoMeyer441/sshrc \
  atinit"local zew_word_style=whitespace" \
  zdharma-continuum/zsh-editing-workbench 


#zt wait'1' for \
#  trigger-load'!conda;!ipython;!pip;!python;' commiyou/conda-init-zsh-plugin \
#  blockf as'completion' \
#  conda-incubator/conda-zsh-completion


# completions
#zt wait blockf as"completion" for \
#  svn OMZP::fd \
#  svn OMZP::docker \
#  svn OMZP::ripgrep

zt wait'[[ -n $WORK_ENV ]]' id-as for \
  $XDG_CONFIG_HOME/work/$WORK_ENV

zt wait for \
  blockf as'completion' atpull'zinit creinstall -q .' id-as'commiyou-completions'\
  $XDG_CONFIG_HOME/zsh/completions

#zinit ice $lightmode wait lucid pick'roszsh' id-as'roszsh'
#zinit snippet https://raw.githubusercontent.com/ros/ros/melodic-devel/tools/rosbash/roszsh

#FZF_TMUX_HEIGHT=100%
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:*' single-group prefix color header
zinit id-as depth'1' wait lucid \
  if'(($+commands[fzf]))' \
  for Freed-Wu/fzf-tab-source

  #atload"!zstyle ':fzf-tab:complete:(cd|z|ls|vim|rm|rmr):*' \
  #fzf-preview 'exa -1 --color=always \$realpath';" \
# fzf-tab must before Fast-syntax-highlighting & autosuggestions
# and bellow LS_COLORS
zt wait'0b' for \
  atinit"zicompinit; zicdreplay;" \
  Aloxaf/fzf-tab \
  zdharma-continuum/fast-syntax-highlighting \
  blockf atpull'zinit creinstall -q .' zsh-users/zsh-completions \
  atload"!_zsh_autosuggest_start" zsh-users/zsh-autosuggestions 

zupdate() { [[ $# -eq 0 ]] && zinit update --all --parallel || zinit update --parallel 15 "$@" }
zt wait'0c' for atload'compdef _zinit zi; compdef _zinit_update zupate;' zdharma-continuum/null
