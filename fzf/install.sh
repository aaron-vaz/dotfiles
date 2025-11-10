#!/bin/sh

if test ! -d ~/.fzf
then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all --no-update-rc
fi

if test ! -d ~/.fzf/git
then
   git clone --depth 1 https://github.com/junegunn/fzf-git.sh.git ~/.fzf/git
fi
