#!/bin/zsh 

export ZSH_PLUGINS_DIR=$DOTFILES/zsh-plugins/.plugins

for plugin in $ZSH_PLUGINS_DIR/**/*.plugin.zsh; do
  echo "Initialising $(echo $plugin | cut -d '/' -f 4-)"
  source $plugin
done
