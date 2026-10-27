#!/bin/sh

if command -v brew > /dev/null 2>&1
then
  echo "\033[00;32m──›\033[0m updating brew"
  brew update
  # installs whatever was added to the Brewfile since the last run; its casks are macOS only
  if test "$(uname)" = "Darwin"
  then
    brew bundle --file="$DOTFILES/homebrew/Brewfile"
  fi
  brew upgrade
  brew cleanup --prune=all
  echo
fi