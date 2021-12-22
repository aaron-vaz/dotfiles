#!/bin/zsh 

for plugin in zsh-plugins/.plugins/**/*.plugin.zsh; do
  echo "Initialising $(echo $plugin | cut -d '/' -f 4-)"
  source $plugin
done