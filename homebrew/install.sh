#!/bin/sh

if test "$(uname)" = "Darwin"
then
  if test ! $(which brew 2> /dev/null)
  then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  echo "› brew update"
  brew update
  brew upgrade --all

  echo "› brew bundle"
  brew bundle check --file=$DOTFILES/Brewfile
  brew bundle --file=$DOTFILES/Brewfile
fi
