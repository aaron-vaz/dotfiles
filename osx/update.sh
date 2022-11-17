#!/bin/sh

if test "$(uname)" = "Darwin"
then
  echo "\033[00;32m──›\033[0m OS X Software Update"
  softwareupdate -l	
fi