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

	IFS=$sep
	COMPREPLY=($(compgen -W "$list" -- "$cur"))
}

_smithy ()
{
  #echo "cur: $cur, prev: $prev" > /dev/pts/33

	local i=1 cmd

	# find the subcommand
	while [[ $i -lt $COMP_CWORD ]]; do
		local s="${COMP_WORDS[i]}"
		case "$s" in
    --*) ;;
		-*) ;;
		*) 	cmd="$s"
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
        --config-file=
        --disable-group-writable
        --file-group-name=
        --help
        --no-color
        --software-root="
        return
        ;;
      *)
        __smithycomp "
        build
        deploy
        help
        new
        search"
        return
        ;;
    esac
		return
	fi

	# subcommands have their own completion functions
	case "$cmd" in
	b|build)  _smithy_build  ;;
	s|search) _smithy_search ;;
	new)      _smithy_new    ;;
	help)     _smithy_help   ;;
	*)        ;;
	esac
}

__smithy_complete_packages ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local packages=$(smithy search --format=name ${cur})
	COMPREPLY=($(compgen -W "$packages" -- "$cur"))
}

_smithy_build () {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prv="${COMP_WORDS[COMP_CWORD-1]}"
  case "$prv" in
  --build-log-name=*)
    COMPREPLY=($(compgen -f "$cur"))
    return
    ;;
  esac
	case "$cur" in
	-*)
		__smithycomp "
      --build-log-name=
      --disable-build-log
      --dry-run
      --send-to-stdout"
		return
		;;
	esac
  __smithy_complete_packages
}

_smithy_search () {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prv="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prv" in
  --format=*)
    __smithycomp "path name table csv"
    return
    ;;
  esac
	case "$cur" in
	-*)
		__smithycomp "--format="
		return
		;;
	esac
}

_smithy_new () {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prv="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prv" in
  --tarball=*)
    COMPREPLY=($(compgen -f "$cur"))
    return
    ;;
  esac
	case "$cur" in
	-*)
		__smithycomp "
      --dry-run
      --tarball=
      --web-description"
		return
		;;
	esac
}

_smithy_help () {
  __smithycomp "build search new"
}

complete -F _smithy smithy
