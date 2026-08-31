# Claude Code Configuration

Personal Claude Code settings, skills, hooks, and knowledge base.

## Installation

The install script symlinks the configuration files to `~/.claude/`.

```bash
cd ~/Code/shell/dotfiles && ./install
```

Or just the Claude Code part:

```bash
bash ~/Code/shell/dotfiles/claude/install.sh
```

## Files

- `AGENTS.md` — Canonical agent instructions (single source of truth)
- `CLAUDE.md` — Delegation stub → `@./AGENTS.md`
- `persona.md` — Communication style (blunt, peer-to-peer)
- `settings.json` — Hooks, permissions, model config
- `mcp.json` — MCP server registrations (also symlinked to `~/.mcp.json`)
- `functions.zsh` — `cc` launcher function (tmux session management), `mcc` throwaway-session launcher

## `cc` Launcher

`cc` is a tmux-powered Claude launcher with session management:

| Command | Action |
|---------|--------|
| `cc` | Attach to existing session for CWD, or create new. Offers to resume last session. |
| `cc -n` | Force new session with startup prompt (`session-start.md`) |
| `cc -n my-feature` | New session named `cwd-my-feature-HHMM` |
| `cc -r` | Pick from recent sessions (fzf) |
| `cc <args>` | New session with args passed to claude |

Auto-features:
- Session named from git branch or ticket ID in `sessions/current.md`
- Auto-resume prompt if recent session exists (<7 days)
- `~/.claude` git pull on launch (if updates available)
- In-session rename: write to `~/.claude/sessions/.rename-request` → tmux renames automatically

For direct launch without tmux, use `cla` (alias for `claude`).

## `mcc` — Throwaway Session

`mcc` launches Claude in a fresh `mktemp -d` scratch dir — no session tracking, no resume prompt. Use for ad-hoc/one-off work you don't want polluting a real project's session history. Args pass through to `claude`.

## Structure

```
~/.claude/
├── AGENTS.md              # Canonical agent instructions
├── CLAUDE.md              # Delegation stub → @./AGENTS.md
├── persona.md             # Communication style
├── settings.json          # Hooks, permissions, model config
├── mcp.json               # MCP server registrations
├── rules/                 # Auto-loaded coding rules (5 rules)
├── hooks/                 # Hook scripts (9 hooks)
├── agents/                # Agent definitions (2 agents)
├── skills/                # Custom skills (12 skills)
├── references/            # Reference docs (loaded on demand)
├── scripts/               # Utility scripts
├── startup/               # Session initialization prompts
├── kb/                    # Knowledge base (searchable)
├── sessions/              # Session tracking (runtime)
├── learnings/             # Error logs (runtime)
├── logs/                  # Runtime logs
└── ideas/                 # Brainstorming notes
```

## Customization

Edit files in `~/Code/shell/dotfiles/claude/.claude/` — they're symlinked to `~/.claude/`.

After changes, commit and push to keep config in sync across machines.
