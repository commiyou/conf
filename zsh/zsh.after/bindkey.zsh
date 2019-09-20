#!/usr/bin/env zsh
rationalise-dot() {
  if [[ $LBUFFER = *.. ]]; then
    LBUFFER+=/..
  else
    LBUFFER+=.
  fi
}
zle -N rationalise-dot
bindkey -M emacs . rationalise-dot

zmodload -i zsh/parameter
insert-last-command-output() {
 LBUFFER+="$(eval $history[$((HISTCMD-1))])"
}
zle -N insert-last-command-output
bindkey -M emacs '^[x' insert-last-command-output
bindkey -M emacs -s '^[>' '^Q..^M' # Alt-S-.
bindkey -M emacs -s '^[_' '^Qcd -^M' # Alt-S-\-
bindkey -M emacs -s '^[o' '^Anohup ^e &^M' # Alt-n
bindkey -M emacs '^[k' kill-line
bindkey -M emacs '^[j' accept-line

dostuff_internal () {
   zle push-line
   BUFFER="$@"
   zle accept-line
}
zle -N dostuff_internal
dostuff_ls () {
   zle dostuff_internal -- " ls -lrt"
}
zle -N dostuff_ls
bindkey -M emacs "^[l" dostuff_ls

bindkey -M menuselect '^p' vi-up-line-or-history
bindkey -M menuselect '^n' vi-down-line-or-history

bindkey -M emacs '^]' vi-cmd-mode
bindkey -M emacs '^[' vi-cmd-mode
