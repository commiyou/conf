service_name() {
  local service_path service_name
  if [ $# -eq 0 ]; then 
    # find
    service_path=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$service_path" ]; then
      service_name=$(\ls $(git rev-parse --show-toplevel 2>/dev/null)/build/bin/ | \egrep '^[a-z_]+$')
    else
      service_name=$(pwd | tr '/' '\n' | egrep '^[a-z_]*-[0-9]+\.[0-9]+\.[0-9]+$')
    fi
  fi
  if [ -z "$service_name" ]; then
    service_name=$(ls /data/services | egrep '^[a-z_]*-[0-9]+\.[0-9]+\.[0-9]+$' | fzf -1 -q "$*")
  fi
  if [ -n "$service_name" ]; then
    echo ${service_name%-*}
  else
    echo "$@"
  fi
}

bigo__service() {
  local usage="bigo service (-m|-c|-g) [-n] [-p]"
  local TEMP=$(getopt -o mcghn --long machine,current,git,name,help -- "$@")
  [ $? != 0 ] && echo "$usage"
  eval set -- "$TEMP"
  # print -- "$@"

  local services print_name print_port
  declare -a services
  while true; do
    case "$1" in
      -h|--help)
        echo "$usage"
        return 0
        ;;
      -m|--machine)
        services+=( $(ls -rt /data/services | egrep '^[a-z_]*-[0-9]+\.[0-9]+\.[0-9]+$') )
        # print -- ${services[@]}
        ;;
      -c|--current)
        local tmp=$(pwd | tr '/' '\n' | egrep '^[a-z_]*-[0-9]+\.[0-9]+\.[0-9]+$')
        [ -n "$tmp" ] && services+=( "$tmp" )
        ;;
      -g|--git)
        services+=( $(basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null) )
        ;;
      -n|--name)
        print_name=1
        ;;
      -p|--port)
        print_port=1
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "Internal error!" ;
        return 1
    esac
    shift
  done
  local service
  for service in "${services[@]}"; do
    if [ -n "$print_name" ]; then
      echo ${service%-*}
    else
      echo ${service}
    fi
  done

  return 0
}

bigo__build() {
  local cwd=$PWD
  pushd $(git rev-parse --show-toplevel 2>/dev/null || echo .) 
  [ "$1" == "-f" ] && rm -rf build 
  mkdir -p build 2>/dev/null && cd build 
  conan install .. -u --build=missing && cmake .. && make -j 32
  popd
}

bigo__clone() {
  local repo
  for repo in "${@}"
  do
    git clone ssh://$USERNAME@gerrit.sysop.520hello.com:29418/$repo && scp -p -P 29418 $USERNAME@gerrit.sysop.520hello.com:hooks/commit-msg $repo/.git/hooks/
    ( cd $repo && git_config_user $USERNAME@bigo.sg; )
  done
  cd $repo
}

