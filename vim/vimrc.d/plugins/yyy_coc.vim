set updatetime=300
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


let g:coc_config_home = g:config.path.config
let g:coc_data_home = g:config.path.data . '/coc'

call coc#add_extension("coc-python")
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

call coc#add_extension("coc-json")
autocmd FileType json syntax match Comment +\/\/.\+$+

call coc#add_extension("coc-html")
call coc#add_extension("coc-css")
call coc#add_extension("coc-git")
call coc#add_extension("coc-prettier")
command! -nargs=0 Prettier :CocCommand prettier.formatFile

"call coc#add_extension("coc-pairs")
call coc#add_extension("coc-lists")
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
nmap f <Plug>(coc-smartf-forward)
nmap F <Plug>(coc-smartf-backward)
nmap ; <Plug>(coc-smartf-repeat)
nmap , <Plug>(coc-smartf-repeat-opposite)
 
augroup Smartf
  autocmd User SmartfEnter :hi Conceal ctermfg=220 guifg=#6638F0
  autocmd User SmartfLeave :hi Conceal ctermfg=239 guifg=#504945
augroup end

