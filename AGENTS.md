# AGENTS.md

Guidelines for agents working in this repository.

## Project Overview

Aaron's dotfiles for macOS and Linux (Arch, Debian/Ubuntu, Fedora). Each top-level directory is a module ("topic") that owns one tool: its install, its update and its zsh config. `./install` runs the modules' installers; `up` updates everything.

This repo is **public**. Never commit secrets, employer names, internal hosts or private repo details. Machine-specific settings belong in `~/.localrc` (sourced by `.zshrc`, never tracked); the git identity lives in `git/gitconfig.local.symlink` (gitignored).

## Running the installer without prompts

Agents should never rely on prompts. Anything that would ask has a flag or an environment variable:

```bash
./install --list                          # modules, one per line
./install --only gh,pyenv --no-update     # just these modules, no bin/up afterwards
./install --skip arch,vscode              # everything but these
./install -y                              # everything
GIT_AUTHOR_NAME=… GIT_AUTHOR_EMAIL=… ./install --only git   # git asks for these otherwise
```

Choosing modules by flag, or running without a terminal on stdin, never opens the fzf picker. `--only`/`--skip` reject unknown module names. `bin/up` runs after the install unless `--no-update` is given; it pulls this repo and runs every module's `update.sh`, including system package upgrades with `sudo`, so pass `--no-update` unless that is wanted. `bin/dot` is the same as `./install` and works from any directory.

## Layout

```
install            # entry point: picks modules, runs <module>/install.sh, then bin/up
bin/               # on PATH; bin/up updates everything, bin/dot runs install
functions/         # zsh functions and completions, autoloaded
<module>/          # one per tool, e.g. gh/, pyenv/, zsh/
claude/.claude/    # Aaron's global Claude Code config, symlinked to ~/.claude
opencode/          # OpenCode config, symlinked to ~/.config/opencode
kb/                # shared agent knowledge base, symlinked to ~/.agents/kb
```

`claude/.claude/AGENTS.md` and its rules are Aaron's **global** agent instructions for every repo, not instructions for this one. Editing them changes how every agent session on his machines behaves, so only touch them when asked to.

## Module files

A module uses only the files it needs. The names are what make them load:

| File | Run by | When |
|------|--------|------|
| `install.sh` | `./install`, with `bash -e`, from the repo root, alphabetically after `homebrew` | install |
| `update.sh` | `bin/up`, **sourced** in zsh | update |
| `path.zsh` | `.zshrc`, first | every shell |
| `*.zsh` (other names, e.g. `env.zsh`, `aliases.zsh`) | `.zshrc`, after all `path.zsh` | every shell |
| `completion.zsh` | `.zshrc`, after `compinit` | every shell |
| `*.symlink` | nothing automatically; the module's `install.sh` links it | install |

`$DOTFILES` points at the repo root in all of them.

## Writing a module

- **`install.sh` is idempotent.** Check before doing work (`command -v tool`, `[ -d ~/.tool ]`) so running `./install` again is safe and quick.
- **Guard by platform.** Skip quietly on an OS or package manager the module does not support (see `ghostty/install.sh`, `gh/install.sh`).
- **No prompt without a way around it.** Read an environment variable first and prompt only when stdin is a terminal; without one, fail with a message naming the variable (see `git/install.sh`).
- **`update.sh` is sourced into zsh**, so it must never `exit` (that ends `up`), and it should do nothing when the tool is not installed. `bin/up` runs with `set -e`: a command that can fail for an expected reason (not logged in, nothing to upgrade) needs `|| …`, or every later module goes without its update.
- **Shell files must not fail when the tool is missing.** A `path.zsh`, `env.zsh` or `completion.zsh` that runs a command guards it with `command -v`, or every new shell prints an error on machines without the tool.
- **Prefer the tool's official installer or the system package manager**, and let the package manager do updates where it can. On macOS, a plain CLI formula belongs in `homebrew/Brewfile`, which `homebrew/install.sh` and `up` apply with `brew bundle`. GUI apps (casks) are per machine: they live in `homebrew/Brewfile.apps`, which `homebrew/install.sh` offers in a picker (or `DOTFILES_CASKS=all|none|name,name` answers) and writes the choice to the untracked `~/.Brewfile`; `install` and `up` apply that file.
- Print progress the way the other modules do: `echo "\033[00;32m──›\033[0m updating <tool>"`.

## Shell compatibility

- `install` must run on the bash 3.2 that ships with macOS: no associative arrays, `mapfile`, `${var,,}` or `declare -n`.
- `install.sh`/`update.sh` are POSIX `sh` unless their shebang says otherwise. Use `bash` when the script needs it (e.g. it sources `jabba.sh`).
- macOS ships BSD `sed`, `grep` and `awk`: no `sed -i` without a suffix argument, no `\s` in `grep`.

## Testing a change

There is no test suite. CI (`.github/workflows/shellcheck.yml`) runs `shellcheck --severity=error` over `install`, `bin/` and every `*.sh` with an `sh` or `bash` shebang; warnings remain in older scripts, so do not add new ones. Before committing:

```bash
bash -n install                       # syntax
sh -n <module>/install.sh             # or bash -n for bash scripts
zsh -n <module>/*.zsh                 # when zsh is installed
shellcheck install <module>/*.sh      # when shellcheck is installed
```

To check that a new shell starts cleanly, link a temporary `.zshrc` to a copy of the repo and run `HOME=<tmp> ZDOTDIR=<tmp> PATH=/usr/bin:/bin zsh -ic exit`: it must print nothing on a machine without the tools.

Exercise install logic with stub commands on `PATH` (a fake `curl`, `brew`, `gh`, …) and a temporary `HOME` rather than installing real software, and run `./install --only <module> --no-update` against the stubs. Never run `bin/up` to test: it upgrades the whole machine.

## Commits

Conventional commits (`feat(gh): …`, `fix(install): …`, `chore: …`), scoped by module. This is a single-author repo: commit to `master` and push it, no feature branch or PR. Keep `master`'s history clean: one commit per logical change, with its fixes amended or squashed in before pushing, never a run of work-in-progress commits. Stage only the files the change touches, since the working tree often has unrelated edits.
