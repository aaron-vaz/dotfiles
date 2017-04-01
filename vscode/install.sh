#!/bin/sh
if test "$(which code)"; then
  if [ "$(uname -s)" = "Darwin" ]; then
    VSCODE_HOME="$HOME/Library/Application Support/Code"
  else
    VSCODE_HOME="$HOME/.config/Code"
  fi

  ln -sf "$DOTFILES/vscode/settings.json" "$VSCODE_HOME/User/settings.json"
  ln -sf "$DOTFILES/vscode/keybindings.json" "$VSCODE_HOME/User/keybindings.json"

  modules="
    PeterJausovec.vscode-docker
    donjayamanne.python
    gerane.Theme-Dark-Dracula
    lukehoban.Go
    mattn.Runner
    robertohuertasm.vscode-icons
    seanmcbreen.Spell
  "
  for module in $modules; do
    code --install-extension "$module" || true
  done
fi
