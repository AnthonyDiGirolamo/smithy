export SMITHY_PREFIX=/sw/tools/smithy
export SMITHY_CONFIG=$SMITHY_PREFIX/smithyrc
export MANPATH=$SMITHY_PREFIX/lib/app/man:$MANPATH

smithy () {
  echo "$@" | grep -q "module use"
  if [ "$?" -eq 0 ] ; then
    eval `$SMITHY_PREFIX/smithy $@`
  else
    $SMITHY_PREFIX/smithy $@
  fi
}

if [[ -n ${ZSH_VERSION-} ]]; then
  fpath=($SMITHY_PREFIX/lib/app/etc/completion/zsh $fpath)
  compinit -i
fi

if [[ -n ${BASH_VERSION-} ]]; then
  source $SMITHY_PREFIX/lib/app/etc/completion/smithy-completion.bash
fi

smithy reindex

