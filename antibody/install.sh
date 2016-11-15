#!/bin/sh
if which brew >/dev/null 2>&1; then
  brew untap -q getantibody/homebrew-antibody || true
  brew tap -q getantibody/homebrew-antibody
  brew install antibody
else
  curl -sL https://git.io/vwMNi | sh -s
fi

antibody bundle < "$DOTFILES/antibody/bundles" > ~/.antibody_bundles
antibody bundle sindresorhus/pure >> ~/.antibody_bundles
antibody bundle < "$DOTFILES/antibody/last_bundles" >> ~/.antibody_bundles
