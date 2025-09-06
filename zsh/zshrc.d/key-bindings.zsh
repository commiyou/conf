# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    echoti smkx
  }
  function zle-line-finish() {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

#bindkey -e # Use emacs key bindings
bindkey '^f' forward-char
bindkey '^b' backward-char
bindkey '^e' end-of-line
bindkey '^a' beginning-of-line
bindkey '^p' up-line-or-history
bindkey '^n' down-line-or-history
bindkey -M viins '^u' vi-kill-line 
bindkey '^x^n' infer-next-history # Search in the history list for a line matching the current one and fetch the event following it.
bindkey '^y' yank
bindkey -M viins '^y' vi-yank
bindkey "^['" quote-line
bindkey '^t' transpose-chars
bindkey '^o' accept-and-infer-next-history
bindkey "^Q" push-line

bindkey "^[?" which-command
bindkey '^[a' accept-and-hold # push the contents of the buffer on the buffer stack and execute it.
bindkey "^[b" backward-word
bindkey "^[f" forward-word
bindkey "^[T" transpose-words
bindkey "^_" undo



if [[ "${terminfo[kpp]}" != "" ]]; then
  bindkey "${terminfo[kpp]}" up-line-or-history       # [PageUp] - Up a line of history
fi
if [[ "${terminfo[knp]}" != "" ]]; then
  bindkey "${terminfo[knp]}" down-line-or-history     # [PageDown] - Down a line of history
fi

# start typing + [Up-Arrow] - fuzzy find history forward
if [[ "${terminfo[kcuu1]}" != "" ]]; then
  autoload -U up-line-or-beginning-search
  zle -N up-line-or-beginning-search
  bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
fi
# start typing + [Down-Arrow] - fuzzy find history backward
if [[ "${terminfo[kcud1]}" != "" ]]; then
  autoload -U down-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

if [[ "${terminfo[khome]}" != "" ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line      # [Home] - Go to beginning of line
fi
if [[ "${terminfo[kend]}" != "" ]]; then
  bindkey "${terminfo[kend]}"  end-of-line            # [End] - Go to end of line
fi

bindkey '^[[1;5C' forward-word                        # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word                       # [Ctrl-LeftArrow] - move backward one word

if [[ "${terminfo[kcbt]}" != "" ]]; then
  bindkey "${terminfo[kcbt]}" reverse-menu-complete   # [Shift-Tab] - move through the completion menu backwards
fi

bindkey '^?' backward-delete-char                     # [Backspace] - delete backward
if [[ "${terminfo[kdch1]}" != "" ]]; then
  bindkey "${terminfo[kdch1]}" delete-char            # [Delete] - delete forward
else
  bindkey "^[[3~" delete-char
  bindkey "^[3;5~" delete-char
  bindkey "\e[3~" delete-char
fi

# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# file rename magic
bindkey "^[m" copy-prev-shell-word

bindkey '^X^F' emacs-forward-word
bindkey '^X^B' emacs-backward-word
#
bindkey -s '^X^Z' '%-^M'
bindkey '^Xe' expand-cmd-path
#bindkey '^[^I' reverse-menu-complete
#bindkey '^X^N' accept-and-infer-next-history
bindkey '^W' kill-region
bindkey '^I' complete-word

expand-dot-to-parent-directory-path() {
  if [[ $LBUFFER = *.. ]]; then
    LBUFFER+='/..'
  else
    LBUFFER+='.'
  fi
}

zle -N expand-dot-to-parent-directory-path

#bindkey -M emacs . expand-dot-to-parent-directory-path
bindkey . expand-dot-to-parent-directory-path

bindkey -M emacs -s '^[o' '^Anohup ^e &^M' # Alt-o

# run command using sudo(1)
function _run_with_sudo {
  BUFFER="sudo $BUFFER"
  zle end-of-line
  #zle accept-line
}
zle -N _run_with_sudo
bindkey '^Xs' _run_with_sudo

# # replace command with pager
# function _run_with_pager {
#   local command="$PAGER ${BUFFER#* }"
#   zle push-line
#   BUFFER=$command
#   zle accept-line
# }
#

function _insert_date {
  LBUFFER+="$(date +%Y%m%d)"
}
zle -N _insert_date
bindkey "^X^a" _insert_date

# replace command with pager
function _ls_cwd {
  local command="ls -lrt ."
  zle push-line
  BUFFER=$command
  zle accept-line
}
zle -N _ls_cwd
bindkey '^X^l' _ls_cwd


function _fno_with_last_word {
  local orig_buffer="$BUFFER"
  local orig_cursor=$CURSOR

  # 获取最后一个单词
  local last_word=${(M)BUFFER##* }
  #zle push-line

  local query=""
  if [[ $last_word == *.tsv || $last_word == *.txt ]]; then
    query="--query=$last_word"
  fi

  local sel qsel
  sel=$(fd --type f . | fzf $query --preview 'fno -- {}') || {
    zle redisplay
    return 0
  }

  [[ -z "$sel" ]] && {
    zle redisplay
    return 0
  }

  qsel=$(printf "%q" "$sel")

  zle push-line
  # 执行 fno
  BUFFER="fno $qsel"
  zle accept-line
}
zle -N _fno_with_last_word
bindkey "^X^x" _fno_with_last_word



# emacs - Emacs emulation
# viins - Vi mode - INSERT mode
# vicmd - Vi mode - NORMAL mode (also confusingly called COMMAND mode)
# viopp - Vi mode - OPERATOR-PENDING mode
# visual - Vi mode - VISUAL mode
# https://github.com/jeffreytse/zsh-vi-mode
#function zvm_after_lazy_keybindings() {
function zvm_after_init() {
  # Here we define the custom widget
  #zvm_define_widget my_custom_widget

  # In normal mode, press Ctrl-E to invoke this widget
  #zvm_bindkey vicmd '^E' my_custom_widget

  zvm_define_widget _run_with_sudo
  zvm_bindkey viins '^Xs' _run_with_sudo
  zvm_bindkey vicmd '^[.' insert-last-word
  zvm_bindkey vicmd '^[m' copy-earlier-word

  zvm_define_widget _insert_date
  zvm_bindkey viins '^Xa' _insert_date

  zvm_define_widget _ls_cwd
  zvm_bindkey viins '^X^l' _ls_cwd

  zvm_define_widget _fno_with_last_word
  zvm_bindkey viins '^X^x' _fno_with_last_word

  export ZVM_ESCAPE_KEYTIMEOUT=0.05

  #zvm_define_widget expand-dot-to-parent-directory-path
  #zvm_bindkey viins . expand-dot-to-parent-directory-path
}

# bindkey -e                       # switch to emacs modes 
# bindkey -v                       # switch to vi mode
# bindkey -N newmap                # this creates a keybind named 'newmap'
# bindkey -N mycoolmap emacs       # this creates a new keymap based off the existing 'emacs'
# bindkey -A mycoolmap mymacs      # this creates an alias 'mymacs' for 'mycoolmap'
# bindkey -l                       # currently available keymaps
# bindkey -lL                      # format the output as a series of the bindkey commands
# bindkey -L                       # a list of all your current bindings, including those of a built-in keymap, formatted in a way you can use within your scripts
# zle -al  # list all  registered zle commands

