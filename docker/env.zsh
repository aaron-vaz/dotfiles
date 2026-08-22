# Docker Desktop CLI completions.
# Sourced before zshrc's compinit, so fpath is set in time (a completion.zsh
# would load too late). Not named completion.zsh for exactly that reason.
typeset -U fpath
[[ -d $HOME/.docker/completions ]] && fpath=($HOME/.docker/completions $fpath)
