# Aaron does dotfiles

## Install

```sh
./install       # pick the modules to install in fzf (installed first if missing); all are selected by default
./install -y    # install every module without asking
./install --help
```

`--only`, `--skip` and `--list` choose modules without the picker, for scripts and agents. See [docs/agents/install.md](docs/agents/install.md).

## Extensions

Customizations for one machine, such as work tools or a server's jobs, go in `~/.dotfiles.d/<extension>/`, usually a private repo cloned there. An extension is laid out like this repo (`<module>/install.sh`, `update.sh`, `*.zsh`, plus `bin/` and `functions/`), and `install`, `up` and every new shell pick it up. `up` also pulls it when it is a git repo.

```sh
git clone git@example.com:me/work-dotfiles.git ~/.dotfiles.d/work
./install --only work/vpn
```
