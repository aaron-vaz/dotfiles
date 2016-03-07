#!/bin/sh

if test ! -d ~/.tmux/plugins/tpm
then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

~/.tmux/plugins/tpm/bin/install_plugins
