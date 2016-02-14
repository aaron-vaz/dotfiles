if test "$(which apgggm)"
then
  rm -R ~/.atom/packages/*
  apm install --packages-file ~/.dotfiles/atom/package-list.txt
fi
