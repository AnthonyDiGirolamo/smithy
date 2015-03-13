if [[ -n ${ZSH_VERSION-} ]]; then
  autoload -U +X bashcompinit && bashcompinit
fi

__smithycomp_words_include ()
{
  local i=1
  while [[ $i -lt $COMP_CWORD ]]; do
    if [[ "${COMP_WORDS[i]}" = "$1" ]]; then
      return 0
    fi
    i=$((++i))
  done
  return 1
}

# Find the previous non-switch word
__smithycomp_prev ()
{
  local idx=$((COMP_CWORD - 1))
  local prv="${COMP_WORDS[idx]}"
  while [[ $prv == -* ]]; do
    idx=$((--idx))
    prv="${COMP_WORDS[idx]}"
  done
}


__smithycomp ()
{
  # break $1 on space, tab, and newline characters,
  # and turn it into a newline separated list of words
  local list s sep=$'\n' IFS=$' '$'\t'$'\n'
  local cur="${COMP_WORDS[COMP_CWORD]}"

  for s in $1; do
    __smithycomp_words_include "$s" && continue
    list="$list$s$sep"
  done

  case "$cur" in
  --*=)
    COMPREPLY=()
    ;;
  *)
    IFS=$sep
    COMPREPLY=( $(compgen -W "$list" -- "$cur" | sed -e 's/[^=]$/& /g') )
    ;;
  esac
}

_smithy ()
{
  #echo "cur: $cur, prev: $prev" > /dev/pts/33

  local i=1 cmd

  if [[ -n ${ZSH_VERSION-} ]]; then
    emulate -L bash
    setopt KSH_TYPESET

    # workaround zsh's bug that leaves 'words' as a special
    # variable in versions < 4.3.12
    typeset -h words
  fi

  # find the subcommand
  while [[ $i -lt $COMP_CWORD ]]; do
    local s="${COMP_WORDS[i]}"
    case "$s" in
    --*) ;;
    -*) ;;
    *)  cmd="$s"
      break
      ;;
    esac
    i=$((++i))
  done

  if [[ $i -eq $COMP_CWORD ]]; then
    local cur="${COMP_WORDS[COMP_CWORD]}"
    case "$cur" in
      -*)
        __smithycomp "
        --arch=
        --no-colors
        --colors
        --config-file=
        --descriptions-root=
        --disable-group-writable
        --force
        --file-group-name=
        --help
        --prgenv-prefix=
        --software-root=
        --verbose
        --web-root="
        return
        ;;
      *)
        __smithycomp "
        build
        clean
        edit
        formula
        help
        module
        new
        publish
        repair
        search
        show
        test"
        return
        ;;
    esac
    return
  fi

  # subcommands have their own completion functions
  case "$cmd" in
  build|test)    _smithy_build  ;;
  clean)         _smithy_clean  ;;
  edit)          _smithy_edit   ;;
  formula)       _smithy_formula ;;
  help)          _smithy_help   ;;
  module)        _smithy_module ;;
  new)           _smithy_new    ;;
  publish)       _smithy_publish ;;
  repair)        _smithy_repair ;;
  search)        _smithy_search ;;
  show)          _smithy_show   ;;
  *)        ;;
  esac
}

__smithy_complete_packages ()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local cache_file=$HOME/.smithy/completion_packages
  if [[ -e $cache_file ]]
  then
    local packages=$(cat $cache_file)
  else
    local packages=$(smithy search --format=name ${cur})
  fi
  COMPREPLY=($(compgen -W "$packages" -- "$cur"))
}

__smithy_complete_formulas ()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local cache_file=$HOME/.smithy/completion_formulas
  if [[ -e $cache_file ]]
  then
    local packages=$(cat $cache_file)
  else
    local packages=$(smithy formula list ${cur})
  fi
  COMPREPLY=($(compgen -W "$packages" -- "$cur"))
}

