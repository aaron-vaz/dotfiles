#!/bin/sh

if command -v pacman > /dev/null 2>&1
then
  sudo pacman -S --noconfirm - < $DOTFILES/arch/arch_headless_packages
  
  # if in a ui environment install the ui packages
  if test -n "$DISPLAY"
  then
    sudo pacman -S --noconfirm - < $DOTFILES/arch/arch_packages
  fi
fi
