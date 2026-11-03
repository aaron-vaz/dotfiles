#!/bin/sh

# Only the fzf this repo cloned into ~/.fzf; one from a package manager is updated by that
if [ -d "$HOME/.fzf/.git" ]
then
  echo "\033[00;32m──›\033[0m updating fzf"
  if ! git -C "$HOME/.fzf" pull | grep -q "Already up.to.date"
  then
    "$HOME/.fzf/install" --all --no-update-rc
  fi
  echo
fi
