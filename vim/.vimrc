" what is the name of the directory containing this file?
"
let g:vimrc = resolve(expand('<sfile>:p'))
let g:vimdir = fnamemodify(g:vimrc, ':h')
"let g:cachedir = g:vimdir . '/.cache'
"let $vimdir= g:vimdir
"let $cachedir = g:cachedir

" set default 'runtimepath' (without ~/.vim folders)
" let &runtimepath = printf('%s,%s', g:vimdir, $VIMRUNTIME)

for f in split(glob(g:vimdir . "/vimrc.d/*.vim"), '\n')
    exe 'source' f
endfor

