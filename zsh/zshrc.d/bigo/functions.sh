function dbls() {
  local db rpath
  for db in "$@"; do
    rpath=
    if [ "$db" =~ ^bigolive\.* ]; then
      rpath="/flume/bigolive/${db#*.}"
    elif [ "$db" =~ ^report_tb\.* ]; then
      rpath="/data/hive/report_tb.db/${db#*.}"
    elif [ "$db" =~ ^algo\.* ]; then
      rpath="/recommend/hive/algo.db/${db#*.}"
    elif [ "$db" =~ ^default\.* ]; then
      rpath="/user/hive/warehouse/${db#*.}"
    elif [ "$db" =~ ^tmp\.* ]; then
      rpath="/apps/hive/warehouse/tmp.db/${db#*.}"
    fi
    echo "> $db : $rpath"
    if [ -n "$rpath" ]; then
      hadoop fs -ls "$rpath"| tail -10
    fi
  done
}

alias hdls="hadoop fs -ls"
alias hdrm="hadoop fs -rmr"
alias hdput="hadoop fs -put"
function down_repo() {
  for repo in ${@}
  do
    git clone ssh://youbin@gerrit.sysop.520hello.com:29418/$repo && scp -p -P 29418 youbin@gerrit.sysop.520hello.com:hooks/commit-msg $repo/.git/hooks/
  done
}

alias ssh="ssh -o StrictHostKeyChecking=no -p 10020"

unalias go 2>/dev/null
function go() {
  # set -x
  t=${1}
  ips=$(cat ~/server.txt | grep "$t")
  ips_cnt=$(echo "$ips" | wc -l )
  target=
  if echo "$t" | egrep -q '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    target="$t"
  elif [[ $ips_cnt -eq 1 ]]; then
    target="$ips"
  else
    let i=1
    echo "$ips" | while read -r ip
    do
      echo $i: $ip
      let i++
    done
    NO=-1
    while [[ $NO -lt 1 || $NO -gt $ips_cnt ]]
    do
        echo -n "no:"
        read NO
        [[ $NO == "" ]] && NO=1
    done

    ip=$(echo "$ips" | sed -n "${NO}p")
    target=$ip
  fi
  ssh -o StrictHostKeyChecking=no -p 10020 $(echo $target | cut -f1 -d' ')
  set +x
}

unalias gg 2>/dev/null
function gg() {
  # set -x
  t=${1}
  ips=$(cat ~/server.txt | grep "$t")
  ips_cnt=$(echo "$ips" | wc -l )
  target=
  if echo "$t" | egrep -q '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    target="$t"
  elif [[ $ips_cnt -eq 1 ]]; then
    target="$ips"
  else
    let i=1
    echo "$ips" | while read -r ip
    do
      echo $i: $ip
      let i++
    done
    NO=-1
    while [[ $NO -lt 1 || $NO -gt $ips_cnt ]]
    do
        echo -n "no:"
        read NO
        [[ $NO == "" ]] && NO=1
    done

    ip=$(echo "$ips" | sed -n "${NO}p")
    target=$ip
  fi
  sshrc -o StrictHostKeyChecking=no -p 10020 $(echo $target | cut -f1 -d' ')
  set +x
}
