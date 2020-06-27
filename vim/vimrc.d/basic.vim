" let &viminfo .= ',n' . g:vimdir . '/.viminfo'
set modeline
set modelines=5

set history=2000 " history of previous command/search

let mapleader = " "
let g:mapleader = " "

set ruler " show cusor position
set hidden " buffer become hidden when it is abandoned

"if !isdirectory(g:cachedir . "/undodir")
"    call mkdir(g:cachedir . "/undodir", "p")
"endif
"let &undodir= g:cachedir . '/undodir'
set undofile

set encoding=utf8
set fileencodings=utf8,gbk
set number
set rnu  " relativenumber
set cul  " cursorline
set expandtab
set lcs=tab::\|\,trail:-\,eol:$   " listchars
set gdefault " the :substitute flag 'g' is default on
set noeol " no auto add <EOL>

filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" Set 7 lines to the cursor - when moving vertically using j/k
set so=7  " scrolloff
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc,*log,*.bak,*.swp,*.so,*.swp
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l
" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
" Enable syntax highlighting
syntax enable


set background=dark

set nobackup
set nowb
set noswapfile

set shiftwidth=4
set tabstop=4
set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines


" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif


set tags=./tags;,tags;
au FileType python syn keyword pythonDecorator True None False self
au FileType python let indent_guides_guide_size = 4
autocmd FileType python,sh,zsh,c,cpp setlocal expandtab
autocmd FileType sh,zsh setlocal shiftwidth=2
autocmd FileType sh,zsh setlocal tabstop=2
autocmd FileType python setlocal colorcolumn=120
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=0# indentkeys-=<:>
" autocmd CursorMoved *.cpp,*.py,*.sh,*.conf,*.proto exe printf('match CtrlParrow1 /\V\<%s\>/', escape(expand('<cword>'), '/\'))


function! IsDiff(opt)
    let isdiff = 0

    if v:progname =~ "diff"
        let isdiff = isdiff + 1
    endif

    if &diff == 1
        let isdiff = isdiff + 1
    endif

    if a:opt =~ "scrollopt"
        if &scrollopt =~ "hor"
            let isdiff = isdiff + 1
        endif
    endif

    return isdiff
endfunction
function! ShowTaglist()
    if line("$") > 200 && !IsDiff(expand('<amatch>'))
        " echom IsDiff(expand('<amatch>'))
        :call tagbar#autoopen(0)
    endif
endfunction
au FileType cpp,python call ShowTaglist()
augroup vimrc_todo
    au!
    au Syntax * syn match MyTodo /\v<(FIXME|NOTE|TODO|OPTIMIZE|XXX|COMMI)>/
          \ containedin=.*Comment,vimCommentTitle
    au Syntax * syn match MyTodo /\v<(FIXME|NOTE|TODO|OPTIMIZE|XXX|COMMI):/
          \ containedin=.*Comment,vimCommentTitle
augroup END
hi def link MyTodo Todo

set timeout           " for mappings
set timeoutlen=1000   " default value
set ttimeout          " for key codes
set ttimeoutlen=10    " unnoticeable small value

set formatoptions-=t  " no auto line break in text

" set dictionary+=$vimdir/dict/comm.dict
" set spell
