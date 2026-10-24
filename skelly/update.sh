#!/bin/sh

if command -v skelly > /dev/null 2>&1
then
  echo "\033[00;32m──›\033[0m updating skelly"
  UPGRADE_SKELLY=true $DOTFILES/skelly/install.sh
  echo
fi
