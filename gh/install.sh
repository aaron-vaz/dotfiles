#!/bin/sh

# Installs gh from the package manager, which then keeps it up to date
install_gh() {
  if command -v brew > /dev/null 2>&1
  then
    brew install gh
  elif command -v pacman > /dev/null 2>&1
  then
    sudo pacman -S --noconfirm github-cli
  elif command -v dnf > /dev/null 2>&1
  then
    sudo dnf install -y gh
  elif command -v apt-get > /dev/null 2>&1
  then
    # https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    keyring=/etc/apt/keyrings/githubcli-archive-keyring.gpg
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee "$keyring" > /dev/null
    sudo chmod go+r "$keyring"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
  else
    # skip rather than fail, so ./install goes on with the other modules
    echo "no supported package manager found, install gh from https://cli.github.com" >&2
    exit 0
  fi
}

if ! command -v gh > /dev/null 2>&1
then
  install_gh
fi

# Extensions are downloaded through the GitHub API, so gh has to be logged in
if gh auth status > /dev/null 2>&1
then
  if ! gh extension list | grep -q 'github/gh-stack'
  then
    gh extension install github/gh-stack
  fi
else
  echo "gh is not logged in, run gh auth login and then dot to install gh-stack"
fi
