# The installer and updater

## Entry points

- `install` picks modules, runs each `<module>/install.sh`, then `bin/up`.
  Asks in fzf (installed first if missing) with every module selected,
  unless modules are chosen by flag or stdin is not a terminal.
- `bin/dot` is the same as `./install` and works from any directory.
- `bin/up` pulls this repo and runs every module's `update.sh`, including
  system package upgrades with `sudo`. When the pull brings in new commits it
  stops right after, without updating anything. See AGENTS.md: never run it
  unless asked.

## Flags

Agents should never rely on prompts. Anything that would ask has a flag or an environment variable:

```bash
./install --list                          # modules, one per line
./install --only gh,pyenv --no-update     # just these modules, no bin/up afterwards
./install --skip arch,vscode              # everything but these
./install -y                              # everything
GIT_AUTHOR_NAME=… GIT_AUTHOR_EMAIL=… ./install --only git   # git asks for these otherwise
```

Choosing modules by flag, or running without a terminal on stdin, never opens
the fzf picker. `--only`/`--skip` reject unknown module names. `bin/up` runs
after the install unless `--no-update` is given, so pass `--no-update` unless a full machine upgrade is wanted.

## Changing `install`

It must run on the bash 3.2 that ships with macOS (see [shell.md](shell.md)).
Extension modules go through the same code: see [extensions.md](extensions.md).
