# Modules

Each top-level directory is a module ("topic") that owns one tool: its
install, its update and its zsh config.

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

`$DOTFILES` points at the repo root in all of them. Modules can also live
outside the repo, in extensions: see [extensions.md](extensions.md).

## Writing a module

- **`install.sh` is idempotent.** Check before doing work (`command -v tool`, `[ -d ~/.tool ]`) so running `./install` again is safe and quick.
- **Guard by platform.** Skip quietly on an OS or package manager the module does not support (see `ghostty/install.sh`, `gh/install.sh`).
- **No prompt without a way around it.** Read an environment variable first and prompt only when stdin is a terminal; without one, fail with a message naming the variable (see `git/install.sh`).
- **`update.sh` never installs.** It updates a tool that is already there and does nothing otherwise (guard with `command -v` or the tool's directory); installing, including a new package, a JDK or a plugin, belongs to `install.sh`, so `up` cannot put software on a machine its owner left it off.
- **`update.sh` is sourced into zsh**, so it must never `exit` (that ends `up`), and it should do nothing when the tool is not installed. `bin/up` runs with `set -e`: a command that can fail for an expected reason (not logged in, nothing to upgrade) needs `|| …`, or every later module goes without its update.
- **Shell files must not fail when the tool is missing.** A `path.zsh`, `env.zsh` or `completion.zsh` that runs a command guards it with `command -v`, or every new shell prints an error on machines without the tool.
- **Prefer the tool's official installer or the system package manager**, and let the package manager do updates where it can. On macOS, a plain CLI formula belongs in `homebrew/Brewfile`, which `homebrew/install.sh` applies with `brew bundle`. GUI apps (casks) are per machine: they live in `homebrew/Brewfile.apps`, which `homebrew/install.sh` offers in a picker (or `DOTFILES_CASKS=all|none|name,name` answers) and writes the choice to the untracked `~/.Brewfile`, which `install` applies. `up` only updates what is installed (`brew update`, `upgrade`, `cleanup`) and never installs: a package added to a Brewfile reaches a machine through `./install`.
- Print progress the way the other modules do: `echo "\033[00;32m──›\033[0m updating <tool>"`.

Scripts follow [shell.md](shell.md); check them with [testing.md](testing.md).
