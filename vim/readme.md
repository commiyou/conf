# quickstart
```
cd ~
git clone https://github.com/commiyou/conf --branch new
cp ~/.vimrc ~/.vimrc.bak
ln -s ~/conf/vim/.vimrc

# install ripgrep
# https://github.com/BurntSushi/ripgrep#installation

```
打开vim，就会自动下载插件到`$XDG_DATA_HOME/vim` 或者 `~/.local/share` 下, 或者使用`:PlugInstall`


# 快捷键 
`mapleader`为`space`

##  normal mode
- `<leader>m` recently opened files
- `<leader>b` buffers/opened files
- `<leader>ff` search file by `fzf` under current dir: `<enter>` open, `<ctrl>x` split, `<ctrl>v` vsplit, `<ctrl>t` tabe, `<ctrl>c` break
- `<leader>rr` search current word by `rg` in files under current dir: `<enter>` open, `<ctrl>x` split, `<ctrl>v` vsplit, `<ctrl>t` tabe, `<ctrl>c` break; ~目前有点问题，需要改动下搜索词才能触发rg的搜索~
- `<leader>m` highlight current word: `<enter>` open, `<ctrl>x` split, `<ctrl>v` vsplit, `<ctrl>t` tabe, `<ctrl>c` break
- `<leader>tt` open/close explorer
- `<ctrl>wz` maximize current window/zoom mode
- `<ctrl>wq` close current window
- `<ctrl>h/l/j/k` jump to left/right/downside/upside window
- `<ctrl>]` open function defination in top window from ctags
- `<ctrl>i` go to newer cursor position in jump list
- `<ctrl>o` go to older cursor position in jump list
- `ci<char>` delete words in `<char>` and start insert
- `ma` make marker `a`
- `'a` jump to makrer `a`
- `"+y` copy into systerm clipboard (ubuntu with vim-gtk installed)

## cmdline mode
可用使用`<tab>`补全
- `:help help` help
- `:cd ..` set current dir to ..
- `:sp`  split tab, 
- `:vsp`  split tab vertically
- `:tabe` edit in new tab
- `:e <path>` edit file
- `:e` roload current file
- `:r <path>` read in to current file
- `:help :Git` git tools, `:Git blame` 
- `:Git`git tools, `:Git blame` 
- `:Maps` see all mapping
- `:Rg [PATTERN]` search word by `rg`
- `:FZF` search file by `fzf`, 
- `:help fzf-vim-commands` more useful commands
