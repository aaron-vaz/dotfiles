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
  brew bundle check --file=$DOTFILES/Brewfile.mac
  brew bundle --file=$DOTFILES/Brewfile.mac
elif test "$(uname)" = "Linux"
then
  if test ! $(which ruby 2> /dev/null)
  then
    if test "$(which apt-get 2> /dev/null)"
    then
      sudo apt-get install ruby
    fi
    if test "$(which dnf 2> /dev/null)"
    then
      sudo dnf install ruby
    fi
  fi

  if test ! $(which brew 2> /dev/null)
  then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/linuxbrew/go/install)"
  fi

  echo "› brew update"
  brew update
  brew upgrade --all

  echo "› brew bundle"
  brew bundle check --file=$DOTFILES/Brewfile.linux
  brew bundle --file=$DOTFILES/Brewfile.linux
fi
