autoload -Uz allopt zed zmv zcalc colors
colors
alias C="zcalc -f -e"

[ -f $XDG_CACHE_HOME/lvim/lvim.shada ] && command -v lvim >/dev/null 2>&1 && export viminfo=$XDG_CACHE_HOME/lvim/lvim.shada
[ -f $XDG_CACHE_HOME/nvim/lvim.shada ] && [ -z "$viminfo" ] && export viminfo=$XDG_CACHE_HOME/nvim/lvim.shada
