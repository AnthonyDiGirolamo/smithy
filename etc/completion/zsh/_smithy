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
  'module:Manage modulefiles for a package'
	'new:Generate a new build and all necessary files'
	'repair:Repair a package'
	'search:Search currently installed software'
	'test:Test software'
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
  '(--web-root=)--web-root=[The root level directory for web files]:directory:_files -/' \
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
  build|test)
    _arguments \
      '(--disable-log)--disable-log[Disable logging]' \
      '(-f --force)'{-f,--force}'[Ignore .lock file and run anyway]' \
      '(--log-name=)--log-name=[Log file name located within the software prefix]:file:_files' \
      '(-n --dry-run)'{-n,--dry-run}'[See what scripts will be run without running them]' \
      '(-s --send-to-stdout)'{-s,--send-to-stdout}'[Send messages from scripts to STDOUT.]' \
      '1: :->forms' &&  return 0

    if [[ "$state" == forms ]]; then
      _smithy_packages
      _wanted packages expl 'packages' compadd -a packages
    fi ;;
  deploy)
    _arguments \
      '(-n --dry-run)'{-n,--dry-run}'[See what files will be created without creating them]' \
      '1: :->forms' &&  return 0

    if [[ "$state" == forms ]]; then
      _smithy_packages
      _wanted packages expl 'packages' compadd -a packages
    fi ;;
  edit)
    _subsub_commands=(
      'build:Edit a build script'
      'test:Edit a test script'
      'modules:Edit modules loaded for the build script'
      'modulefile:Edit modules loaded for the build script'
    )
    # Match subsub-command
    if (( CURRENT == 2 )); then
      _describe -t subcommands "edit subcommand" _subsub_commands
      return
    fi

    _arguments \
      '(--editor=)--editor=[Editor for opening script files]:file:_files' \
      '2: :->forms' &&  return 0

    if [[ "$state" == forms ]]; then
      _smithy_packages
      _wanted packages expl 'packages' compadd -a packages
    fi ;;
  module)
    _subsub_commands=(
      'create:Generate a modulefile for a given package'
      'use:Add a modulefile to the MODULEPATH'
      'deploy:Copy a modulefile to the system MODULEPATH'
    )
    # Match subsub-command
    if (( CURRENT == 2 )); then
      _describe -t subcommands "edit subcommand" _subsub_commands
      return
    fi

    _arguments \
      '(-n --dry-run)'{-n,--dry-run}'[See what files will be created without creating them]' \
      '2: :->forms' &&  return 0

    if [[ "$state" == forms ]]; then
      _smithy_packages
      _wanted packages expl 'packages' compadd -a packages
    fi ;;
  new)
    _arguments \
      '(--skip-modulefile)--skip-modulefile[Skip modulefile generation]' \
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
