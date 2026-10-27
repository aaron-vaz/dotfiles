#!/bin/sh

PYENV_ROOT=${PYENV_ROOT:-$HOME/.pyenv}

# pyenv.run installs pyenv with pyenv-virtualenv and pyenv-update, on macOS and Linux
# pyenv installed another way (e.g. Homebrew, pacman) is kept, not installed twice
if ! command -v pyenv > /dev/null 2>&1 && [ ! -d "$PYENV_ROOT" ]
then
  curl -fsSL https://pyenv.run | bash
fi

# pyenv installed another way (e.g. Homebrew) comes without pyenv-virtualenv
if [ ! -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]
then
  git clone --depth 1 https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_ROOT/plugins/pyenv-virtualenv"
fi
