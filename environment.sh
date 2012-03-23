module load ruby
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
