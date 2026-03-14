# Configuration Reference

## CONFIGURATION STRUCTURE

```
~/.config/opencode/
├── AGENTS.md                    # Global instructions (this file)
├── agents.d/                    # Referenced modules
│   ├── AGENTS.agents.md         # Agent/model configuration
│   ├── AGENTS.skills.md         # Custom skills reference
│   ├── AGENTS.workflows.md      # Build/test/git/debug workflows
│   ├── AGENTS.conventions.md    # Patterns and anti-patterns
│   └── AGENTS.config.md         # This file - config setup
├── settings.json                # OpenCode settings
├── opencode.json                # Provider config + plugins
├── oh-my-opencode.json          # Agent/category model assignments
├── skills/                      # Custom skills directory
│   ├── agents-md-updater/
│   ├── agents-md-validator/
│   ├── conventional-commits/
│   ├── find-skills/
│   ├── generate-project-docs/
│   ├── jvm/
│   ├── jvm-test-quality/
│   ├── kotlin-review/
│   ├── mermaid-diagram-creator/
│   ├── pr-review-learnings/
│   ├── react-best-practices/
│   └── self-review/
├── kb/                          # Knowledge base
└── snippet/                     # Code snippets
```

## DOTFILES & SYMLINKS

**All configuration is managed via symlinks to a git repo:**

| Config | Location | Symlink Target |
|--------|----------|----------------|
| OpenCode config | `~/.config/opencode` | `/Users/aaronvaz/Code/shell/dotfiles/opencode` |
| Git config | `~/.gitconfig` | `/Users/aaronvaz/Code/shell/dotfiles/git/gitconfig.symlink` |
| Git ignore | `~/.gitignore` | `/Users/aaronvaz/Code/shell/dotfiles/git/gitignore.symlink` |

**Dotfiles repo:** `/Users/aaronvaz/Code/shell/dotfiles`

## SETUP (ONE-TIME)

```bash
# Backup existing config if needed
mv ~/.config/opencode ~/.config/opencode.backup

# Create symlink
ln -s /Users/aaronvaz/Code/shell/dotfiles/opencode ~/.config/opencode
```

## UPDATE WORKFLOW

```bash
# All edits happen in dotfiles repo, not symlinks
cd ~/Code/shell/dotfiles/opencode/.opencode

# Edit AGENTS.md or other files
vim AGENTS.md

# Commit and push changes
git add -A
git commit -m "config: describe change"
git push

# Changes are immediately reflected via symlinks
```

## PLUGIN CONFIGURATION

### opencode.json

```json
{
  "provider": { "go": { "name": "go" } },
  "plugin": [
    "oh-my-opencode",
    "cc-safety-net",
    "envsitter-guard",
    "opencode-mem",
    "opencode-snip",
    "opencode-notify",
    "opencode-snippets",
    "tokenscope"
  ]
}
```

### oh-my-opencode.json

See [`AGENTS.agents.md`](./AGENTS.agents.md) for full configuration.

## COMMANDS REFERENCE

```bash
# Install/update symlinks
~/Code/shell/dotfiles/opencode/install.sh

# OpenCode commands
opencode -s                    # Start with session
opencode --list-sessions      # List sessions
opencode --new-session        # New session
opencode --kill-server        # Kill server

# Git worktrees
git worktree add -b <branch> .worktrees/<name> <base>
git worktree list
git worktree remove <path>
```

## TROUBLESHOOTING

| Issue | Solution |
|-------|----------|
| Symlink broken | Re-run `install.sh` |
| Config not loading | Check symlink with `ls -la ~/.config/opencode` |
| Skills not found | Verify `~/.config/opencode/skills/` exists |
| Wrong model used | Check `oh-my-opencode.json` overrides |

## FILES TO EDIT

| What to Change | File |
|----------------|------|
| Global instructions | `AGENTS.md` |
| Agent/model config | `oh-my-opencode.json` |
| Plugin settings | `opencode.json` |
| OpenCode settings | `settings.json` |
| Add custom skill | `skills/<name>/SKILL.md` |