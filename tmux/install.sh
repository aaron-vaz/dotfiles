#!/bin/sh

if test ! -d ~/.tmux/plugins/tpm
then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# tries to delete everything when TMUX_PLUGIN_MANAGER_PATH is unset https://github.com/tmux-plugins/tpm/issues/58
#~/.tmux/plugins/tpm/bin/clean_plugins
~/.tmux/plugins/tpm/bin/install_plugins
~/.tmux/plugins/tpm/bin/update_plugins all
