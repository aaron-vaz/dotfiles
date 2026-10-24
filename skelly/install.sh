#!/bin/sh
UPGRADE_SKELLY=${UPGRADE_SKELLY:-false}

if [ ! -x ~/.local/bin/skelly ] || [ "$UPGRADE_SKELLY" = "true" ]
then
  curl -fsSL https://raw.githubusercontent.com/aaron-vaz/skelly/main/install.sh | sh
fi
