source ~/.zplug/zplug

# zplug "b4b4r07/zplug"

zplug "themes/bira", from:oh-my-zsh

zplug "zsh-users/zsh-syntax-highlighting", nice:10
zplug "zsh-users/zsh-completions", nice:10

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load
