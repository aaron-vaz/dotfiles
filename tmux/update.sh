#!/bin/sh

if test -d ~/.tmux/plugins/tpm
then
  echo "\033[00;32m──›\033[0m updating tpm"
  git -C ~/.tmux/plugins/tpm pull
  # tries to delete everything when TMUX_PLUGIN_MANAGER_PATH is unset https://github.com/tmux-plugins/tpm/issues/58
  #~/.tmux/plugins/tpm/bin/clean_plugins
  ~/.tmux/plugins/tpm/bin/update_plugins all
  echo
fi
