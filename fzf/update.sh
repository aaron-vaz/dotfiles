#!/bin/sh

if command -v fzf > /dev/null 2>&1
then
  echo "\033[00;32m──›\033[0m updating fzf"
  if ! git -C ~/.fzf pull | grep -q "Already up.to.date"
  then
    ~/.fzf/install --all --no-update-rc
  fi
  echo
fi