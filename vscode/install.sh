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
    dbaeumer.vscode-eslint
    eamodio.gitlens
    esbenp.prettier-vscode
    github.github-vscode-theme
    golang.go
    hashicorp.terraform
    haskell.haskell
    justusadam.language-haskell
    ms-azuretools.vscode-docker
    ms-kubernetes-tools.vscode-kubernetes-tools
    ms-python.debugpy
    ms-python.isort
    ms-python.python
    ms-python.vscode-pylance
    ms-toolsai.jupyter
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow
    ms-vscode-remote.remote-containers
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode.makefile-tools
    ms-vscode.remote-explorer
    pkief.material-icon-theme
    redhat.vscode-yaml
    rust-lang.rust-analyzer
    streetsidesoftware.code-spell-checker
    tamasfe.even-better-toml
    yzhang.markdown-all-in-one
  "
  for module in $modules; do
    "$BINARY" --install-extension "$module" || true
  done
fi
