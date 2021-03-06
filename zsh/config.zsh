export CLICOLOR=true

fpath=($DOTFILES/functions $fpath)

autoload -U $DOTFILES/functions/*(:t)

bindkey "^[[3~" delete-char

[[ $(whence gdircolors 2> /dev/null) ]] && eval `gdircolors $DOTFILES/zsh/dircolors`
[[ $(whence dircolors 2> /dev/null) ]] && eval `dircolors $DOTFILES/zsh/dircolors`

export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

setopt NO_BG_NICE # don't nice background tasks
setopt NO_HUP
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS # allow functions to have local options
setopt LOCAL_TRAPS # allow functions to have local traps
setopt HIST_VERIFY
setopt SHARE_HISTORY # share history between sessions ???
setopt EXTENDED_HISTORY # add timestamps to history
setopt PROMPT_SUBST
setopt CORRECT
setopt COMPLETE_IN_WORD

setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# don't expand aliases _before_ completion has finished
#   like: git comm-[tab]
setopt complete_aliases
