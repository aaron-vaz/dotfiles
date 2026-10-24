#!/bin/sh

if test "$(whence skelly 2> /dev/null)"
then
  echo "\033[00;32m──›\033[0m updating skelly"
  UPGRADE_SKELLY=true $DOTFILES/skelly/install.sh
  echo
fi
