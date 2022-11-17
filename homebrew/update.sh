#!/bin/sh

if test "$(whence brew 2> /dev/null)"
then
  echo "\033[00;32m──›\033[0m updating brew"
  brew update
  brew upgrade
  brew cleanup --prune=all
  echo
fi