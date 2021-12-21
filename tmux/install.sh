#!/bin/sh

if test ! -d ~/.tmux/plugins/tpm
then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if test ! $(which tmux 2> /dev/null)
  ~/.tmux/plugins/tpm/bin/install_plugins

  # symlinks
  ln -sf tmux/tmux.conf.symlink ~/.tmux.conf
fi

