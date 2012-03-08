#compdef smithy

_smithy_packages() {
	packages=(`smithy search --format=name`)
}

local -a _1st_arguments
_1st_arguments=(
	'build:Build software'
  'deploy:Deploy a package'
  'edit:Edit package support files'
  'help:Shows list of commands or help for one command'
	'new:Generate a new build and all necessary files'
	'repair:Repair a package'
	'search:Search currently installed software'
)

local expl
local -a formulae

_arguments \
  '(--arch=)--arch=[Machine architecture to operate on]' \
  '(--config-file=)--config-file=[Alternate config file]:file:_files' \
  '(--disable-group-writeable)--disable-group-writeable[Disable group writable file creation]' \
  '(--help)--help[Show help]' \
  '(--no-color)--no-color[Hide coloring]' \
  '(--software-root=)--software-root=[The root level directory for software]:directory:_files -/' \
  '*:: :->subcmds' && return 0
#[[ "$PREFIX" = --* ]] && _arguments -- \
  #'*=FILE*:file:_files' \
  #'*=PATH*:directory:_files -/' \
  #'*=NAME*:directory:_files -/' && return 0

# Match Sub-command
if (( CURRENT == 1 )); then
	_describe -t commands "smithy subcommand" _1st_arguments
	return
fi

# completion for each sub command
case "$words[1]" in
  help)
    _describe -t commands "smithy subcommand" _1st_arguments ;;
  build)
    _arguments \
      '(--build-log-name=)--build-log-name=[Build log file name located within the software prefix]:file:_files' \
'(--disable-build-log)--disable-build-log[Disable build logging]' \
'(-n)--dry-run[See what packages will be built but without building them]' \
'(--dry-run)-n[See what packages will be built but without building them]' \
'(-s)--send-to-stdout[Send messages from underlying commands (configure, make, etc) to STDOUT.]' \
'(--send-to-stdout)-s[Send messages from underlying commands (configure, make, etc) to STDOUT.]' \
      '1: :->forms' &&  return 0

    if [[ "$state" == forms ]]; then
      _smithy_packages
      _wanted packages expl 'packages' compadd -a packages
    fi ;;
  edit)
    _arguments \
      '(--build)--build[Edit a build script]' \
      '(--editor=)--editor=[Editor for opening script files]' \
      '(--test)--test[Edit a test script]' \
      '(--compile-time-modules)--compile-time-modules[Edit modules loaded for the build script]' \
      '1: :->forms' &&  return 0

    if [[ "$state" == forms ]]; then
      _smithy_packages
      _wanted packages expl 'packages' compadd -a packages
    fi ;;
  new)
    _arguments \
      '(--web-description)--web-description[Create description file for website]' \
      '(-n --dry-run)'{-n,--dry-run}'[See what files will be created without creating them]' \
      '(-t --tarball=)'{-t,--tarball=}'[Provide a source tarball to unpack (optional)]:file:_files' ;;
  repair)
    _arguments \
      '(-n --dry-run)'{-n,--dry-run}'[Verify permissions only]' \
      '1: :->forms' &&  return 0

    if [[ "$state" == forms ]]; then
      _smithy_packages
      _wanted packages expl 'packages' compadd -a packages
    fi ;;
  search)
    _arguments \
      '(--format=)--format=[Format of the output]:format:(path name table csv)' ;;
esac
