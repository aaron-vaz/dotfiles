#!/bin/sh

# Upgrades jabba when it is installed; it never installs it (or a JDK) on a machine without it
if [ -d "$HOME/.jabba" ]
then
  echo "\033[00;32m──›\033[0m updating jabba"
  curl -fsSL https://github.com/Jabba-Team/jabba/raw/main/install.sh | bash -s -- --skip-rc
  echo
fi
