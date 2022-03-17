set updatetime=300
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif
autocmd CursorHold * silent call CocActionAsync('highlight')

call coc#add_extension("coc-jedi")
call coc#add_extension("coc-snippets")
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
 
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
 
let g:coc_snippet_next = '<tab>'

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)


" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')

call coc#add_extension("coc-json")
autocmd FileType json syntax match Comment +\/\/.\+$+

call coc#add_extension("coc-html")
call coc#add_extension("coc-sh")
call coc#add_extension("coc-css")
call coc#add_extension("coc-git")
call coc#add_extension("coc-prettier")
call coc#add_extension("coc-translator")
nmap <Leader>t <Plug>(coc-translator-p)



command! -nargs=0 Prettier :CocCommand prettier.formatFile

"call coc#add_extension("coc-pairs")
call coc#add_extension("coc-lists")
call coc#add_extension("coc-calc")
call coc#add_extension("coc-sql")
call coc#add_extension("coc-markdownlint")
call coc#add_extension("coc-markdownlint")
call coc#add_extension("coc-yank")
" Add hi HighlightedyankRegion term=bold ctermbg=0 guibg=#13354A to your .vimrc after :colorscheme command.
call coc#add_extension("coc-word")
call coc#add_extension("coc-cmake")
call coc#add_extension("coc-highlight")
autocmd CursorHold * silent call CocActionAsync('highlight')
" call coc#add_extension("coc-sh")
call coc#add_extension("coc-ultisnips")
call coc#add_extension("coc-lines")
Plug 'skywind3000/asynctasks.vim'
Plug 'skywind3000/asyncrun.vim'
let g:asyncrun_open = 6
call coc#add_extension("coc-tasks")
call coc#add_extension("coc-terminal")
" <Plug>(coc-terminal-toggle)
call coc#add_extension("coc-smartf")
call coc#add_extension("coc-clangd")
if !executable("clangd")
    call coc#rpc#notify('runCommand', ["clangd.install"])
endif

nmap f <Plug>(coc-smartf-forward)
nmap F <Plug>(coc-smartf-backward)
nmap ; <Plug>(coc-smartf-repeat)
nmap , <Plug>(coc-smartf-repeat-opposite)
 
augroup Smartf
  autocmd User SmartfEnter :hi Conceal ctermfg=220 guifg=#6638F0
  autocmd User SmartfLeave :hi Conceal ctermfg=239 guifg=#504945
augroup end

