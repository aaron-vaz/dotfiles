# Extensions

Machine-specific modules that must not be public (work tools, a server's
backup jobs) live outside this repo, in `~/.dotfiles.d/<extension>/`. Nothing
about a specific extension belongs in this repo.

## Layout

An extension is laid out like this repo: module folders with the files in
[modules.md](modules.md), plus an optional `bin/` (put on `PATH`) and
`functions/` (added to `fpath` and autoloaded). `install` lists only module
folders with an `install.sh`; one with just `update.sh` is updated by `up` but
never shows in `install --list`. It is usually a private git
clone, but a plain folder works.

```
~/.dotfiles.d/
  work/              # extension (git clone or plain folder)
    vpn/install.sh   # module work/vpn
    vpn/update.sh
    bin/             # on PATH
    functions/       # autoloaded
```

`$DOTFILES_EXTENSIONS_DIR` moves the directory. Set it in `~/.zshenv`:
`~/.localrc` loads after the modules, too late for `.zshrc`.

## How each entry point finds them

- **`install`** lists extension modules as `<extension>/<module>`, after the
  built-in ones, and `--only`/`--skip`/the picker take the same names. Each
  `install.sh` runs with `bash -e` from its extension's root, with `$DOTFILES`
  still pointing at this repo.
- **`bin/up`** first pulls this repo, and stops there when the pull brings in
  new commits: nothing is updated on that run, so `up` needs running again.
  Otherwise it updates the built-in modules, then for each extension:
  `git pull` when it is a git repo with no unstaged changes to tracked files
  (a failed pull warns and `up` carries on), then sources its modules'
  `update.sh`.
- **`.zshrc`** loads extension `*.zsh` files after the built-in ones in each
  phase (`path.zsh`, other `*.zsh`, `completion.zsh`). `system/path.zsh` adds
  each `bin/`, `zsh/config.zsh` each `functions/`, `zsh/fpath.zsh` each module
  folder.

A machine without `~/.dotfiles.d` behaves as if extensions did not exist: every
glob is null-guarded (`(N)` in zsh, `[ -f ]` in bash) and prints nothing.

## Changing the extension plumbing

Keep the three entry points above in step, and test with a temporary `HOME`
holding a stub extension (see [testing.md](testing.md)):

```bash
tmp=$(mktemp -d)
mkdir -p "$tmp/.dotfiles.d/work/demo"
printf '#!/bin/sh\necho "ran in $PWD"\n' > "$tmp/.dotfiles.d/work/demo/install.sh"
# .zshrc exports DOTFILES_EXTENSIONS_DIR, so override it too, or the real
# ~/.dotfiles.d is used
HOME=$tmp DOTFILES_EXTENSIONS_DIR=$tmp/.dotfiles.d ./install --list | tail -1   # work/demo
HOME=$tmp DOTFILES_EXTENSIONS_DIR=$tmp/.dotfiles.d ./install --only work/demo --no-update
```

Test `up`'s extension loop by running only that part of `bin/up` against stub
extensions (a clean git clone, a dirty one, one without an upstream, a plain
folder), never `bin/up` itself.

## Instructions inside an extension

An extension's own `AGENTS.md` is its own business. To let an agent working
there know how it plugs in, one line is enough:

```markdown
This is a dotfiles extension; see $DOTFILES/docs/agents/extensions.md.
```
