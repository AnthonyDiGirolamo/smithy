#compdef smithy

_smithy_all_formulae() {
	formulae=(`smithy search`) # FIXME _call_program should be used here
}

_smithy_installed_formulae() {
	installed_formulae=(`smithy list`) # FIXME _call_program should be used here
}

local -a _1st_arguments
_1st_arguments=(
	'new:create a new software build'
	'build:build an existing package'
	'search:search existing packages'
)

local expl
local -a formulae installed_formulae

_arguments \
	'(-v)-v[verbose]' \
	'(--cellar)--cellar[smithy cellar]' \
	'(--config)--config[smithy configuration]' \
	'(--env)--env[smithy environment]' \
	'(--repository)--repository[smithy repository]' \
	'(--version)--version[version information]' \
	'(--prefix)--prefix[where smithy lives on this system]' \
	'(--cache)--cache[smithy cache]' \
	'*:: :->subcmds' && return 0

if (( CURRENT == 1 )); then
	_describe -t commands "smithy subcommand" _1st_arguments
	return
fi

case "$words[1]" in
	search|-S)
		_arguments \
			'(--macports)--macports[search the macports repository]' \
			'(--fink)--fink[search the fink repository]' ;;
	list|ls)
		_arguments \
			'(--unsmithyed)--unsmithyed[files in smithy --prefix not controlled by smithy]' \
			'(--versions)--versions[list all installed versions of a formula]' \
			'1: :->forms' &&  return 0

			if [[ "$state" == forms ]]; then
				_smithy_installed_formulae
				_wanted installed_formulae expl 'installed formulae' compadd -a installed_formulae
			fi ;;
	install|home|homepage|log|info|abv|uses|cat|deps|edit|options)
		_smithy_all_formulae
		_wanted formulae expl 'all formulae' compadd -a formulae ;;
	remove|rm|uninstall|unlink|cleanup|link|ln)
		_smithy_installed_formulae
		_wanted installed_formulae expl 'installed formulae' compadd -a installed_formulae ;;
esac
