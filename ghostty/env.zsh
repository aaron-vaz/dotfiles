# tmux hardcodes TERM_PROGRAM=tmux; restore ghostty for proper extended key support (e.g. shift+enter)
[[ -n "$TMUX" ]] && export TERM_PROGRAM=ghostty
