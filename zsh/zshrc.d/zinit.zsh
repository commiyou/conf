# vim: filetype=zsh
[ -n "$USE_ZPLUG" ] && return

# ─── §1 Bootstrap ─────────────────────────────────────────────────────────────

typeset -A ZINIT=(
  BIN_DIR         ${XDG_DATA_HOME:-$HOME/.local/share}/zinit/bin
  HOME_DIR        ${XDG_DATA_HOME:-$HOME/.local/share}/zinit
  ZCOMPDUMP_PATH  ${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-${(%):-%n}
  COMPINIT_OPTS   -C
)
hash -d zinit=$ZINIT[HOME_DIR]

if [[ ! -f $ZINIT[BIN_DIR]/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing zinit…%f"
  command mkdir -p "$ZINIT[HOME_DIR]" && command chmod g-rwX "$ZINIT[HOME_DIR]"
  command git clone https://github.com/zdharma-continuum/zinit "$ZINIT[BIN_DIR]" && \
    print -P "%F{34}▓▒░ Installation successful.%f" || \
    print -P "%F{160}▓▒░ Clone failed.%f"
fi

source $ZINIT[BIN_DIR]/zinit.zsh

# zt: shorthand for deferred parallel light loads; pass 'wait' to defer
zt(){ zinit depth'3' light-mode lucid "${@}"; }

# Annexes must be first — they extend zinit's ice syntax for everything below
zt for \
  zdharma-continuum/z-a-patch-dl \
  zdharma-continuum/z-a-submods \
  NICHOLAS85/z-a-linkman \
  NICHOLAS85/z-a-linkbin \
  atinit'Z_A_USECOMP=1' NICHOLAS85/z-a-eval


# ─── §2 Theme ─────────────────────────────────────────────────────────────────
# Synchronous: p10k instant-prompt demands the theme load before first prompt

zt for \
  atload"[[ -f ${ZDOTDIR:-$HOME}/.p10k.zsh ]] && source ${ZDOTDIR:-$HOME}/.p10k.zsh" \
  romkatv/powerlevel10k


# ─── §3 Immediate plugins ─────────────────────────────────────────────────────
# zsh-vi-mode: ZVM config vars must be exported before zinit sources the plugin

ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
zinit depth'1' light-mode lucid for jeffreytse/zsh-vi-mode


# ─── §4 Deferred: environment ─────────────────────────────────────────────────
# zicompinit runs first so subsequent atload hooks can call compdef

zt wait for \
  atinit'zicompinit' zdharma-continuum/null \
  eval'dircolors -b LS_COLORS' \
  atload'zstyle ":completion:*" list-colors ${(s.:.)LS_COLORS}' \
  commiyou/LS_COLORS \
  trigger-load'!zhooks' agkozak/zhooks \
  trigger-load'!gencomp' blockf \
    atload'export GENCOMP_DIR=${ZDOTDIR:-$HOME}/completions/' Aloxaf/gencomp \
  blockf compile'lib/*f*~*.zwc' pick'autoenv.zsh' nocompletions \
    Tarrasch/zsh-autoenv

# zoxide: uses custom pick/cp/atclone so written out explicitly
zinit wait lucid light-mode for \
  from'gh-r' as'program' \
  pick'zoxide-*/zoxide -> zoxide' \
  cp'zoxide-*/completions/_zoxide -> _zoxide' \
  atclone'./zoxide init zsh > init.zsh' atpull'%atclone' src'init.zsh' \
  ajeetdsouza/zoxide


# ─── §5 Deferred: OMZ plugins ─────────────────────────────────────────────────

zt wait for \
  OMZP::fancy-ctrl-z \
  OMZP::colored-man-pages \
  OMZP::command-not-found \
  OMZP::gnu-utils \
  OMZP::iterm2 \
  OMZP::rsync \
  OMZP::systemadmin \
  OMZP::urltools \
  trigger-load'!pp_json;!is_json;!urlencode_json;!urldecode_json;!pp_ndjson;!is_ndjson' \
    OMZP::jsontools \
  trigger-load'!x;!extract' OMZP::extract \
  trigger-load'!fuck' OMZP::thefuck \
  OMZL::clipboard.zsh \
  OMZL::completion.zsh \
  OMZL::functions.zsh \
  OMZL::grep.zsh \
  has'tmux' atload'ZSH_TMUX_FIXTERM=false; \
    ZSH_TMUX_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf; \
    compdef _zsh_tmux_plugin_run=tmux' \
    OMZP::tmux


# ─── §6 Deferred: binary tools (gh-r) ────────────────────────────────────────
# Install only when the command is absent; lbin/lman wire up links automatically

zt wait binary from'gh-r' lman lbin for \
  if'[[ -z $commands[exa]   ]]' @ogham/exa \
  if'[[ -z $commands[fd]    ]]' @sharkdp/fd \
  if'[[ -z $commands[bat]   ]]' @sharkdp/bat \
  if'[[ -z $commands[gron]  ]]' @tomnomnom/gron \
  if'[[ -z $commands[jless] ]]' PaulJuliusMartinez/jless \
  if'[[ -z $commands[mdcat] ]]' @swsnr/mdcat \
  if'[[ -z $commands[xsv]   ]]' BurntSushi/xsv \
  if'[[ -z $commands[sad]   ]]' ms-jpq/sad \
  id-as'fx-bin'   lbin'fx* -> fx'                if'[[ -z $commands[fx]  ]]' antonmedv/fx \
  id-as'tmux-bin' lbin'tmux* -> tmux' ver'v3.3a' mjakob-gh/build-static-tmux

zt wait binary from'gh-r' lman for \
  lbin'**/rg -> rg'   if'[[ -z $commands[rg]  ]]' @BurntSushi/ripgrep \
  id-as'fzf-bin' lbin if'[[ -z $commands[fzf] ]]' \
    dl'https://raw.githubusercontent.com/junegunn/fzf/master/man/man1/fzf.1' \
    junegunn/fzf \
  id-as'cheat-bin' lbin'**/cheat* -> cheat' cheat/cheat

zt wait binary from'gh-r' as'program' for \
  id-as'navi' pick'navi' denisidoro/navi

# git-extras: make build; deferred fine since git-* are non-core commands
zt wait for \
  as'program' pick"$ZPFX/bin/git-*" src'etc/git-extras-completion.zsh' make"PREFIX=$ZPFX" \
  tj/git-extras


# ─── §7 Deferred: UX plugins ──────────────────────────────────────────────────

zt wait for \
  hlissner/zsh-autopair \
  Tarrasch/zsh-functional \
  Tarrasch/zsh-colors \
  reegnz/jq-zsh-plugin \
  atload'ZSH_COMMAND_TIME_EXCLUDE=(vim v); ZSH_COMMAND_TIME_COLOR=red' \
    popstas/zsh-command-time \
  atpull'git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"; \
    git config --global interactive.diffFilter "diff-so-fancy --patch"' \
    z-shell/zsh-diff-so-fancy \
  atload'export FORGIT_INSTALL_DIR=$PWD; \
    export FORGIT_NO_ALIASES=1; \
    export FORGIT_LOG_FZF_OPTS="--bind=ctrl-e:execute(echo {} |grep -Eo [a-f0-9]+ |head -1 |xargs command git show |vim -)"; \
    alias gdca="forgit::diff --cached"; alias gds="forgit::diff --cached"; \
    alias glog="forgit::log --oneline --decorate --graph"; \
    compdef _git gco=git-checkout' \
    wfxr/forgit

zt wait for \
  atinit'local zew_word_style=whitespace' zdharma-continuum/zsh-editing-workbench \
  multisrc'shell/*.zsh' trackbinds bindmap'^T -> ^X^T; \ec -> ^X^C' junegunn/fzf \
  atinit'export AUTOSWITCH_DEFAULT_CONDAENV=base' bckim92/zsh-autoswitch-conda

zt wait'[[ -n $WORK_ENV ]]' id-as'work-env' for \
  $XDG_CONFIG_HOME/work/$WORK_ENV


# ─── §8 Completions ───────────────────────────────────────────────────────────
# Ordering contract:
#   wait §4 (zicompinit first) → wait §5–§7 → wait'0b' (zicdreplay + fzf-tab → fsh → autosuggestions)
#   wait'1'      → zsh-more-completions (heavy; loads after first prompt)
#
# fzf-tab-source provides extra previews; must load before fzf-tab

zinit wait lucid light-mode depth'1' if'(($+commands[fzf]))' for \
  Freed-Wu/fzf-tab-source


# fzf-tab > fast-syntax-highlighting > autosuggestions: order is mandatory
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:*' single-group prefix color header

zt wait'0b' for \
  atinit'zicdreplay' Aloxaf/fzf-tab \
  zdharma-continuum/fast-syntax-highlighting \
  blockf atpull'zinit creinstall -q .' zsh-users/zsh-completions \
  atload'_zsh_autosuggest_start' zsh-users/zsh-autosuggestions

# Heavy completion database; load after first prompt to avoid blocking
zinit ice lucid compile'**/*.zsh' wait'1' nocompletions
zinit load MenkeTechnologies/zsh-more-completions


# ─── Utilities ────────────────────────────────────────────────────────────────

zupdate() { [[ $# -eq 0 ]] && zinit update --all --parallel || zinit update --parallel 15 "$@"; }
zt wait'0c' for atload'compdef _zinit zi; compdef _zinit_update zupdate' zdharma-continuum/null
