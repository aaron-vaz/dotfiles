# fzf-tab replaces the completion menu, so it has to load after compinit
# (init.zsh skips it for that reason). This file also owns the menu style,
# because zsh/completion.zsh loads after it and would override it.
fzf_tab=$ZSH_PLUGINS_DIR/Aloxaf/fzf-tab/fzf-tab.plugin.zsh

if [[ -f $fzf_tab ]]; then
  source "$fzf_tab"

  # fzf-tab needs zsh's own menu off to capture the common prefix
  zstyle ':completion:*' menu no
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':completion:*:git-checkout:*' sort false
  zstyle ':fzf-tab:*' switch-group ',' '.'
else
  zstyle ':completion:*' menu select
fi

unset fzf_tab
