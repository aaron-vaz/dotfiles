#add each topic folder to fpath so that they can add functions and completion scripts
for topic_folder ($DOTFILES/* ${DOTFILES_EXTENSIONS_DIR:-$HOME/.dotfiles.d}/*/*(N/)) if [ -d $topic_folder ]; then  fpath=($topic_folder $fpath); fi;
