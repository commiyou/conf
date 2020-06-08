#  -U stands for unique
typeset -U path

[ -r ${ZDOTDIR:-$HOME}/.path ] && path=(${(f)"$(<${ZDOTDIR:-$HOME}/.path)"} $path)
