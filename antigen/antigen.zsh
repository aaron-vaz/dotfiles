source ~/.antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
#antigen bundle git
antigen bundle pip
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Completions.
antigen bundle zsh-users/zsh-completions src
antigen bundle zsh-users/zsh-history-substring-search

# Autoupdate.
antigen bundle unixorn/autoupdate-antigen.zshplugin

# Theme.
antigen theme bira

# Fin.
antigen apply
