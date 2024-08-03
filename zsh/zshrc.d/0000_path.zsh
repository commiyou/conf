#  -U stands for unique
typeset -U path

[ -r ${ZDOTDIR:-$HOME}/.path ] && path=(${(f)"$(<${ZDOTDIR:-$HOME}/.path)"} $path)
[ -r ${HOME}/.path ] && path=(${(f)"$(<${HOME}/.path)"} $path)
path=("$HOME/bin" "$HOME/.local/bin" "$XDG_CONFIG_HOME/bin/" $path)

typeset -aU ld_library_path
ld_library_path=(${(s.:.)LD_LIBRARY_PATH})
[ -r ${ZDOTDIR:-$HOME}/.ld.path ] && ld_library_path=(${(f)"$(<${ZDOTDIR:-$HOME}/.ld.path)"} $ld_library_path)
[ -r ${HOME}/.ld.path ] && ld_library_path=(${(f)"$(<${HOME}/.ld.path)"} $ld_library_path)
export LD_LIBRARY_PATH=${(j.:.)ld_library_path}


