#!/bin/sh

# Updates the toolchains. rustup itself is upgraded by "brew upgrade" in the homebrew module.
if command -v rustup > /dev/null 2>&1
then
  echo "\033[00;32m──›\033[0m updating rust toolchains"
  rustup update || echo "rustup update failed" >&2
  echo
fi
