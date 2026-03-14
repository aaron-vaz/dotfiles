#!/usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

set -e

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

info 'setting up opencode config directory'
mkdir -p ~/.config/opencode

info 'symlinking opencode configuration'

if [ -f "$DOTFILES_ROOT/opencode/.opencode/AGENTS.md" ]; then
  ln -sf "$DOTFILES_ROOT/opencode/.opencode/AGENTS.md" ~/.config/opencode/AGENTS.md
  success 'AGENTS.md symlinked'
fi

if [ -f "$DOTFILES_ROOT/opencode/.opencode/settings.json" ]; then
  ln -sf "$DOTFILES_ROOT/opencode/.opencode/settings.json" ~/.config/opencode/settings.json
  success 'settings.json symlinked'
fi

if [ -f "$DOTFILES_ROOT/opencode/.opencode/opencode.json" ]; then
  ln -sf "$DOTFILES_ROOT/opencode/.opencode/opencode.json" ~/.config/opencode/opencode.json
  success 'opencode.json symlinked'
fi

success 'opencode configuration installed'
