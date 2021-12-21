#!/bin/sh

link_dir=~/.config/terminator

mkdir -p $link_dir
ln -sf $DOTFILES/terminator/terminator.conf.symlink $link_dir/config