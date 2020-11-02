#!/bin/sh
if [ ! -d ~/.gw ]; then
  curl -sL https://github.com/aaron-vaz/gw/raw/master/install.sh | bash
fi