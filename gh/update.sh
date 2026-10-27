#!/bin/sh

if command -v gh > /dev/null 2>&1
then
  echo "\033[00;32m──›\033[0m updating gh extensions"
  # bin/up stops at the first failure, and this fails when gh is not logged in
  gh extension upgrade --all || echo "gh extensions not upgraded"
  echo
fi
