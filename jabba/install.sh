#!/usr/bin/env bash

UPGRADE_JABBA=${UPGRADE_JABBA:-false}
# newest Temurin 25 (an LTS release)
DEFAULT_JDK="temurin@~25"

if [ ! -d ~/.jabba ] || [ "$UPGRADE_JABBA" = "true" ];
then
    curl -fsSL https://github.com/Jabba-Team/jabba/raw/main/install.sh | bash -s -- --skip-rc
fi

. ~/.jabba/jabba.sh

# seed a default JDK on a fresh machine, and leave one that is already chosen alone
if [ -z "$(jabba alias default)" ];
then
    jabba install "$DEFAULT_JDK"
    jabba use "$DEFAULT_JDK"
    jabba alias default "$(jabba current)"
fi
