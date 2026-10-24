UPGRADE_JABBA=${UPGRADE_JABBA:-false}

if [ ! -d ~/.jabba ] || [ "$UPGRADE_JABBA" = "true" ];
then
    curl -fsSL https://github.com/Jabba-Team/jabba/raw/main/install.sh | bash -s -- --skip-rc && . ~/.jabba/jabba.sh
fi
