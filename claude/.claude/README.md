# Personal Claude Code Config

Adapted from work config. Minimal foundation — add plugins, MCP servers, and skills as needed.

## Structure

```
~/.claude/
├── AGENTS.md              # Canonical agent instructions
├── CLAUDE.md              # Delegation stub → @./AGENTS.md
├── persona.md             # Communication style
├── settings.json          # Hooks, permissions, model config
├── mcp.json               # MCP server registrations
│
├── rules/                 # Auto-loaded coding rules
├── hooks/                 # Hook scripts
├── agents/                # Agent definitions
├── skills/                # Custom skills (12 skills)
├── references/            # Reference docs (loaded on demand)
├── scripts/               # Utility scripts
│
├── kb/                    # Knowledge base (searchable)
│   ├── entries/           # YAML-frontmatter entries
│   ├── search-kb.sh       # Search by tag/keyword
│   └── audit-kb.sh        # Find stale entries
│
├── sessions/              # Session tracking
├── learnings/             # Error logs for learning system
├── logs/                  # Runtime logs
├── ideas/                 # Brainstorming notes
└── startup/               # Session initialization prompts
```

## Key Components

### Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| SessionStart | Always | Loads recent KB entries into context |
| Notification | `idle_prompt` | macOS notification when waiting for input |
| PreToolUse/Bash | `git commit` | Pre-commit review, planning file check, git usage validation |
| PostToolUse/Edit+Write | After file edits | Async: runs tests, saves session summary |
| PostToolUse/Bash | After any command | Async: logs command, saves session summary |
| PostToolUseFailure | Any tool failure | Async: logs error for learning system |

### Skills

| Skill | Purpose |
|-------|---------|
| `adversarial-review` | Cross-model review at 3 gates (investigation, plan, architecture) |
| `conventional-commits` | Semantic commit message format |
| `end-session` | Session cleanup checklist |
| `end-session-agent` | Auto-runs at session startup for archival |
| `grill-me` | Stress-test a plan or design |
| `investigation-intake` | Pre-investigation checklist |
| `jira-writing` | Create Jira issues from notes |
| `self-review` | Review own code as staff engineer |
| `session-archiver` | Archive session to KB |
| `skill-audit` | Remove token-wasteful content from skills |
| `tech-discovery` | Technical discovery documents |
| `web-design-guidelines` | UI/a11y review |

### Knowledge Base

```bash
~/.claude/kb/search-kb.sh "keyword"          # search
~/.claude/kb/search-kb.sh --tag debugging     # by tag
~/.claude/kb/search-kb.sh --project myproject # by project
~/.claude/kb/audit-kb.sh                      # find stale entries
```

## Setup

```bash
# 1. Copy or symlink to ~/.claude
cp -r ~/.claude-personal ~/.claude
# OR
ln -s ~/.claude-personal ~/.claude

# 2. Symlink mcp.json
ln -sf ~/.claude/mcp.json ~/.mcp.json

# 3. Make scripts executable
chmod +x ~/.claude/hooks/*.sh ~/.claude/kb/*.sh ~/.claude/scripts/*.sh

# 4. Add MCP servers to ~/.claude/mcp.json as needed

# 5. Optionally add plugins via /plugin in Claude Code
```

## Customization Points

- **`AGENTS.md`** — project locations, domain rules, personal conventions
- **`persona.md`** — communication style
- **`settings.json`** — hooks, permissions, model config
- **`mcp.json`** — add MCP servers
- **`rules/`** — add language-specific coding rules
- **`skills/`** — add custom skills

## Key Principles

1. **Only do what was requested** — no autonomous refactoring
2. **Execute directly** — don't plan unless asked
3. **Never guess** — look up from source
4. **Parallelize** — independent reads, independent fixes
5. **Multi-model delegation** — use different models for review/verification
