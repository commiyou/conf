set encoding=utf-8

call plug#begin(g:vimdir . "/plugged")

let hostname = system('hostname')
if 0
	set pyxversion=2
	Plug 'Valloric/YouCompleteMe', {'do': 'sh ' . g:vimdir . '/misc/ycm.sh'}

	let g:ycm_complete_in_comments = 1
	let g:ycm_collect_identifiers_from_comments_and_strings = 1
	let g:ycm_key_detailed_diagnostics = ''
	let g:ycm_filepath_completion_use_working_dir = 0
	let g:ycm_server_python_interpreter = $JUMBO_ROOT . '/bin/python'
	let g:ycm_add_preview_to_completeopt = 1
	let g:ycm_autoclose_preview_window_after_completion = 0
	let g:ycm_autoclose_preview_window_after_insertion = 1
	let g:ycm_auto_trigger = 1
	nnoremap <leader>gt :YcmCompleter GoTo<CR>
	nnoremap <leader>gr :YcmCompleter GoToReferences<CR>
	nnoremap <leader>gd :YcmCompleter GetDoc<CR>
	let g:ycm_filetype_specific_completion_to_disable = {
      \ 'cpp': 1
      \}
	" let g:ycm_key_invoke_completion = ';;'
	
	Plug 'ervandew/supertab'
	" make YCM compatible with UltiSnips (using supertab)
	let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
	let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
	let g:SuperTabDefaultCompletionType = '<C-n>'

	" better key bindings for UltiSnipsExpandTrigger
	let g:UltiSnipsExpandTrigger = "<tab>"
	let g:UltiSnipsJumpForwardTrigger = "<tab>"
else
	" set pyxversion=3
	Plug 'roxma/vim-hug-neovim-rpc' 
	Plug 'roxma/nvim-yarp', { 'do': 'sudo pip3 install neovim'}
	let pyver = execute(':pythonx import sys;sys.version.split(" ")')
	if pyver < '3.6.1'
		Plug 'Shougo/deoplete.nvim', { 'tag':'4.1', 'do': 'sudo pip3 install --user pynvim' }
	else
		Plug 'Shougo/deoplete.nvim', { 'do': 'sudo pip3 install --user pynvim' }
	endif
	Plug 'Shougo/neco-syntax'
	Plug 'zchee/deoplete-jedi'
	Plug 'wellle/tmux-complete.vim'
	Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash install.sh' } 
	Plug 'deoplete-plugins/deoplete-dictionary'
	Plug 'Shougo/context_filetype.vim'
	Plug 'Shougo/neopairs.vim'
	Plug 'Shougo/echodoc.vim'
	Plug 'Shougo/neoinclude.vim'
	let g:deoplete#enable_at_startup = 1
endif

" Plug 'ludovicchabant/vim-gutentags'
" Plug 'skywind3000/gutentags_plus'


Plug 'Konfekt/FastFold'

Plug 'vim-scripts/a.vim', {'as': 'alternate.vim', 'do': 'sed -i \"/^imap /d\" $(fd --no-ignore ^a.vim$)'}
" {{{
	let g:alternateNoDefaultAlternate = 1
" }}}
Plug 'tpope/vim-repeat'
nmap <Leader>M <Plug>MarkSet
let g:mwHistAdd = '@'
let g:mwAutoLoadMarks = 1
let g:mw_no_mappings = 1
" dependency of vim-mark
Plug 'inkarkat/vim-ingo-library'  
Plug 'inkarkat/vim-mark'

Plug 'rhysd/clever-f.vim'
" {{{
  let g:clever_f_across_no_line = 1
" }}}
" gaip= 
Plug 'junegunn/vim-easy-align'
" {{{
  let g:easy_align_ignore_comment = 0 " align comments
  vnoremap <silent> <Enter> :EasyAlign<cr>
	" Start interactive EasyAlign in visual mode (e.g. vipga)
	xmap ga <Plug>(EasyAlign)
	" " Start interactive EasyAlign for a motion/text object (e.g. gaip)
	nmap ga <Plug>(EasyAlign)
" }}}


Plug 'w0rp/ale'
let g:ale_set_quickfix = 1
let g:ale_maximum_file_size = 1048576
let g:ale_python_flake8_options="--max-line-length=120 --ignore=E402,E999,E722"
let g:ale_python_isort_options = '-sl --line-width=120'
let g:ale_linters = { 'python' : ['flake8'], 'cpp' : ['all'] }

