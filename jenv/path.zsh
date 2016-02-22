#Lazy load jenv, this currently takes 400ms to start. It does however mean that it won't use the right Java version until it's loaded.

function jenv() {
    unfunction jenv

    if test "$(whence jenv 2> /dev/null)"
    then
        local exe=$(which jenv)
        eval "$( command $exe init - )"
        $exe "$@"
    fi
}
