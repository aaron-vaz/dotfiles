#!/bin/sh

if test "$(uname)" = "Darwin"
then
  if test ! $(which brew 2> /dev/null)
  then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi
