#!/bin/zsh

if test "$(whence pacman 2> /dev/null)"
then
  sudo pacman -S --noconfirm - < $DOTFILES/arch/ArchPackages
fi
