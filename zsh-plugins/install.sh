#!/bin/sh
install_plugin() {
  plugin=$1
  location=$2

  git clone --depth 1 https://github.com/$plugin.git $location/$plugin
}

plugin_dir=zsh-plugins/.plugins

plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-history-substring-search
  zsh-users/zsh-completions
  srijanshetty/zsh-pip-completion
)

mkdir $plugin_dir

# install plugins
for plugin in "${plugins[@]}"; do
  install_plugin $plugin $plugin_dir
done

# install prompt
sh -c "$(curl -fsSL https://starship.rs/install.sh)"
