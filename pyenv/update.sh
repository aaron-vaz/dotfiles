#!/bin/sh

if command -v pyenv > /dev/null 2>&1
then
  echo "\033[00;32m──›\033[0m updating pyenv"
  # pyenv update comes from the pyenv-update plugin, which pyenv.run installs
  if [ -d "$(pyenv root)/plugins/pyenv-update" ]
  then
    pyenv update
  elif [ -d "$(pyenv root)/plugins/pyenv-virtualenv/.git" ]
  then
    git -C "$(pyenv root)/plugins/pyenv-virtualenv" pull
  fi
  echo
fi
