#!/bin/sh

# This script unfortunately reinstalls all packages, due to apm not currently providing adequate package management options.

if test "$(which apm 2> /dev/null)"
then
  rm -R ~/.atom/packages/*
  apm install --packages-file ~/.dotfiles/atom/package-list.txt
fi