let g:ale_fixers = {  'python': ['isort', 'yapf', 'trim_whitespace'], 'json': ['jq','remove_trailing_lines', 'trim_whitespace'], 'cpp':['remove_trailing_lines', 'trim_whitespace']}
let g:ale_fix_on_save = 1
let s:yapf_bin =  ""
if filereadable(s:yapf_bin)
	let g:ale_python_yapf_executable = s:yapf_bin
endif
nmap <silent> <leader>p <Plug>(ale_previous_wrap)
nmap <silent> <leader>n <Plug>(ale_next_wrap)

Plug 'tomasr/molokai'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
let g:UltiSnipsJumpBackwardTrigger="<c-b>"
let g:UltiSnipsSnippetDirectories=["mysnips", "UltiSnips"]
let g:snips_author=$MYNAME
let g:snips_email=$MYEMAIL

"Plug 'tweekmonster/braceless.vim'
"let g:braceless_line_continuation = 0
"autocmd FileType python BracelessEnable +indent 

Plug 'scrooloose/nerdcommenter'

Plug 'nathanaelkane/vim-indent-guides'
" {{{
 	let g:indent_guides_default_mapping = 0
	let g:indent_guides_enable_on_vim_startup = 0
	let g:indent_guides_color_change_percent = 10
	let g:indent_guides_guide_size = 2
	let g:indent_guides_start_level = 2
	au FileType python IndentGuidesEnable
	au FileType python let indent_guides_auto_colors = 0
	au FileType python autocmd BufEnter,Colorscheme * :hi IndentGuidesOdd  guibg=darkgrey   ctermbg=236
	au FileType python autocmd BufEnter,Colorscheme * :hi IndentGuidesEven guibg=darkgrey   ctermbg=240
" }}}

"Plug 'tmhedberg/SimpylFold'
"let g:SimpylFold_docstring_preview = 1
"set foldlevelstart=1

Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'roxma/vim-paste-easy'

Plug 'scrooloose/nerdtree'
let g:NERDTreeWinPos = "right"
let NERDTreeShowHidden=0
let NERDTreeIgnore = ['\.pyc$', '__pycache__']
let g:NERDTreeWinSize=35
nmap <leader>nn :NERDTreeToggle<cr>
Plug 'majutsushi/tagbar'
nmap <leader>tt :TagbarToggle<cr>
let g:tagbar_width = 30
Plug 'dyng/ctrlsf.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme = 'sol'
let g:airline#extensions#wordcount#enabled = 0
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#ale#enabled = 1

" Plug 'machakann/vim-sandwich'
Plug 'wellle/targets.vim'
Plug 'christoomey/vim-tmux-navigator'
let g:tmux_navigator_disable_when_zoomed = 1
" cxiw cxiw exchage word
Plug 'tommcdo/vim-exchange'
Plug 'janko/vim-test'
" these "Ctrl mappings" work well when Caps Lock is mapped to Ctrl
nmap <silent> t<C-n> :TestNearest<CR> 
nmap <silent> t<C-f> :TestFile<CR>   
nmap <silent> t<C-s> :TestSuite<CR> 
nmap <silent> t<C-l> :TestLast<CR> 
nmap <silent> t<C-g> :TestVisit<CR> 
let test#python#runner = 'pytest'
Plug 'tpope/vim-eunuch'
" Plug 'tpope/vim-unimpaired'
Plug 'mbbill/undotree'
" {{{
  set undofile
  " Auto create undodir if not exists
  let undodir = expand(g:cachedir . '/undodir')
  if !isdirectory(undodir)
    call mkdir(undodir, 'p')
  endif
  let &undodir = undodir

  nnoremap <leader>U :UndotreeToggle<CR>
" }}}

Plug 'junegunn/vim-peekaboo'
" {{{
  let g:peekaboo_delay = 400
" }}}
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'
Plug 'haya14busa/is.vim'
Plug 'terryma/vim-multiple-cursors'
let g:multi_cursor_select_all_key = 'g<c-n>'




