_smith_completion() {
  if [ -z $2 ] ; then
    reply=(`bundle exec smith help -c`)
  else
    reply=(`bundle exec smith help -c $2`)
  fi
}
compctl -K _smith_completion bundle exec smith

_smith_search_completion() {
  reply=(`bundle exec smith search --format=name $@`)
}
compctl -K _smith_search_completion bundle exec smith search
