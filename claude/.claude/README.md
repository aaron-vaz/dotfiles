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
├── rules/                 # Coding rules (some path-scoped via paths:)
├── hooks/                 # Hook scripts
├── agents/                # Agent definitions
├── skills/                # Custom skills
├── references/            # Reference docs (loaded on demand)
├── scripts/               # Utility scripts
│
├── kb/                    # Knowledge base (searchable)
│   ├── entries/           # YAML-frontmatter entries
│   ├── private/           # Untracked private store (default for new entries)
│   ├── search-kb.sh       # Search by tag/keyword; --brief, --medium, --section <heading>, --full, --usage; multi-word AND
│   └── audit-kb.sh        # Find stale entries; fails on missing name/type/description, warns on descriptions >300 chars
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
| PreToolUse/Bash | Any shell command | `guard-sensitive-paths.sh` denies commands naming `~/.ssh`, `~/.gnupg`, `~/.kube`, `~/.aws`, `~/Library`, `~/.netrc`, `~/.npmrc`, `~/.pypirc`, `~/.git-credentials`, `~/.docker/config.json`, `~/.config/gh` (Bash-side twin of the `Read(~/...)` deny rules). Text match only: catches explicit references, not obfuscation, and can false-positive on commands that merely mention a path. Implicit use (`git push`, `ssh`) is unaffected; a project-level `./.npmrc` is allowed |
| PreToolUse/Bash | `git commit`/`tag`/`notes`/`merge` (any global options), `gh pr`/`issue`/`api`/`release` | `block-session-urls.sh` denies a message or body carrying a `claude.ai/code/session_*` URL or a `Claude-Session:` trailer, inline or in a `-F`/`--body-file` file (KB `no-session-urls-in-external-content`). Tests: `tests/session-urls-mechanical.sh`, `tests/sensitive-paths-mechanical.sh` |
| PreToolUse/Edit+Write+NotebookEdit | Main-thread file edit | `enforce-delegation.sh` denies it and points at `impl-orchestrator` (exempt: `.claude/`, `~/.agents/`, temp dirs, `CC_MAIN_EDITS=1`) |
| PreToolUse/Read+Edit+Write | First touch of a file type per session+agent | `kb-feedback-push.sh` maps extension (.kt/.kts→kotlin, .py→python, .java→java, .sh→shell, .proto→protobuf, gradle files→gradle, test files→testing) to KB tags, injects `search-kb.sh --type feedback --tag <tag> --brief` results as additionalContext. Deduped per session+agent+tag via state file under `$TMPDIR`; never blocks |
| SubagentStart | Any subagent spawn | `subagent-track.sh` records agent_id → agent_type for the subagent status line |

Hooks read tool metadata as JSON on stdin and run in the session's working directory, not through `CLAUDE_*` variables: see `references/hooks.md` ("Hook Input Contract"). Contract test: `tests/hook-stdin-contract-mechanical.sh`.

### Skills

| Skill | Purpose |
|-------|---------|
| `adversarial-review` | Cross-model review at 3 gates (investigation, plan, architecture) |
| `conventional-commits` | Semantic commit message format |
| `grill-me` | Stress-test a plan or design |
| `investigation-intake` | Pre-investigation checklist |
| `jira-writing` | Create Jira issues from notes |
| `self-review` | Review own code as staff engineer |
| `skelly` | Scaffold a new project from a template without prompts |
| `session-archiver` | Archive session to KB (manual) |
| `skill-audit` | Remove token-wasteful content from skills |
| `tech-discovery` | Technical discovery documents |
| `web-design-guidelines` | UI/a11y review |

### Delegation (subagents)

Main session (`cc`, Sonnet) stays open for ad-hoc questions. Anything that edits code is delegated: multi-unit work to `impl-orchestrator`, a single file or artifact straight to `implementer`.

