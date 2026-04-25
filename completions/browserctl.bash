_browserctl() {
  local cur prev words cword
  _init_completion || return

  local all_cmds="run workflows describe record init open close pages goto fill click shot snap url eval watch pause resume inspect cookies set-cookie clear-cookies ping shutdown"

  # Find the real command, skipping --daemon <name> if present
  local cmd="" cmd_idx=1
  local i=1
  while [[ $i -lt ${#words[@]} ]]; do
    case "${words[$i]}" in
      --daemon)
        (( i += 2 ))
        (( cmd_idx += 2 ))
        ;;
      --version|-v|--help|-h)
        (( i++ ))
        ;;
      --*)
        (( i++ ))
        ;;
      *)
        cmd="${words[$i]}"
        cmd_idx=$i
        break
        ;;
    esac
  done

  if [[ $cword -le $cmd_idx ]]; then
    COMPREPLY=($(compgen -W "$all_cmds --daemon --version --help" -- "$cur"))
    return
  fi

  case $cmd in
    run)
      case $prev in
        --params) COMPREPLY=($(compgen -f -- "$cur")); return ;;
      esac
      if [[ $cur == -* ]]; then
        COMPREPLY=($(compgen -W "--params" -- "$cur"))
      else
        COMPREPLY=($(compgen -f -- "$cur"))
      fi
      ;;
    record)
      local subcmd="${words[$((cmd_idx + 1))]}"
      if [[ $cword -eq $((cmd_idx + 1)) ]]; then
        COMPREPLY=($(compgen -W "start stop status" -- "$cur"))
      elif [[ $subcmd == "stop" && $cur == -* ]]; then
        case $prev in
          --out|-o) COMPREPLY=($(compgen -f -- "$cur")); return ;;
        esac
        COMPREPLY=($(compgen -W "--out" -- "$cur"))
      fi
      ;;
    open)
      case $prev in
        --url|-u) return ;;
      esac
      [[ $cur == -* ]] && COMPREPLY=($(compgen -W "--url" -- "$cur"))
      ;;
    fill)
      case $prev in
        --ref|-r) return ;;
        --value|-V) return ;;
      esac
      [[ $cur == -* ]] && COMPREPLY=($(compgen -W "--ref --value" -- "$cur"))
      ;;
    click)
      case $prev in
        --ref|-r) return ;;
      esac
      [[ $cur == -* ]] && COMPREPLY=($(compgen -W "--ref" -- "$cur"))
      ;;
    shot)
      case $prev in
        --out|-o) COMPREPLY=($(compgen -f -- "$cur")); return ;;
      esac
      [[ $cur == -* ]] && COMPREPLY=($(compgen -W "--out --full" -- "$cur"))
      ;;
    snap)
      case $prev in
        --format|-f) COMPREPLY=($(compgen -W "ai html" -- "$cur")); return ;;
      esac
      [[ $cur == -* ]] && COMPREPLY=($(compgen -W "--format --diff" -- "$cur"))
      ;;
    watch)
      case $prev in
        --timeout|-t) return ;;
      esac
      [[ $cur == -* ]] && COMPREPLY=($(compgen -W "--timeout" -- "$cur"))
      ;;
  esac
}

complete -F _browserctl browserctl
