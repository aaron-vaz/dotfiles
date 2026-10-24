#!/usr/bin/env bash

# Ghostty keeps its config under Application Support on macOS only
[ "$(uname)" = "Darwin" ] || exit 0

config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$config_dir"

# Symlink the config file
ln -sf "$DOTFILES/ghostty/config.symlink" "$config_dir/config"
