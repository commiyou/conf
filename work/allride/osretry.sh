#!/bin/bash
#  redownload all oss *.temp files
#  /4000/*.bag.temp
#  /4001/*.bag.temp
#



cwd=$(pwd)
while true
do
  fd temp$ | xargs -n1 | tac | while read line
  do
    [ -z "$line" ] && break
    bagdir=$(dirname $line)

    bagfile=${line%.temp}
    bagfile=${bagfile##*/}
    echo process $bagfile ..
    cd $cwd/$bagdir/ossutil_output || cd $cwd/$bagdir/../ossutil_output
    bagaddr=$(cat * | grep ' cp ' | xargs -n1 |grep '^oss://' | sort -u | grep $bagfile)
    if [ -z "$bagaddr" ]; then
      bagaddr=$(cat * | grep ' cp ' | xargs -n1 |grep '^oss://' | sort -u | grep $(basename $(dirname $line)))
      bagaddr=${bagaddr%%/}
    fi
    if [ -z "$bagaddr" ]; then
      bagaddr=$(cat * | grep ' cp ' | xargs -n1 |grep '^oss://' | sort -u | egrep -v 'bag$|log$|gz$' | head -1)
      bagaddr=${bagaddr%%/}
    fi

    if [ -z "$bagaddr" ]; then
      echo "error process $bagfile"
      continue
    fi
    echo $bagaddr | grep $bagfile || bagaddr=$bagaddr/$bagfile

    cd $cwd/$bagdir/
    echo ossutil64 cp $bagaddr $bagdir
    ossutil64 cp $bagaddr .

    echo
  done
  exit

  if [ $(fd temp$ | wc -l) -eq 0 ]; then
    break
  fi

done
