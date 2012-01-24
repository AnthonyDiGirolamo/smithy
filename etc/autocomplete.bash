complete -F get_smith_targets smith
function get_smith_targets()
{
  if [ -z $2 ] ; then
    COMPREPLY=(`smith help -c`)
  else
    COMPREPLY=(`smith help -c $2`)
  fi
}
