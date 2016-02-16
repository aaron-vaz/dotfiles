#!/bin/sh

if test "$(which pip3 2> /dev/null)"
then
  pip3 install --user --upgrade -r ~/.dotfiles/pip/requirements.txt
else
  curl -fsSL https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && python3 /tmp/get-pip.py --user
fi