" (Optional) Multi-entry selection UI.
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
nmap <leader>ff :Files<cr>
nmap <leader>fd :FilesUnderFileDir<cr>
nmap <leader>fg :FilesUnderGitRoot<cr>
nmap <leader>b :Buffers<cr>
nmap <leader>m :History<cr>
nmap <leader>rr :Rg<cr>
nmap <leader>rd :RgUnderFileDir<cr>
nmap <leader>rg :RgUnderGitRoot<cr>

let g:fzf_history_dir = g:cachedir . "/fzf-history"
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1
" [[B]Commits] Customize the options used by 'git log':
let g:fzf_commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'
" [Commands] --expect expression for directly executing the command
let g:fzf_commands_expect = 'alt-enter,ctrl-x'


command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=? -complete=dir FilesUnderFileDir
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({ 'dir': expand('%:p:h')}), <bang>0)

command! -bang -nargs=? -complete=dir FilesUnderGitRoot
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({ 'dir': systemlist('cd '. expand('%:p:h') . ';git rev-parse --show-toplevel')[0] }), <bang>0)

command! -bang -nargs=?  History
  \ call fzf#vim#history(fzf#vim#with_preview(), <bang>0)

" Files target dir
"
"
let s:rg_cmd="rg --column --line-number --no-heading --color=always --smart-case --no-config "

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   s:rg_cmd.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({ 'dir': expand('%:p:h') }, 'right:50%'),
  \   <bang>0)

command! -bang -nargs=* RgUnderFileDir
  \ call fzf#vim#grep(
  \   s:rg_cmd.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({ 'dir': expand('%:p:h') }, 'right:50%'), 
  \   <bang>0)

command! -bang -nargs=* RgUnderGitRoot
  \ call fzf#vim#grep(
  \   s:rg_cmd.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({ 'dir': systemlist('cd '. expand('%:p:h') . ';git rev-parse --show-toplevel')[0] }, 'right:50%'), 
  \   <bang>0)

" enable gtags module
let g:gutentags_modules = ['ctags', 'gtags_cscope']

" config project root markers.
let g:gutentags_project_root = ['.root']

" generate datebases in my cache directory, prevent gtags files polluting my project
let g:gutentags_cache_dir = g:cachedir . '/tags'

" change focus to quickfix window after search (optional).
let g:gutentags_plus_switch = 1

" Text Navigation
" ====================================================================
Plug 'Lokaltog/vim-easymotion'
" {{{
  let g:EasyMotion_do_mapping = 0
  let g:EasyMotion_smartcase = 1
  let g:EasyMotion_off_screen_search = 0
  nmap ; <Plug>(easymotion-s2)
" }}}
Plug 'rhysd/clever-f.vim'
" {{{
  let g:clever_f_across_no_line = 1
" }}}
"

Plug 'mzlogin/vim-markdown-toc'


let $TERM_PROGRAM = 'iTerm.app'
Plug 'jszakmeister/vim-togglecursor'
Plug 'elzr/vim-json'
Plug 'will133/vim-dirdiff'

Plug 'aperezdc/vim-template'
Plug 'stephpy/vim-yaml'
" {{{
 let g:templates_no_builtin_templates =1
 let g:templates_use_licensee = 0
 let g:templates_directory = [g:vimdir . '/mytpls']
 " let g:templates_debug = 1
 " let g:templates_user_variables = 
" }}}
call plug#end()

try
	" Remove this if you'd like to use fuzzy search
	" call deoplete#custom#source('dictionary', 'matchers', ['matcher_head'])
	" If dictionary is already sorted, no need to sort it again.
	call deoplete#custom#source('dictionary', 'sorters', [])
	" Do not complete too short words
	call deoplete#custom#source('dictionary', 'min_pattern_length', 3)
	call deoplete#custom#source('dictionary', 'keyword_patterns', {'_': '[a-zA-Z_0-9/]\w*', 'python': '[a-zA-Z_0-9/]\w*'})
	call deoplete#custom#option('converter_auto_delimiter', [])

	" debug deoplete
	" call deoplete#custom#option('profile', v:true)
	" call deoplete#enable_logging('DEBUG', 'deoplete.log')
	"let $NVIM_PYTHON_LOG_FILE="/data1/youbin/nvim_log"
	" let $NVIM_PYTHON_LOG_LEVEL="DEBUG"
catch
endtry
