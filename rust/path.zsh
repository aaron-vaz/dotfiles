# rustup from Homebrew is keg-only: its rustup, cargo, rustc... proxies are in the keg, not on PATH
for dir in /opt/homebrew/opt/rustup/bin /usr/local/opt/rustup/bin /home/linuxbrew/.linuxbrew/opt/rustup/bin
do
    if [[ -d $dir ]]
    then
        export PATH="$dir:$PATH"
        break
    fi
done

# binaries installed with cargo install
if [[ -d $HOME/.cargo/bin ]]
then
    export PATH="$PATH:$HOME/.cargo/bin"
fi
