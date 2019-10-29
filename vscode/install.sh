#!/bin/sh
check_install () {
  if test "$(which code)"; then
    BINARY="code"
    if [ "$(uname -s)" = "Darwin" ]; then
      VSCODE_HOME="$HOME/Library/Application Support/Code"
    else
      VSCODE_HOME="$HOME/.config/Code"
    fi  
  elif test "$(which codium)"; then
    BINARY="codium"
    if [ "$(uname -s)" = "Darwin" ]; then
      VSCODE_HOME="$HOME/Library/Application Support/VSCodium"
    else
      VSCODE_HOME="$HOME/.config/VSCodium"
    fi
  fi    
}

check_install

if [ $BINARY != "" ]; then
  ln -sf "$DOTFILES/vscode/settings.json" "$VSCODE_HOME/User/settings.json"
  ln -sf "$DOTFILES/vscode/keybindings.json" "$VSCODE_HOME/User/keybindings.json"

  modules="
    HookyQR.beautify
    ms-azuretools.vscode-docker
    ms-vscode.go
    mattn.Runner
    ms-python.python
    vscode-icons-team.vscode-icons
    streetsidesoftware.code-spell-checker
  "
  for module in $modules; do
    "$BINARY" --install-extension "$module" || true
  done
fi
