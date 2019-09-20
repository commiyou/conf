pathAppend() {
  PATH=$PATH:$1
  # Remove duplicate entries from PATH:
  PATH=$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++{if (NR > 1) printf ORS; printf $a[$1]}')
}

pathPrepend() {
  PATH=$1:$PATH
  # Remove duplicate entries from PATH:
  PATH=$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++{if (NR > 1) printf ORS; printf $a[$1]}')
}


pathPrepend $ZDOTDIR/../bin
pathPrepend $ZDOTDIR/bin
if [ -f $ZDOTDIR/paths ]; then
  while IFS= read -r line
  do
    pathPrepend $line
  done < $ZDOTDIR/paths
fi

fpath+=$ZDOTDIR/completion
