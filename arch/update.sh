#!/bin/sh
pacman -Qqet | grep -v "$(pacman -Qqg base)" | grep -v "$(pacman -Qqm)" > arch_packages # community
pacman -Qqm > aur_packages # aur