export ZPLUG_HOME=$ZDOTDIR/zplug

# Check if zplug is installed
if [[ ! -d $ZPLUG_HOME ]]; then
  git clone https://github.com/zplug/zplug $ZPLUG_HOME
  source $ZPLUG_HOME/init.zsh 
fi


source $ZPLUG_HOME/init.zsh
# fix zplug bug
export ZSH="$ZPLUG_REPOS/$_ZPLUG_OHMYZSH"


# Grab binaries from GitHub Releases
# and rename with the "rename-to:" tag
if [[ $OSTYPE =~ linux ]]
then
	use_pattern="*linux*amd64*"
else
	use_pattern="*darwin*amd64*"
fi
zplug "junegunn/fzf-bin", \
  from:gh-r, \
  as:command, \
  rename-to:fzf, \
	use:$use_pattern


if [[ $OSTYPE =~ linux ]]
then
	use_pattern="*x86*linux*musl*"
else
	use_pattern="*darwin*"
fi
zplug "sharkdp/fd", \
  from:gh-r, \
  as:command, \
  use:"$use_pattern", \
	hook-build:"cp $ZPLUG_REPOS/sharkdp/fd/**/fd.1 $ZPLUG_HOME/doc/man/man1"


if [[ $OSTYPE =~ linux ]]
then
	use_pattern="*x86*linux*musl*"
else
	use_pattern="*darwin*"
fi
zplug "BurntSushi/ripgrep", \
  from:gh-r, \
  as:command, \
  rename-to:rg, \
  at:'0.10.0' \
  use:"$use_pattern", \
  hook-build:"cp $ZPLUG_REPOS/BurntSushi/ripgrep/**/rg.1 $ZPLUG_HOME/doc/man/man1", \
  hook-load:"source $ZDOTDIR/zshrc.d/rg"

zplug "junegunn/fzf", \
	as:command, use:"bin/*", \
	hook-load: "source $ZDOTDIR/zshrc.d/fzf"

# zplug "changyuheng/fz", defer:1
export _Z_DATA=$ZSH_CACHE_DIR/.z
zplug "rupa/z", use:z.sh, hook-build:"cp  $ZPLUG_REPOS/rupa/z/**/z.1 $ZPLUG_HOME/doc/man/man1"
zplug "rupa/v", as:command, \
  hook-build:"cp $ZPLUG_REPOS/rupa/v/**/v.1 $ZPLUG_HOME/doc/man/man1"
zplug "thetic/extract"
zplug "denisidoro/navi", \
  hook-build:"$ZPLUG_REPOS/denisidoro/navi/scripts/install $ZPLUG_BIN", \
  hook-load: "export NAVI_PATH=$ZPLUG_REPOS/denisidoro/navi/cheats:$CONF_DIR/cheat"

zplug "shannonmoeller/up", use:"*.sh"
# zplug "changyuheng/zsh-interactive-cd", defer:1

export ENHANCD_DIR=$ZSH_CACHE_DIR/enhancd
export ENHANCD_DISABLE_DOT=1
export ENHANCD_DISABLE_HOME=1
zplug "b4b4r07/enhancd", use:init.sh
# zplug "gsamokovarov/jump", use:init.sh


zplug "zsh-users/zsh-autosuggestions", \
  hook-load:"
bindkey -M emacs '^[^m' autosuggest-execute;
bindkey -M emacs '^[^j' autosuggest-execute;
"
# Additional completion definitions for Zsh
zplug "zsh-users/zsh-completions"

# zsh plugin to change directory to git repository root directory
# Usage:
# 	cd-gitroot [PATH]
zplug "mollifier/cd-gitroot", hook-load: "alias cdu='cd-gitroot'"

# A simple zsh function to make management of zsh named directories easier.
# Usage:
# 	cdbk {-a,-r,-d,-l} <name> [path] 
zplug "MikeDacre/cdbk"

# Syntax highlighting bundle. zsh-syntax-highlighting must be loaded after
# excuting compinit command and sourcing other plugins.
# zplug "zsh-users/zsh-syntax-highlighting", defer:2, hook-load: "source $ZDOTDIR/zshrc.d/hilight"
zplug "zdharma/fast-syntax-highlighting"
zplug "zsh-users/zsh-history-substring-search", defer:3, \
  hook-load:"bindkey -M emacs '^P' history-substring-search-up;  
             bindkey -M emacs '^N' history-substring-search-down;"

zplug "folixg/kinda-fishy-theme", as:theme, defer:3, hook-load:"source $ZDOTDIR/zshrc.d/theme.sh"


#zplug "themes/fishy", from:oh-my-zsh, as:theme
zplug "plugins/fancy-ctrl-z", from:oh-my-zsh
zplug "plugins/colored-man-pages", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh
zplug "plugins/docker-compose", from:oh-my-zsh
## bindkey '^[[1;4D' insert-cycledleft
## bindkey '^[[1;4C' insert-cycledright
zplug "plugins/dircycle", from:oh-my-zsh
## TODO
#zplug "plugins/fasd", from:oh-my-zsh
## TODO
zplug "plugins/git", from:oh-my-zsh
#zplug "plugins/git-extras", from:oh-my-zsh
## TODO
zplug "plugins/iterm2", from:oh-my-zsh
zplug "plugins/pip", from:oh-my-zsh
#zplug "plugins/thefuck", from:oh-my-zsh
## TODO
# zplug "plugins/tmux", from:oh-my-zsh

##zplug "lib/functions", from:oh-my-zsh
export CASE_SENSITIVE=false
export HYPHEN_INSENSITIVE=true
zplug "lib/completion", from:oh-my-zsh
zplug "lib/key-bindings", from:oh-my-zsh
##zplug "lib/grep", from:oh-my-zsh
##zplug "lib/misc", from:oh-my-zsh
HIST_STAMPS="yyy-mm-dd"
zplug "lib/history", from:oh-my-zsh


FORGIT_FZF_DEFAULT_OPTS="
--exact
--border
--cycle
--reverse
--height '80%'
"
forgit_add=gaa
zplug 'wfxr/forgit', defer:1

zplug "so-fancy/diff-so-fancy", as:command

zplug "LuRsT/hr", as:command, hook-build:"cp $ZPLUG_REPOS/LuRsT/hr/hr.1 $ZPLUG_HOME/doc/man/man1"

zplug "Aloxaf/fzf-tab", defer:3

if ! zplug check; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  else
    echo
  fi
fi

zplug load # --verbose
alias z="nocorrect _z 2>&1"
