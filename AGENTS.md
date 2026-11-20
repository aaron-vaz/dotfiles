# AGENTS.md

Guidelines for agents working in this repository. This file is the map:
read the linked doc before the task it names.

## Project

Aaron's dotfiles for macOS and Linux (Arch, Debian/Ubuntu, Fedora). Each top-level directory is a module that owns one tool: its install, its update and its zsh config. `./install` runs the modules' installers; `up` updates everything. Machine-specific modules live outside the repo, in extensions under `~/.dotfiles.d/`.

This repo is **public**. Never commit secrets, employer names, internal hosts or private repo details. Machine-specific settings belong in `~/.localrc` (sourced by `.zshrc`, never tracked) or an extension; the git identity lives in `git/gitconfig.local.symlink` (gitignored).

## Read before…

| Task | Read |
|------|------|
| adding or changing a module | [docs/agents/modules.md](docs/agents/modules.md), then [docs/agents/testing.md](docs/agents/testing.md) |
| anything touching `~/.dotfiles.d`, or how `install`, `bin/up` and `.zshrc` find and load modules | [docs/agents/extensions.md](docs/agents/extensions.md) |
| changing `install`, `bin/up` or `bin/dot`, or running the installer | [docs/agents/install.md](docs/agents/install.md) |
| writing any script | [docs/agents/shell.md](docs/agents/shell.md) |
| committing | [docs/agents/testing.md](docs/agents/testing.md) |

## Always

- Never rely on prompts: `./install --only <module> --no-update` installs without asking and without running `bin/up`.
- Never run `bin/up` unless asked, and never to test: it pulls this repo and upgrades the whole machine with `sudo`.

## Layout

```
install            # entry point: picks modules, runs <module>/install.sh, then bin/up
bin/               # on PATH; bin/up updates everything, bin/dot runs install
functions/         # zsh functions and completions, autoloaded
<module>/          # one per tool, e.g. gh/, pyenv/, zsh/
claude/.claude/    # Aaron's global Claude Code config, symlinked to ~/.claude
opencode/          # OpenCode config, symlinked to ~/.config/opencode
kb/                # shared agent knowledge base, symlinked to ~/.agents/kb
docs/agents/       # the topic docs above
```

`claude/.claude/` and `opencode/.opencode/` hold Aaron's **global** agent instructions for every repo, not instructions for this one: their `AGENTS.md`/`CLAUDE.md` may load when you touch files there, and do not apply to work here. Editing them changes how every agent session on his machines behaves, so only touch them when asked to.

## Commits

Conventional commits (`feat(gh): …`, `fix(install): …`, `chore: …`), scoped by module. This is a single-author repo: commit to `master` and push it, no feature branch or PR. Keep `master`'s history clean: one commit per logical change, with its fixes amended or squashed in before pushing, never a run of work-in-progress commits. Stage only the files the change touches, since the working tree often has unrelated edits.
