#!/bin/sh

if test -d $ZSH_PLUGINS_DIR
then
  echo "\033[00;32m──›\033[0m updating ZSH plugins"
  for plugin in $ZSH_PLUGINS_DIR/**/.git; do
      echo $(dirname $plugin)
      git -C $plugin/.. pull
      echo
  done
fi