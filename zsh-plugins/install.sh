#!/bin/sh
install_plugin() {
  plugin=$1
  location=$2

  git clone --depth 1 https://github.com/$plugin.git $location/$plugin
}

plugin_dir=zsh-plugins/.plugins

plugins=(
  hlissner/zsh-autopair
  srijanshetty/zsh-pip-completion
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  zsh-users/zsh-history-substring-search
  zsh-users/zsh-syntax-highlighting
)

mkdir $plugin_dir

# install plugins
for plugin in "${plugins[@]}"; do
  echo ""
  echo "\033[00;32m──›\033[0m installing $plugin"
  echo ""
  
  install_plugin $plugin $plugin_dir
done

# install prompt
echo ""
echo "\033[00;32m──›\033[0m installing Starship prompt"
echo ""

sh -c "$(curl -fsSL https://starship.rs/install.sh)"
