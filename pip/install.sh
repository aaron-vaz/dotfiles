#!/usr/bin/env zsh

if [[ "$(which brew 2> /dev/null)" && ! -f $PYTHONUSERBASE/bin/pip ]]
then
    curl -fsSL https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && python3 /tmp/get-pip.py --user && rm /tmp/get-pip.py
fi

