#!/bin/sh

# The official script installs the app and links the zed CLI into ~/.local/bin
# on both macOS and Linux. Zed updates itself after that.
if ! command -v zed > /dev/null 2>&1 && [ ! -x ~/.local/bin/zed ]
then
  curl -fsSL https://zed.dev/install.sh | sh
fi