bigo__conf() {
  local usage="bigo conf [-s] [-e|-l] [file] [-V]"
  local TEMP=$(getopt -o s:elhV --long service:,edit,list,noverbose,help -- "$@")
  [ $? != 0 ] && echo "$usage"
  eval set -- "$TEMP"

  local service cmd noverbose
  while true; do
    case "$1" in
      -h|--help)
        echo "$usage"
        return 0
        ;;
      -s|--service)
        service="$2"
        shift
        ;;
      -l|--list)
        cmd="ls -l"
        ;;
      -e|--edit)
        cmd=vim
        ;;
      -V|--noverbose)
        noverbose=1
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "Internal error!" ;
        return 1
    esac
    shift
  done

  if [ -z "$service" ]; then
    service=$(bigo__service -c -n)
  fi

  [ $# -eq 0 ] && [ -z "$cmd" ] && cmd="ls"
  [ $# -gt 0 ] && [ -z "$cmd" ] && cmd="cat"
  [ -n "$noverbose" ] || echo $cmd /data/services/$service*/conf/"$@" 1>&2
  eval $cmd /data/services/$service*/conf/"$@"
  return 0
}

bigo__log() {
  local usage="bigo log [-s] [-e|-l|-t [linecnt]] [file] [-V]"
  local TEMP=$(getopt -o s:elt::Vh --long service:,edit,list,tail::,noverbose,help -- "$@")
  [ $? != 0 ] && echo "$usage"
  eval set -- "$TEMP"

  local service cmd noverbose linecnt
  while true; do
    case "$1" in
      -h|--help)
        echo "$usage"
        return 0
        ;;
      -t|--tail)
        case "$2" in
          "") linecnt=10 ;;
          *) linecnt="$2" ;;
        esac
        cmd="tail -$linecnt"
        shift
        ;;
      -s|--service)
        service="$2"
        shift
        ;;
      -l|--list)
        cmd="ls -l"
        ;;
      -e|--edit)
        cmd=vim
        ;;
      -V|--noverbose)
        noverbose=1
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "Internal error!" ;
        return 1
    esac
    shift
  done

  if [ -z "$service" ]; then
    service=$(bigo__service -c -n)
  fi

  [ $# -eq 0 ] && [ -z "$cmd" ] && cmd="ls"
  [ $# -gt 0 ] && [ -z "$cmd" ] && cmd="cat"
  [ -n "$noverbose" ] || echo $cmd /data/yy/log/$service/"$@" 1>&2
  eval $cmd /data/yy/log/$service/"$@"
  return 0
}

bigo__url() {
  local TEMP=$(getopt -o dgjah --long deploy,gerrit,jenkins,all,help -- "$@")
  [ $? != 0 ] && echo "bigo url (-d|-g|-j|-a) [service]"
  eval set -- "$TEMP"

  local service urls url
  declare -a urls
  while true; do
    case "$1" in
      -h|--help)
        echo "bigo url (-d|-g|-j|-a) [service]"
        return 0
        ;;
      -d|--deploy)
        urls+=(deploy)
        ;;
      -j|--jenkins)
        urls+=(jenkins)
        ;;
      -g|--gerrit)
        urls+=(gerrit)
        ;;
      -a|--all)
        urls+=(gerrit jenkins deploy)
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "Internal error!" ;
        return 1
    esac
    shift
  done

  if [ -z "$urls" ]; then
    urls+=(gerrit jenkins deploy)
  fi

  for service in "$@"; do
    echo "$service --"
    for url in ${urls[@]}; do
      case "$url" in
        gerrit)
          echo "http://gerrit.sysop.520hello.com/#/admin/projects/$service"
          ;;
        deploy)
          echo "http://deploy.sysop.bigo.sg/jpack/version?search=$service&exact=0"
          ;;
        jenkins)
          echo "http://jenkins.sysop.bigo.sg/job/$service/"
          ;;
      esac
    done
  done
}

bigo__debug() {
  :
}

bigo__port() {
  #port, pid
  # sudo netstat -t -l -n -p | awk '/LISTEN/{n = split($4, a, ":"); m = split($7, b, "/"); print a[n]"\t"b[1]  }'
  local sn=${1?no service name}
  sn=${sn:0:15}
  sudo lsof -a -i -c ${sn} | grep LISTEN | sed  's,\*,http://'$(echo $SSH_CONNECTION | cut -f3 -d ' '),
}

bigo() {
  [ $# -eq 0 ] && echo "bigo <$(typeset -f | awk '/ \(\) \{?$/ && !/^main / {print $1}' | grep bigo__ | cut -c7- | paste -sd "\|")> -h" && return 0
  local cmdname=$1
  shift
  if type "bigo__$cmdname" > /dev/null 2>&1; then
    "bigo__$cmdname" "$@"
  else
    case "$cmdname" in
      debug)
        local service_path=$(find /data/services -maxdepth 1 -type d | egrep '/[a-z_]*-[0-9]+\.[0-9]+\.[0-9]+$' | fzf -1 -q "$*")
        [ -d $service_path ] && cp -r $service_path . && cd $(basename $service_path)/bin
        ;;
      conf)
        local bin_name service_path
        bin_name=$(service_name "$@")
        service_path=$(find /data/services -maxdepth 1 -type d | egrep '/[a-z_]*-[0-9]+\.[0-9]+\.[0-9]+$' | fzf -1 -q "$bin_name")
        if [ -d "$service_path" ]; then
          ls $service_path/conf/ | fzf -1 -q 
        fi
        ;;
    esac
  fi
}
