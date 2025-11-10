#!/usr/bin/env bash
touch $HOME/Library/Application\ Support/com.mitchellh.ghostty/config

# Symlink the config file
ln -sf $DOTFILES/ghostty/config.symlink $HOME/Library/Application\ Support/com.mitchellh.ghostty/config