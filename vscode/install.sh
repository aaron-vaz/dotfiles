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
    bungcip.better-toml
    dbaeumer.vscode-eslint
    eamodio.gitlens
    esbenp.prettier-vscode
    golang.go
    hashicorp.terraform
    haskell.haskell
    justusadam.language-haskell
    ms-azuretools.vscode-docker
    ms-kubernetes-tools.vscode-kubernetes-tools
    ms-python.python
    ms-python.vscode-pylance
    ms-toolsai.jupyter
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-vscode-remote.remote-containers
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode.makefile-tools
    redhat.vscode-yaml
    rust-lang.rust-analyzer
    streetsidesoftware.code-spell-checker
    vscode-icons-team.vscode-icons
    yzhang.markdown-all-in-one
    zhuangtongfa.material-theme
  "
  for module in $modules; do
    "$BINARY" --install-extension "$module" || true
  done
fi
