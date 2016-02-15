if test "$(which fzf)"
then
  cd ~/.fzf && git pull && ./install
else
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all --no-update-rc
fi
