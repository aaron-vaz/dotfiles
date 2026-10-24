# zshrc adds ~/.local/bin only after the completion files are loaded, so skelly's completion
# would not find it without this
if [ -x ~/.local/bin/skelly ]; then
  export PATH=$HOME/.local/bin:$PATH
fi
