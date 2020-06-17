if empty($XDG_CONFIG_HOME)| let $XDG_CONFIG_HOME = $HOME . '/.config'| endif
if empty($XDG_CACHE_HOME)| let $XDG_CACHE_HOME = $HOME . '/.cache'| endif
if empty($XDG_DATA_HOME)| let $XDG_DATA_HOME = $HOME . '/.local/share'| endif

let g:confdir = $XDG_CONFIG_HOME . '/vim'
let g:cachedir = $XDG_CACHE_HOME . '/vim'
let g:datadir = $XDG_DATA_HOME . '/vim'

let s:undodir = g:cachedir . '/undo'
if !isdirectory(s:undodir)| call mkdir(s:undodir, "p", 0700)| endif
let &undodir = s:undodir

let s:swapdir = g:cachedir . '/swap'
if !isdirectory(s:swapdir)| call mkdir(s:swapdir, "p", 0700)| endif
let &directory = s:swapdir

let s:backupdir = g:cachedir . '/backup'
if !isdirectory(s:backupdir)| call mkdir(s:backupdir, "p", 0700)| endif
let &directory = s:backupdir

let &viminfo .= ',n' . $XDG_CACHE_HOME . '/vim/viminfo'
let &runtimepath = $XDG_CONFIG_HOME . '/vim,' . $XDG_CONFIG_HOME . '/vim/after,'.$VIM.','.$VIMRUNTIME
let $MYVIMRC = $XDG_CONFIG_HOME . '/vim/vimrc'
