# Shell compatibility

- `install` must run on the bash 3.2 that ships with macOS: no associative arrays, `mapfile`, `${var,,}` or `declare -n`.
- `install.sh`/`update.sh` are POSIX `sh` unless their shebang says otherwise. Use `bash` when the script needs it (e.g. it sources `jabba.sh`).
- macOS ships BSD `sed`, `grep` and `awk`: no `sed -i` without a suffix argument, no `\s` in `grep`.
