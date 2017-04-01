#!/bin/zsh

if test "$(whence pacman 2> /dev/null)"
then
  sudo pacman -S - < $DOTFILES/arch/ArchPackages
fi
