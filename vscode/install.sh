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
    HookyQR.beautify
    PeterJausovec.vscode-docker
    lukehoban.Go
    mattn.Runner
    ms-python.python
    robertohuertasm.vscode-icons
    streetsidesoftware.code-spell-checker
    zhuangtongfa.Material-theme
  "
  for module in $modules; do
    code --install-extension "$module" || true
  done
fi
