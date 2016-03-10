if [[ "$(whence jenv 2> /dev/null)" ]]
then
    eval "$(jenv init - --no-rehash zsh)"
fi
