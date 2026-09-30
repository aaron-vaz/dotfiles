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
| PreToolUse/Bash | `git commit` | Pre-commit review suggestion, planning file check, git usage validation |
| PostToolUse/Edit+Write | After file edits | Async: runs tests |
| PostToolUse/Bash | After any command | Logs command to command-log.txt |
| PreToolUse/Bash | Any shell command | `guard-sensitive-paths.sh` denies commands naming `~/.ssh`, `~/.gnupg`, `~/.kube`, `~/Library`, `~/.netrc`, `~/.npmrc`, `~/.pypirc`, `~/.docker/config.json` (Bash-side twin of the `Read(~/...)` deny rules). Text match only: catches explicit references, not obfuscation, and can false-positive on commands that merely mention a path. Implicit use (`git push`, `ssh`) is unaffected; a project-level `./.npmrc` is allowed |
| PreToolUse/Edit+Write+NotebookEdit | Main-thread file edit | `enforce-delegation.sh` denies it and points at `impl-orchestrator` (exempt: `.claude/`, `~/.agents/`, temp dirs, `CC_MAIN_EDITS=1`) |
| SubagentStart | Any subagent spawn | `subagent-track.sh` records agent_id → agent_type for the subagent status line |

### Skills

| Skill | Purpose |
|-------|---------|
| `adversarial-review` | Cross-model review at 3 gates (investigation, plan, architecture) |
| `conventional-commits` | Semantic commit message format |
| `grill-me` | Stress-test a plan or design |
| `investigation-intake` | Pre-investigation checklist |
| `jira-writing` | Create Jira issues from notes |
| `self-review` | Review own code as staff engineer |
| `session-archiver` | Archive session to KB (manual) |
| `skill-audit` | Remove token-wasteful content from skills |
| `tech-discovery` | Technical discovery documents |
| `web-design-guidelines` | UI/a11y review |

### Delegation (subagents)

Main session (`cc`, Sonnet) stays open for ad-hoc questions. Anything that edits code goes to `impl-orchestrator`.

| Agent | Tier | Role |
|-------|------|------|
| `impl-orchestrator` | opus | Plans, splits, dispatches, verifies. No Edit/Write; can spawn workers |
| `implementer` | sonnet | One scoped unit of work (≤ ~5 files), builds and tests before reporting |
| `quick-editor` | sonnet | Mechanical edit, hard limit 3 files |
| `scout` | sonnet | Read-only locator, returns `path:line` evidence |
| `test-runner` | sonnet | Runs build/tests/lint, categorizes every failure, no edits |
| `change-reviewer` | opus | Independent read-only diff review (must differ from implementer's model) |

- **Enforcement:** `hooks/enforce-delegation.sh` (PreToolUse). `agent_id` in the payload exists only inside subagents, so a missing one means main thread. Don't run the main session with `--agent`.
- **Bypass:** `CC_MAIN_EDITS=1 cc` — `cc`/`mcc` forward it through tmux via `env`, since tmux sessions don't inherit the launching shell's environment.
- **Don't pass `model`** when spawning these agents: a per-call `model` beats the definition's tier.
- **No haiku:** auto mode does not support Haiku, so every worker is sonnet or above.
- **Depth:** `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` in `settings.json` (main → orchestrator → workers). `Agent(type)` allowlists in a subagent's `tools:` are ignored by Claude Code, so the orchestrator's worker list is enforced by its prompt; workers simply have no `Agent` tool.
- **Status line:** `subagentStatusLine` → `hooks/subagent-statusline.js`. Row: status glyph, agent type, model tier (colored), elapsed, context %, tokens, sparkline, effort, label.
- **Tests:** `tests/delegation-mechanical.sh`.
- **Launchers:** `cc` and `mcc` run `claude update` before starting (failure never blocks launch).

### Knowledge Base

```bash
~/.agents/kb/search-kb.sh "keyword"          # search
~/.agents/kb/search-kb.sh --tag debugging     # by tag
~/.agents/kb/search-kb.sh --project myproject # by project
~/.agents/kb/audit-kb.sh                      # find stale entries
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
chmod +x ~/.claude/hooks/*.sh ~/.agents/kb/*.sh ~/.claude/scripts/*.sh

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
