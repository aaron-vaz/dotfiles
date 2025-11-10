UPGRADE_JABBA=${UPGRADE_JABBA:-false}

if [ ! -d ~/.jabba ] || [ "$UPGRADE_JABBA" = "true" ];
then
    curl -sL https://github.com/Jabba-Team/jabba/raw/main/install.sh | bash -s -- --skip-rc && . ~/.jabba/jabba.sh
fi
