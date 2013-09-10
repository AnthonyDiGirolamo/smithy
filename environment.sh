module load ruby/1.9.3-p448
module use /sw/tools/smithy/modulefiles
module load smithy

smithy () {
  echo "$@" | grep -q "module use"
  if [ "$?" -eq 0 ] ; then
    eval `/sw/tools/smithy/bin/smithy $@`
  else
    /sw/tools/smithy/bin/smithy $@
  fi
}

if [[ -n ${ZSH_VERSION-} ]]; then
  fpath=(/sw/tools/smithy/gems/software_smithy-1.6.2/etc/completion/zsh $fpath)
  compinit
fi

if [[ -n ${BASH_VERSION-} ]]; then
  source /sw/tools/smithy/gems/software_smithy-1.6.2/etc/completion/smithy-completion.bash
fi

smithy reindex

