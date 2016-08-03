source ~/.zplug/init.zsh

#Load path first.
zplug "$DOTFILES", use:"**/path.zsh", nice:1, from:local

#Load everything else.
zplug "$DOTFILES", use:"**/*.zsh", ignore:"**/(path|completion|zplug|config|plugins).zsh", from:local

# Load pure prompt theme.
zplug "sindresorhus/pure"
zplug "mafredri/zsh-async"

#Load completions last.
zplug "$DOTFILES", use:"**/completion.zsh", nice:10, from:local
zplug "zsh-users/zsh-autosuggestions", nice:10
zplug "zsh-users/zsh-syntax-highlighting", nice:10
zplug "zsh-users/zsh-completions", nice:10
zplug "srijanshetty/zsh-pip-completion", nice:10

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
