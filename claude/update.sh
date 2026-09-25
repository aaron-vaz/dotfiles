#!/bin/sh

if test "$(whence claude 2> /dev/null)"
then
  echo "\033[00;32m──›\033[0m updating claude"
  claude update
  echo
fi
