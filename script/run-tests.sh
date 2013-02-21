#!/bin/sh

if [ ! -p test_commands ] ; then
  mkfifo test_commands
fi

while true; do
  sh -c "$(cat test_commands)"
done