| Agent | Tier | Role |
|-------|------|------|
| `impl-orchestrator` | opus (medium effort) | Plans, splits, dispatches, verifies multi-unit work. No Edit/Write; can spawn workers |
| `implementer` | sonnet | One scoped unit of work (≤ ~5 files), builds and tests before reporting |
| `quick-editor` | sonnet | Mechanical edit, hard limit 3 files |
| `scout` | haiku | Read-only locator, returns `path:line` evidence |
| `test-runner` | haiku | Runs build/tests/lint, categorizes every failure, no edits |
| `change-reviewer` | opus | Independent read-only diff review (must differ from implementer's model) |

- **Enforcement:** `hooks/enforce-delegation.sh` (PreToolUse). `agent_id` in the payload exists only inside subagents, so a missing one means main thread. Don't run the main session with `--agent`.
- **Bypass:** `CC_MAIN_EDITS=1 cc` — `cc`/`mcc` forward it through tmux via `env`, since tmux sessions don't inherit the launching shell's environment.
- **Turn budget and handoff:** every definition has a "Turn budget and handoff" section with its own limit (`maxTurns`): handoff note within the first 3 tool rounds, stop new work at ~70%, report (`PARTIAL` if unfinished) by ~85%. Briefs state the limit and name the handoff and report paths. Standard: `references/subagent-turn-budget-and-handoff.md`.
- **Don't pass `model`** when spawning these agents: a per-call `model` beats the definition's tier.
- **Haiku only for read-only workers:** `scout` and `test-runner` run on haiku; every worker that edits or reviews is sonnet or above.
- **Depth:** `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=2` in `settings.json` (main → orchestrator → workers). `Agent(type)` allowlists in a subagent's `tools:` are ignored by Claude Code, so the orchestrator's worker list is enforced by its prompt; workers simply have no `Agent` tool.
- **Status line:** `subagentStatusLine` → `hooks/subagent-statusline.js`. Row: status glyph, agent type, model tier (colored), elapsed, context %, tokens, sparkline, effort, label.
- **Tests:** `tests/delegation-mechanical.sh`.
- **Verified harness facts** (model resolution order, status line payload, report and resume mechanics, deny-rule caveats): `references/delegation-stack.md`.
- **Launchers:** `cc` and `mcc` run `claude update` before starting (failure never blocks launch) and start claude via `scripts/claude-with-secrets` (see MCP secrets below).

### Session naming

`startup/session-start.md` (section 3) tells the main session to name itself so parallel sessions are distinguishable: write a 2–4 word kebab-case slug of the *work* (not the repo) to `~/.claude/sessions/.rename-request`, which renames the tmux session within seconds.

- **When:** first user message that states a task, as the first tool call of that turn; the startup turn alone ("Ready") does not rename.
- **Self-check:** a first substantive turn must not end without a rename having been written.
- **Re-name:** once, on a clear pivot to different work. Subagents never rename.
- **Enforcement:** instruction only (no hook), so it depends on the model following the startup prompt.

### Rules

- **Always loaded:** `code-style.md`, `testing.md`, `git.md`, `shell.md`.
- **Path-scoped** (`paths:` frontmatter; load only when Claude reads a matching file): `kotlin.md` (`**/*.kt`, `**/*.kts`), `java.md` (`**/*.java`), `python.md` (`*.py`, `**/*.py`).

### Knowledge Base

```bash
~/.agents/kb/search-kb.sh "keyword"          # search
~/.agents/kb/search-kb.sh --tag debugging     # by tag
~/.agents/kb/search-kb.sh --project myproject # by project
~/.agents/kb/audit-kb.sh                      # find stale entries
```

Design rationale (flat entries, gitignored TSV index, SessionStart output rules): `references/memory-system.md`.

**Tests:** `tests/kb-search-mechanical.sh`, `tests/kb-feedback-push-mechanical.sh`, `tests/kb-session-reminder-mechanical.sh`.

## MCP secrets (OS keystore)

MCP configs hold `${VAR}` placeholders, never secret values. `cc`/`mcc` start claude through `scripts/claude-with-secrets`, which reads each secret from the OS keystore (macOS Keychain via `security`, else Linux `secret-tool`), exports it, and then `exec`s claude. Claude Code expands `${VAR}` in `command`, `args`, `env`, `url` and `headers`.

The secret list is per machine and untracked. Create `${XDG_CONFIG_HOME:-~/.config}/claude/secrets.map` (override the path with `CLAUDE_SECRETS_MAP`), one `ENV_VAR keystore-service` pair per line. `scripts/claude-with-secrets.map.example` shows the format.

```bash
# 1. Store the value (prompts for it; -U overwrites)
security add-generic-password -U -a "$USER" -s my-mcp-token -w          # macOS
secret-tool store --label=my-mcp-token service my-mcp-token             # Linux

# 2. Map it to an env var on this machine
echo 'MY_MCP_TOKEN my-mcp-token' >> ~/.config/claude/secrets.map

# 3. Reference it in the MCP config as ${MY_MCP_TOKEN}
```

- **Why a launcher:** a tmux pane does not inherit the launching shell's exports, and `env VAR=secret claude` would leave the secret in the tmux client's argv. The launcher runs inside the pane and reads the keystore there.
- **No map file:** the launcher starts claude with no secrets. `${VAR}` placeholders for unset variables make those MCP servers fail to authenticate.
- **Missing keystore item:** the launcher warns on stderr (names only) and starts claude anyway.
- **Plain `claude` outside `cc`/`mcc` has no secrets.** Run `~/.claude/scripts/claude-with-secrets` instead, or export the variables yourself. A variable already set in the environment is not overwritten.
- **Values are stored raw:** keep prefixes such as `Bearer ` in the MCP config, not in the keystore.

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
