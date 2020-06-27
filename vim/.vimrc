" what is the name of the directory containing this file?
"
set nocompatible
if !empty($XDG_CONFIG_HOME) && isdirectory($XDG_CONFIG_HOME.'/vim')
    for f in split(glob($XDG_CONFIG_HOME."/vim/vimrc.d/*.vim"), '[\r\n]')
        exe 'source' f
    endfor
else
    let g:vimrc = resolve(expand('<sfile>:p'))
    let g:vimdir = fnamemodify(g:vimrc, ':h')
endif
