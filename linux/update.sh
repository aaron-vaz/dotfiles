#!/bin/sh

if test "$(uname)" = "Linux"
then
  if test "$(whence apt-get 2> /dev/null)"
  then
    echo "\033[00;32m──›\033[0m updating apt-get"
    sudo apt-get update
    set +e
    sudo apt-get dist-upgrade
    sudo apt-get autoremove
    set -e
    sudo apt-get clean
    echo
  elif test "$(whence dnf 2> /dev/null)"
  then
    echo "\033[00;32m──›\033[0m updating dnf"
    sudo dnf clean all
    set +e
    sudo dnf update
    sudo dnf autoremove
    set -e
    sudo dnf clean all
    echo
  elif test "$(whence yay 2> /dev/null)"
  then
    echo "\033[00;32m──›\033[0m updating aur"
    yay -Syu
    set +e
    yay -Rns $(yay -Qtdq)
    set -e
    echo
  elif test "$(whence pacman 2> /dev/null)"
  then
    echo "\033[00;32m──›\033[0m updating pacman"
    sudo pacman -Syu
    set +e
    sudo pacman -Rns $(pacman -Qtdq)
    set -e
    echo
  fi
fi