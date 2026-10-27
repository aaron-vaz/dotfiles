#!/usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES_ROOT=$(pwd -P)

set -e

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit 1
}

setup_gitconfig () {
  if ! [ -f git/gitconfig.local.symlink ]
  then
    info 'setup gitconfig'

    git_credential='cache'
    if [ "$(uname -s)" == "Darwin" ]
    then
      git_credential='osxkeychain'
    fi

    # GIT_AUTHOR_NAME and GIT_AUTHOR_EMAIL answer the questions without a prompt
    git_authorname=$GIT_AUTHOR_NAME
    git_authoremail=$GIT_AUTHOR_EMAIL

    if { [ -z "$git_authorname" ] || [ -z "$git_authoremail" ]; } && ! [ -t 0 ]
    then
      fail 'set GIT_AUTHOR_NAME and GIT_AUTHOR_EMAIL to create git/gitconfig.local.symlink without a prompt'
    fi

    if [ -z "$git_authorname" ]
    then
      user ' - What is your github author name?'
      read -e git_authorname
    fi
    if [ -z "$git_authoremail" ]
    then
      user ' - What is your github author email?'
      read -e git_authoremail
    fi

    # \, | and & are special in a sed replacement
    git_authorname=$(printf '%s' "$git_authorname" | sed 's/[\\|&]/\\&/g')
    git_authoremail=$(printf '%s' "$git_authoremail" | sed 's/[\\|&]/\\&/g')

    sed -e "s|AUTHORNAME|$git_authorname|g" -e "s|AUTHOREMAIL|$git_authoremail|g" -e "s|GIT_CREDENTIAL_HELPER|$git_credential|g" git/gitconfig.local.symlink.example > git/gitconfig.local.symlink

    success 'gitconfig'
  fi
}

setup_gitconfig

# symlinks
ln -sf $DOTFILES/git/gitconfig.local.symlink ~/.gitconfig.local
ln -sf $DOTFILES/git/gitconfig.symlink ~/.gitconfig
ln -sf $DOTFILES/git/gitignore.symlink ~/.gitignore