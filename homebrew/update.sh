#!/bin/sh

# Updates what is already installed. It never installs anything new: new formulae and
# apps come from ./install (brew bundle), so a machine only gets what its owner chose.
if command -v brew > /dev/null 2>&1
then
  echo "\033[00;32m──›\033[0m updating brew"
  brew update
  brew upgrade
  brew cleanup --prune=all
  echo
fi
