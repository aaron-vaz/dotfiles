source ~/.zplug/zplug

export ZPLUG_THREADS=32

zplug "b4b4r07/zplug"

#Load path first.
zplug "$DOTFILES", of:"**/path.zsh", nice:1, from:local

#Load everything else.
zplug "$DOTFILES", of:"**/*.zsh", ignore:"**/(path|completion|zplug|config|plugins).zsh", from:local

#Load the theme.
zplug "lwis/zsh-theme"
#zplug "$PROJECTS/zsh-theme", from:local

#Load completions last.
zplug "$DOTFILES", of:"**/completion.zsh", from:local, nice:10
zplug "zsh-users/zsh-syntax-highlighting", nice:10
zplug "zsh-users/zsh-completions", nice:10
zplug "srijanshetty/zsh-pip-completion", nice:10

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
