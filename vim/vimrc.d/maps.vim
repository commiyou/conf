nnoremap <leader>u :e ++enc=utf8<CR>
nnoremap <leader>g :e ++enc=gbk<CR>
nnoremap <c-g> 1<c-g>

"inoremap <c-]> <Esc>
"inoremap <c-b> <left>
"inoremap <c-f> <right>
nnoremap <c-b> <left>
nnoremap <c-f> <right>


" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
nnoremap <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Remap VIM 0 to first non-blank character
nnoremap 0 ^

" qf
nnoremap <leader>qf :botright cope<cr>

" Toggle paste mode on and off
nnoremap <leader>pp :setlocal paste!<cr>
" Format Jump, go to last changes
nnoremap <silent> g; g;zz
nnoremap <silent> g, g,zz

" Split fast
nnoremap <leader>\ :vs<CR>
nnoremap <leader>\| :vs<CR>
nnoremap <leader>- :sp<CR>
nnoremap <c-w><c-f> :vsplit <cfile><cr>
" Quickly open/reload vim
nnoremap <leader>sv :source $vimdir/vimrc<CR>
nnoremap <leader>ev :Files $vimdir<CR>
autocmd BufWritePost $vimdir/vimrc source %
autocmd BufWritePost $vimdir/vimrc.d/*.vim source %

cno $c e <C-\>eCurrentFileDir("tabe")<cr>
cno $q <C-\>eDeleteTillSlash()<cr>
func! DeleteTillSlash()
    let g:cmd = getcmdline()

    if has("win16") || has("win32")
        let g:cmd_edited = substitute(g:cmd, "\\(.*\[\\\\]\\).*", "\\1", "")
    else
        let g:cmd_edited = substitute(g:cmd, "\\(.*\[/\]\\).*", "\\1", "")
    endif

	    if g:cmd == g:cmd_edited
        if has("win16") || has("win32")
            let g:cmd_edited = substitute(g:cmd, "\\(.*\[\\\\\]\\).*\[\\\\\]", "\\1", "")
        else
            let g:cmd_edited = substitute(g:cmd, "\\(.*\[/\]\\).*/", "\\1", "")
        endif
    endif

    return g:cmd_edited
endfunc

func! CurrentFileDir(cmd)
    return a:cmd . " " . expand("%:p:h") . "/"
endfunc

" Bash like keys for the command line
cnoremap <C-A>      <Home>
cnoremap <C-E>      <End>
cnoremap <C-B>      <Left>
cnoremap <C-F>      <Right>
cnoremap <C-P> <Up>
cnoremap <C-N> <Down>
cnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
cnoremap <silent> <C-j> :TmuxNavigateDown<cr>
cnoremap <silent> <C-k> :TmuxNavigateUp<cr>
cnoremap <silent> <C-l> :TmuxNavigateRight<cr>

nnoremap <leader>l :nohlsearch<cr>:diffupdate<cr>:syntax sync fromstart<cr><c-l>

nnoremap <leader>ts :ts <C-R>=expand("<cword>")<CR><CR>
nnoremap <leader>] :ts <C-R>=expand("<cword>")<CR><CR>
" preview tags
nnoremap <C-]> <Esc>:exe "ptjump " . expand("<cword>")<Esc>
nnoremap gf <C-W>gF

" n to always search forward and N backward,
nnoremap <expr> n  'Nn'[v:searchforward]
nnoremap <expr> N  'nN'[v:searchforward]

" Zoom / Restore window.
function! s:ZoomToggle() abort
    if exists('t:zoomed') && t:zoomed
        execute t:zoom_winrestcmd
        let t:zoomed = 0
    else
        let t:zoom_winrestcmd = winrestcmd()
        resize
        vertical resize
        let t:zoomed = 1
    endif
endfunction
command! ZoomToggle call s:ZoomToggle()
nnoremap <leader>z :ZoomToggle<CR>
nnoremap <c-w>z :ZoomToggle<CR>

" {{{ Plug 'vim-scripts/a.vim' fix unmap
	silent! iu <Leader>ih
	silent! nun <Leader>ih 
	silent! iu <Leader>is 
	silent! nun <Leader>is
	silent! iu <Leader>ihn 
	silent! nun <Leader>ihn 
" }}}
