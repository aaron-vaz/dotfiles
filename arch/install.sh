#!/bin/zsh

if test "$(whence pacman 2> /dev/null)"
then
  sudo pacman -S --noconfirm - < $DOTFILES/arch/arch_headless_packages
  
  # if in a ui environment install the ui packages
  if test $DISPLAY
  then
    sudo pacman -S --noconfirm - < $DOTFILES/arch/arch_packages
  fi
fi
