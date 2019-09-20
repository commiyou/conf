[ -d $ZDOTDIR/../vim ] && export vimdir=$(cd $ZDOTDIR/../vim; pwd)
if [ -n "$vimdir" ]; then
  export viminfo=$vimdir/.viminfo
  export vimrc=$vimdir/.vimrc
  export vim="vim -u $vimrc"

  export VIMINIT="so $vimrc"
  #alias vim="$vim"
  #alias vimdiff="vimdiff -u $vimrc"
fi
