function dbls() {
  local db rpath f
  for db in "$@"; do
    rpath=
    if [ "$db" =~ ^bigolive\.* ]; then
      rpath="/flume/bigolive/${db#*.}"
      rpath=$rpath" /user/hive/warehouse/bigolive.db/${db#*.}"
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
      for f in $(echo $rpath); do
        hadoop fs -ls "$f"| tail -10
      done
    fi
  done
}

alias hdls="hadoop fs -ls"
alias hdrm="hadoop fs -rmr"
alias hdput="hadoop fs -put"

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
  if command -v sshrc &> /dev/null; then
    sshrc -o StrictHostKeyChecking=no -p 10020 $(echo $target | cut -f1 -d' ')
  else
    ssh -o StrictHostKeyChecking=no -p 10020 $(echo $target | cut -f1 -d' ')
  fi
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

conan_build() {
  cd $(git rev-parse --show-toplevel 2>/dev/null || echo .) 
  [ "$1" == "-f" ] && rm -r build 
  mkdir -p build && cd build 
  conan install .. -u --build=missing && cmake .. && make -j 32
}

gerrit_url() {
  local repo_name=${1:-$(basename $(git rev-parse --show-toplevel))}
  echo "http://gerrit.sysop.520hello.com/#/admin/projects/$repo_name,branches"
}

service_conf() {
  vim /data/services/*$1*/conf/server.conf
}

service_gflag() {
  vim /data/services/*$1*/conf/gflags.conf
}

service_log() {
  less /data/yy/log/*$1*/*$1*.log
}

service_port() {
  #port, pid
  # sudo netstat -t -l -n -p | awk '/LISTEN/{n = split($4, a, ":"); m = split($7, b, "/"); print a[n]"\t"b[1]  }'
  local sn=${1?no service name}
  sn=${sn:0:15}
  sudo lsof -a -i -c ${sn} | grep LISTEN | sed  's,\*,http://'$(echo $SSH_CONNECTION | cut -f3 -d ' '),
}

service_debug() {
:
}
