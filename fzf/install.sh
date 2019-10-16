#!/bin/sh

if test !["$(which fzf 2> /dev/null)"]
then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all --no-update-rc
fi
