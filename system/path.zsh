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

export PATH="./bin:$DOTFILES/bin:$PATH"
