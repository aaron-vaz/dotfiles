export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"

function add_to_path()
{
    if [[ -d $1 && ! $PATH =~ ":$1" ]]; then
        export PATH="$1:$PATH"
    fi
}

add_to_path /sbin
add_to_path /usr/sbin
add_to_path /usr/local/sbin
add_to_path /usr/local/bin

# each extension's bin/, behind this repo's so ./bin and $DOTFILES/bin win
for extension_bin in ${DOTFILES_EXTENSIONS_DIR:-$HOME/.dotfiles.d}/*/bin(N/); do
  export PATH="$extension_bin:$PATH"
done
unset extension_bin

export PATH="./bin:$DOTFILES/bin:$PATH"