_smithy_build () {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prv="${COMP_WORDS[COMP_CWORD-1]}"
  case "$cur" in
  --log-name=*)
    local t=`echo "$cur" | sed -e 's/--log-name=//g'`
    COMPREPLY=($(compgen -f "$t"))
    return
    ;;
  -*)
    __smithycomp "
      --disable-log
      --force
      --log-name=
      --dry-run
      --suppress-stdout"
    return
    ;;
  esac
  __smithy_complete_packages
}

_smithy_publish () {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prv="${COMP_WORDS[COMP_CWORD-1]}"
  case "$cur" in
  -*)
    __smithycomp "
      --dry-run"
    return
    ;;
  esac
  __smithy_complete_packages
}

_smithy_module () {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prv="${COMP_WORDS[COMP_CWORD-1]}"
  case "$prv" in
  module)
    __smithycomp "create deploy edit use"
    return
    ;;
  esac
  case "$cur" in
  -*)

    __smithycomp "
      --dry-run"
    return
    ;;
  esac
  __smithy_complete_packages
}

_smithy_edit () {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prv="${COMP_WORDS[COMP_CWORD-1]}"
  case "$prv" in
  edit)
    __smithycomp "build test env modulefile"
    return
    ;;
  -e)
    COMPREPLY=($(compgen -c "$cur"))
    return
    ;;
  esac
  case "$cur" in
  --editor=*)
    local t=`echo "$cur" | sed -e 's/--editor=//g'`
    COMPREPLY=($(compgen -c "$t"))
    return
    ;;
  -*)
    __smithycomp "
      --split
      --editor="
    return
    ;;
  esac
  __smithy_complete_packages
}

_smithy_clean () {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prv="${COMP_WORDS[COMP_CWORD-1]}"
  case "$prv" in
  clean)
    __smithycomp "build"
    return
    ;;
  esac
  __smithy_complete_packages
}

_smithy_formula () {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prv="${COMP_WORDS[COMP_CWORD-1]}"
  case "$prv" in
  formula)
    case "$cur" in
    --directories=*)
      local t=`echo "$cur" | sed -e 's/--directories=//g'`
      COMPREPLY=($(compgen -f "$t"))
      return
      ;;
    -*)
      __smithycomp "
        --directories="
      return
      ;;
    esac
    __smithycomp "create_modulefile display install list new which"
    return
    ;;
  new)
    case "$cur" in
    -*)
      __smithycomp "
        --name=
        --homepage="
      return
      ;;
    esac
    return
    ;;
  install)
    case "$cur" in
    -*)
      __smithycomp "
        --no-clean
        --clean
        --formula-name=
        --modulefile"
      return
      ;;
    esac
    __smithy_complete_formulas
    return
    ;;
  create_modulefile)
    case "$cur" in
    -*)
      __smithycomp "
        --formula-name="
      return
      ;;
    esac
    __smithy_complete_formulas
    return
    ;;
  -d)
    COMPREPLY=($(compgen -f "$cur"))
    return
    ;;
  esac
}

_smithy_search () {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prv="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prv" in
  --format=*)
    __smithycomp "path name table csv dokuwiki"
    return
    ;;
  esac
  case "$cur" in
  -*)
    __smithycomp "--format="
    return
    ;;
  esac
  __smithy_complete_packages
}

_smithy_new () {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prv="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prv" in
  -t)
    COMPREPLY=($(compgen -f "$cur"))
    return
    ;;
  esac
  case "$cur" in
  --tarball=*)
    local t=`echo "$cur" | sed -e 's/--tarball=//g'`
    COMPREPLY=($(compgen -f "$t"))
    return
    ;;
  -*)
    __smithycomp "
      --existing-scripts=
      --dry-run
      --tarball=
      --web-description
      --skip-modulefile"
    return
    ;;
  esac
  __smithy_complete_packages
}

_smithy_help () {
  __smithycomp "build edit formula help module new publish repair search show test"
}

_smithy_show () {
  __smithycomp "arch example_config last"
}

_smithy_repair () {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  case "$cur" in
  -*)
    __smithycomp "
      --dry-run"
    return
    ;;
  esac
  __smithy_complete_packages
}

complete -o bashdefault -o default -o nospace -F _smithy smithy
