#!/bin/sh

if test "$(whence fzf 2> /dev/null)"
then
  echo "\033[00;32m──›\033[0m updating fzf"
  if test "$(git -C ~/.fzf pull)" != "Already up-to-date."
  then
    ~/.fzf/install --all --no-update-rc
  fi
  echo
fi