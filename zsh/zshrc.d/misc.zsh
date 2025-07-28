autoload -Uz allopt zed zmv zcalc colors
colors
alias C="zcalc -f -e"
export LESSOPEN="|$XDG_CONFIG_HOME/.lessfilter %s"

# [ -f $XDG_CACHE_HOME/lvim/lvim.shada ] && command -v lvim >/dev/null 2>&1 && export viminfo=$XDG_CACHE_HOME/lvim/lvim.shada
# [ -f $XDG_CACHE_HOME/nvim/lvim.shada ] && [ -z "$viminfo" ] && export viminfo=$XDG_CACHE_HOME/nvim/lvim.shada

# 定义原生 Neovim 的 shada 文件路径
NEOVIM_SHADA_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/nvim/shada/main.shada"

# 检查 Neovim 可执行文件及其 shada 文件是否存在
[ -f "$NEOVIM_SHADA_PATH" ] && command -v nvim >/dev/null 2>&1 && export viminfo="$NEOVIM_SHADA_PATH"
