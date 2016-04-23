#!/bin/sh

if [ ! -d ~/.zplug ]
then
    git clone https://github.com/b4b4r07/zplug ~/.zplug
    cd ~/.zplug
    git checkout -b v2 origin/v2
fi
