#!/usr/bin/env zsh


#zstyle ':completion:*' completer _complete _list _oldlist _expand _ignored _match _correct _approximate _prefix
#zstyle ':completion:*' completions on
#zstyle ':completion:*' glob on

## Auto rehash commands, may slow
#zstyle ':completion:*' rehash true

## Set format for warnings
#zstyle ':completion:*:warnings' format $'%{\e[0;31m%}No matches for:%{\e[0m%} %d'

## Separate matches into groups
#zstyle ':completion:*:matches' group 'yes'
#zstyle ':completion:*' group-name ''

## Fault tolerance (1 error on 3 characters)
#zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'
## zstyle ':completion:*:approximate:*' max-errors 2

## Attempt to complete many parts at once
#zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# rm: advanced completion (e.g. bak files first)
zstyle ':completion::*:rm:*:*' file-patterns '*.o:object-files:object\ file *(~|.(old|bak|BAK)):backup-files:backup\ files *~*(~|.(o|old|bak|BAK)):all-files:all\ files'

# vim: advanced completion (e.g. tex and rc files first)
zstyle ':completion::*:vim:*:*' file-patterns '*Makefile|*(rc|log)|*.(php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3):vi-files:vim\ likes\ these\ files *~(Makefile|*(rc|log)|*.(log|rc|php|tex|bib|sql|zsh|ini|sh|vim|rb|sh|js|tpl|csv|rdf|txt|phtml|tex|py|n3)):all-files:other\ files'


# Color completion for some things
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt "${fg[red]}%p (%l)${fg[default]}"


#zstyle ':completion:*' verbose yes
#zstyle ':completion:*:descriptions' format '%B%d%b'
#zstyle ':completion:*:messages' format '%d'
#zstyle ':completion:*' group-name ''

#zstyle ':completion:*:processes' command 'ps -au$USER'
#zstyle ':completion:*:*:kill:*' menu yes select
#zstyle ':completion:*:kill:*' force-list always
#zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#)*=29=34"
#zstyle ':completion:*:*:killall:*' menu yes select
#zstyle ':completion:*:killall:*' force-list always


#zstyle ':completion:*:cd:*' ignore-parents parent pwd


zstyle ':completion:*:*:vim:*:*files' ignored-patterns '*?.o' "*?.pyc"
zstyle ':completion:*:*:vi:*:*files' ignored-patterns '*?.o' "*?.pyc"

#zstyle ':completion:*' file-sort access
zstyle ':completion:*' file-sort 'modification'


# http://www.thregr.org/~wavexx/rnd/20141010-zsh_show_ambiguity/
#zmodload zsh/complist
#autoload -Uz compinit 
#if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
	#compinit;
#else
	#compinit -C;
#fi;
zstyle ':completion:*' show-ambiguity true
autoload -U colors
colors
zstyle ':completion:*' show-ambiguity "$color[fg-red]"


# _gnu_generic Can be used toomplete options forommands that understand the `–help’ option.
# compdef _gnu_generic csbk slbk base64 col_merge divide fno insert percent pprint unquote

# https://gist.github.com/blueyed/6856354
# _tmux_pane_words() {
# 	local expl
# 	local -a w
# 	IFS=$'\n' w=( ${(u)=$($BIN_DIR/tmuxcomplete)} )
# 	_wanted values expl 'words from current tmux pane' compadd -a w
# }
# man zshcompsys 
# compdef _tmux_pane_words -default-
# zle -C tmux-pane-words-prefix   complete-word _generic
# zle -C tmux-pane-words-anywhere complete-word _generic
# bindkey '^X^T' tmux-pane-words-prefix
# bindkey '^X^TT' tmux-pane-words-anywhere
# zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' completer _tmux_pane_words
# zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' ignore-line current
# # Display the (interactive) menu on first execution of the hotkey.
# zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' menu yes select interactive
# # zstyle ':completion:tmux-pane-words-anywhere:*' matcher-list 'b:=* m:{A-Za-z}={a-zA-Z}'
# zstyle ':completion:tmux-pane-words-(prefix|anywhere):*' matcher-list 'b:=* m:{A-Za-z}={a-zA-Z}'
# # }}}
# Ignore what's already in the line
zstyle ':completion:*:(rm|cp|mv||kill|diff|vim|cat|less|more|gzip|gunzip|zcat|tar|fg|bg):*' ignore-line yes


