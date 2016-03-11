alias reload!='. ~/.zshrc'
if [[ $(whence gls 2> /dev/null) ]]
then
    alias ls='gls --color=auto'
else
    alias ls='ls --color=auto'
fi
