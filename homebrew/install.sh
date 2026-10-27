#!/bin/sh

if test "$(uname)" = "Darwin"
then
  if ! command -v brew > /dev/null 2>&1
  then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # a fresh install is not on PATH until the next shell
  for brew in /opt/homebrew/bin/brew /usr/local/bin/brew
  do
    if ! command -v brew > /dev/null 2>&1 && [ -x "$brew" ]
    then
      eval "$("$brew" shellenv)"
    fi
  done

  brew bundle --file="$DOTFILES/homebrew/Brewfile"
fi
