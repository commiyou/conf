_bigo() {
  local cur prev opts base subcmds subcmd
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  subcmd="${COMP_WORDS[1]}"


  case "${prev}" in
    -s|--service)
      COMPREPLY=( $(compgen -W "$(bigo__service -m -c -g -n)" -- ${cur}) )
      return 0
      ;;
  esac

  local i offset service 
  if [[ $COMP_CWORD -gt 2 ]]; then
    local args=${COMP_WORDS[@]:2}
    # print -- ${args[*]}
    local tmp=($(getopt -q -o "s:" -l "service:" -- ${args[*]}))
    # print -- ${tmp[@]}
    for ((i = 0; i < ${#tmp[@]}; i++)); do
      case ${tmp[i]} in
        -s|--service)
          service=${tmp[i+1]}
          ;;
      esac
    done
  fi

  [ -n "$service" ] || service=$(bigo__service -c)

  case "${subcmd}" in
    build)
      COMPREPLY=( "-f" )
      return 0
      ;;
    conf)
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W '-l --list -s --service -e --edit' -- "$cur"))
      else
        COMPREPLY=($(compgen -W "$(bigo__conf -s $service -V)" -- "$cur"))
      fi
      return 0
      ;;
    log)
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W '-l --list -s --service -e --edit -t --tail ' -- "$cur"))
      else
        COMPREPLY=($(compgen -W "$(bigo__log -s $service -V)" -- "$cur"))
      fi
      return 0
      ;;
    url)
      COMPREPLY=( $(compgen -W "-d --deploy -g --gerrit -j --jenkins -a --all" -- ${cur}) )
      return 0
      ;;
  esac

  subcmds=$(typeset -f | awk '/ \(\) \{?$/ && !/^main / {print $1}' | grep bigo__ | cut -c7-)
  # print $subcmds
  COMPREPLY=($(compgen -W "${subcmds}" -- ${cur}))  
  return 0
}

complete -F _bigo bigo
