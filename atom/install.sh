#!/bin/zsh

if test "$(whence apm 2> /dev/null)"
then
    # Check for differences, if the lists don't match, reinstall.
    if [[ -n $(comm -3 <(apm list --installed --bare | cut -f1 -d"@" | sort | grep -v '^$') <(sort ~/.dotfiles/atom/package-list.txt | grep -v '^$')) ]]
    then
        rm -R ~/.atom/packages/*
        apm install --packages-file ~/.dotfiles/atom/package-list.txt
    fi
fi
