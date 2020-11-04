let s:spath = resolve(expand('<sfile>:p:h'))

let g:plug = {
            \ 'plug':   expand(g:config.path.config) . '/autoload/plug.vim',
            \ 'base':   expand(g:config.path.data) . '/plugged',
            \ 'url':    'https://raw.github.com/junegunn/vim-plug/master/plug.vim',
            \ 'github': 'https://github.com/Shougo/dein.vim',
            \ }

if g:config.vimrc.plugin_on
    if empty(glob(g:plug.plug))
        silent exec '!curl -fLo ' . g:plug.plug . ' --create-dirs
                    \  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif

    call plug#begin(g:plug.base)

    try
    	let pyver = execute(':pythonx import sys;print(sys.version.split(" ")[0])')
    catch
    	let pyver='2.7'
    endtry

    let g:netrw_home= g:cachedir

    if has("python3") && pyver > '3.0'

        Plug 'roxma/vim-hug-neovim-rpc', { 'do': 'pip3 intall --user pynvim' }
        Plug 'roxma/nvim-yarp', { 'do': 'pip3 install --user neovim'}
        
        if pyver < '3.6.1'
            Plug 'Shougo/deoplete.nvim', { 'tag':'4.1', 'do': 'pip3 install --user pynvim' }
        else
            Plug 'Shougo/deoplete.nvim', { 'do': 'pip3 install --user pynvim' }
        endif
        Plug 'Shougo/neco-syntax'
        Plug 'tbodt/deoplete-tabnine', { 'do': './install.sh' }
        Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash install.sh' } 
        Plug 'deoplete-plugins/deoplete-dictionary'
        Plug 'Shougo/context_filetype.vim'
        Plug 'Shougo/neopairs.vim'
        Plug 'Shougo/echodoc.vim'
        Plug 'Shougo/neoinclude.vim'
    endif



    Plug 'wellle/tmux-complete.vim'
    let nodejs_version = system('node -v')
    if nodejs_version >= 'v10.12'
        let g:coc_config_home = g:config.path.config
        let g:coc_data_home = g:config.path.data . '/coc'
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        if &rtp =~ 'coc.nvim'
            exec 'source'  s:spath . '/plugins/yyy_coc.vim'
        endif
    endif


    " Plug 'ludovicchabant/vim-gutentags'
    " Plug 'skywind3000/gutentags_plus'


    Plug 'Konfekt/FastFold'

    Plug 'enricobacis/a.vim'
    let g:alternateNoDefaultAlternate = 1

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

    if pyver >= '3.5'
	    Plug 'SirVer/ultisnips'
    endif
    Plug 'honza/vim-snippets'
    let g:UltiSnipsJumpBackwardTrigger="<c-b>"
    let g:UltiSnipsSnippetDirectories=["mysnips", "UltiSnips"]
    let g:snips_author=$MYNAME
    let g:snips_email=$MYEMAIL

    "Plug 'tweekmonster/braceless.vim'
    "let g:braceless_line_continuation = 0
    "autocmd FileType python BracelessEnable +indent 

    Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }

    Plug 'tweekmonster/startuptime.vim'

    Plug 'nathanaelkane/vim-indent-guides'
    " {{{
    let g:indent_guides_default_mapping = 0
    let g:indent_guides_enable_on_vim_startup = 0
    let g:indent_guides_color_change_percent = 10
    let g:indent_guides_guide_size = 2
    let g:indent_guides_start_level = 2
    try
        " not load error
        au FileType python silent! IndentGuidesEnable
        au FileType python let indent_guides_auto_colors = 0
        au FileType python autocmd BufEnter,Colorscheme * :hi IndentGuidesOdd  guibg=darkgrey   ctermbg=236
        au FileType python autocmd BufEnter,Colorscheme * :hi IndentGuidesEven guibg=darkgrey   ctermbg=240
    catch
    endtry
    " }}}

    "Plug 'tmhedberg/SimpylFold'
    "let g:SimpylFold_docstring_preview = 1
    "set foldlevelstart=1

    Plug 'ConradIrwin/vim-bracketed-paste'
    "Plug 'roxma/vim-paste-easy'

    "Plug 'scrooloose/nerdtree'
    let g:NERDTreeWinPos = "left"
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
    Plug 'tomasr/molokai'
    Plug 'fmoralesc/molokayo'

    " Plug 'machakann/vim-sandwich'
    Plug 'wellle/targets.vim'
    Plug 'christoomey/vim-tmux-navigator'
    let g:tmux_navigator_disable_when_zoomed = 1
    Plug 'tmux-plugins/vim-tmux'
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

    command! -bang -nargs=? -complete=dir FilesWorkDir
                \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({ 'dir': systemlist('git rev-parse --show-toplevel 2>/dev/null || pwd')[0] }), <bang>0)

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

    command! -bang -nargs=* RgWorkDir
                \ call fzf#vim#grep(
                \   s:rg_cmd.shellescape(<q-args>), 0,
                \   fzf#vim#with_preview({ 'dir': systemlist('git rev-parse --show-toplevel 2>/dev/null || pwd')[0] }, 'right:50%'), 
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
    "Plug 'Lokaltog/vim-easymotion'
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


    "let $TERM_PROGRAM = 'iTerm.app'
    Plug 'jszakmeister/vim-togglecursor'
    Plug 'elzr/vim-json'
    Plug 'will133/vim-dirdiff'

    "Plug 'aperezdc/vim-template'
    Plug 'stephpy/vim-yaml'
    " {{{
    let g:templates_no_builtin_templates =1
    let g:templates_use_licensee = 0
    " let g:templates_directory = [g:vimdir . '/mytpls']
    " let g:templates_debug = 1
    " let g:templates_user_variables = 
    " }}}
    call plug#end()

    try
        " Remove this if you'd like to use fuzzy search
        " call deoplete#custom#source('dictionary', 'matchers', ['matcher_head'])
        " If dictionary is already sorted, no need to sort it again.
        "call deoplete#custom#source('dictionary', 'sorters', [])
        " Do not complete too short words
        " call deoplete#custom#source('dictionary', 'min_pattern_length', 3)
        " call deoplete#custom#source('dictionary', 'keyword_patterns', {'_': '[a-zA-Z_0-9/]\w*', 'python': '[a-zA-Z_0-9/]\w*'})
        " call deoplete#custom#option('converter_auto_delimiter', [])

        " debug deoplete
        " call deoplete#custom#option('profile', v:true)
        " call deoplete#enable_logging('DEBUG', 'deoplete.log')
        "let $NVIM_PYTHON_LOG_FILE="/data1/youbin/nvim_log"
        " let $NVIM_PYTHON_LOG_LEVEL="DEBUG"
    catch
    endtry
endif
