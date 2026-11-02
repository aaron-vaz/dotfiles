#!/bin/sh

# rustup itself comes from Homebrew (homebrew/Brewfile); this module only makes
# sure a toolchain is installed. Without rustup (no Homebrew) it does nothing.
for dir in /opt/homebrew/opt/rustup/bin /usr/local/opt/rustup/bin /home/linuxbrew/.linuxbrew/opt/rustup/bin
do
  if [ -d "$dir" ]
  then
    PATH="$dir:$PATH"
    break
  fi
done

if ! command -v rustup > /dev/null 2>&1
then
  echo "rustup not found, skipping rust (it is installed by the homebrew module)"
  exit 0
fi

# the keg ships rustup without a toolchain; "rustup default" installs and selects one
if ! rustup toolchain list 2> /dev/null | grep -q default
then
  rustup default stable
fi
