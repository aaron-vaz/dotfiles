# Testing a change

There is no test suite. CI (`.github/workflows/shellcheck.yml`) runs `shellcheck --severity=error` over `install`, `bin/` and every `*.sh` with an `sh` or `bash` shebang; warnings remain in older scripts, so do not add new ones. Before committing:

```bash
bash -n install                       # syntax
sh -n <module>/install.sh             # or bash -n for bash scripts
zsh -n <module>/*.zsh                 # when zsh is installed
shellcheck install <module>/*.sh      # when shellcheck is installed
```

To check that a new shell starts cleanly, link a temporary `.zshrc` to a copy of the repo and run `HOME=<tmp> ZDOTDIR=<tmp> PATH=/usr/bin:/bin zsh -ic exit`: it must print nothing on a machine without the tools.

Exercise install logic with stub commands on `PATH` (a fake `curl`, `brew`, `gh`, …) and a temporary `HOME` rather than installing real software, and run `./install --only <module> --no-update` against the stubs. Never run `bin/up` to test: it upgrades the whole machine.
