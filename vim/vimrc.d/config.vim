" https://github.com/b4b4r07/dotfiles/blob/master/.vim/rc/config.vim

function! s:config()
    let config = {}
    let config.is_ = {}

    let config.is_.windows = has('win16') || has('win32') || has('win64')
    let config.is_.cygwin = has('win32unix')
    let config.is_.mac = !config.is_.windows && !config.is_.cygwin
                \ && (has('mac') || has('macunix') || has('gui_macvim') ||
                \    (!executable('xdg-open') &&
                \    system('uname') =~? '^darwin'))
    let config.is_.linux = !config.is_.mac && has('unix')

    let config.is_starting = has('vim_starting')
    let config.is_gui      = has('gui_running')
    let config.hostname    = substitute(hostname(), '[^\w.]', '', '')

    " vim
    if !empty($XDG_DATA_HOME)
        let vim_data_path = expand($XDG_DATA_HOME . '/vim')
    else
        let vim_data_path = expand('~/.vim')
    endif

    if !empty($XDG_CONFIG_HOME)
        let vim_config_path = expand($XDG_CONFIG_HOME . '/vim')
    else
        let vim_config_path = expand('~')
    endif


    let config.path = {
                \ 'data': vim_data_path,
                \ 'config':  vim_config_path,
                \ }

    let config.bin = {
                \ 'ag':        executable('ag'),
                \ 'osascript': executable('osascript'),
                \ 'open':      executable('open'),
                \ 'chmod':     executable('chmod'),
                \ 'qlmanage':  executable('qlmanage'),
                \ }

    " tmux
    let config.is_tmux_running = !empty($TMUX)
    let config.tmux_proc = system('tmux display-message -p "#W"')
    if !empty($AUTO_INSTALL)
        let s:plugin_on = 1
    else
        let s:plugin_on = 0
    endif


    let config.vimrc = {
                \ 'plugin_on': s:plugin_on,
                \ }

    return config
endfunction

let g:config = s:config()

function! IsWindows() abort
    return g:config.is_.windows
endfunction

function! IsMac() abort
    return g:config.is_.mac
endfunction
