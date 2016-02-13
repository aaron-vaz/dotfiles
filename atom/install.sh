if test "$(which apm)"
then
  rm -R ~/.atom/packages/*
  apm install --packages-file ~/.dotfiles/atom/package-list.txt
fi
