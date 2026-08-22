# AGENTS.md

Instructions for all AI coding agents acting for Aaron. Tool-specific files (`CLAUDE.md`, `.cursor/rules/`, etc.) delegate here via `@./AGENTS.md` import or symlink. Single source of truth — edit here, not stubs.

## Project Locations

- `~/Code/` — Primary workspace

## Discovery Index (MUST USE)

Symlinks to other repos on this machine. **ALWAYS use this for repo discovery, never direct filesystem scans.**

- `_index/code` → `~/Code` (primary workspace)

**When asked about repos, projects, workspaces:**
- **MUST:** `ls -la ~/.claude/_index/` to discover available paths
- **NEVER:** `ls ~/Code/`, `find ~/Code`, or direct filesystem scans
- **NEVER:** Hardcode or recite path lists from memory/training data

**Why:** _index/ is always current (symlinks), direct scans miss structure and go stale. Agent must demonstrate it consulted _index/, not just that it found the right paths.

## Core Principles

**Only do what was requested.** No refactor, scope expand, or improvements without asking.

**Execute directly.** Do NOT enter planning/brainstorming mode unless explicitly asked.

**Parallelize independent operations** — parallel Read calls, parallel fixes, parallel prereq checks.

**Triggers for immediate execution:**
- "Fix this bug" → fix immediately
- "Add this feature" → implement
- "Run these tests" → run immediately
- "Commit" → check status/diff, commit with conventional format

**Triggers for planning:** User says "plan", "design", or "explore".

**Multi-model delegation** — use different models for different tasks:
- Planning, research, architecture, brainstorming → `kimi-k2.7-code` (fable tier — coding-specialized reasoning)
- Complex multi-file changes, large context, design docs → `deepseek-v4-pro` (opus tier — 384K output, high throughput)
- Execution, code edits, file writes, builds → `qwen3.7-plus` (sonnet tier — balanced mid-tier)
- Fast subagents, parallel tasks, lightweight reviews → `mimo-v2.5` (haiku tier — ultra-cheap, 30K+ req/5hr)
- Adversarial review, verification → different model than the one that did the work (see adversarial-review skill)

## Information Placement Hierarchy

1. Cross-project rules/user preferences → this file (`~/.claude/AGENTS.md`)
2. Feature-specific knowledge → KB entry (`~/.claude/kb/entries/`)
3. Project-specific conventions → `<project>/AGENTS.md`

**Information placement routing** (when saving durable facts):

**Do NOT use Claude Code's built-in auto-memory feature** (`~/.claude/projects/*/memory/`, the `MEMORY.md` + `memory_*.md` files). Redundant with hierarchy below. Route to correct tier instead.

**Before saving anything, check this file first** — grep/read relevant section to see if already covered before writing new entry anywhere.

1. **Correction, standing rule, durable user/reference fact** (don't do X / always do Y / who I am / where to find Z) → **IMMEDIATELY write same turn, unprompted**, as `type: feedback`/`user`/`reference` KB entry using `~/.claude/kb/TEMPLATE-feedback.md` schema (frontmatter, `**Why:**`, `**How to apply:**`, `Related: [[wikilinks]]`). **DO NOT** just verbally acknowledge — capture now or re-teach next session. Add one-line pointer here only if high-frequency enough to justify always-loaded cost (rare — most rules belong paged-in).
2. **Session-specific knowledge worth preserving** → KB entry (`~/.claude/kb/private/` by default; `entries/` only if it names nothing employer- or private-product-specific — see Knowledge Base below)
   - **After completing significant work:** save KB entry with full session detail. Include: problem statement, step-by-step investigation, root cause, fix applied, validation. Detailed enough to reproduce or hand off without re-deriving.
3. **Project-specific facts needed every session** → target repo's own `AGENTS.md` (sparingly)
   - **When working in repo with `AGENTS.md`:** append discoveries throughout session — after each significant finding, schema discovery, architectural decision, or constraint. Don't wait until end. Guards against context compaction losing work mid-session.

## Knowledge Base

**Before answering questions about past work, decisions, domain topics — search KB first:**
```
~/.claude/kb/search-kb.sh --tag <tag> --brief
~/.claude/kb/search-kb.sh <keyword> --brief
```

**KB search triggers:**
- "How did we..." / "Why did we..." / "What was the decision on..." → search by keyword
- Debugging a technology → `--tag <technology>`
- Picking up work on a project → `--tag <project-name>`
- **Standing rules, corrections, domain rules** → `--type feedback` (MUST, not optional)
- **About to do something a past correction covers** → `--type feedback --tag <topic>` before acting

**Entry types** (`type:` frontmatter field — filter with `--type`):
- `feedback` — standing corrections, evergreen, `Why:`/`How to apply:` shape
- `user`/`reference` — durable facts/pointers, same evergreen shape
- `project`/`knowledge` — session logs and long-form notes, decay on `expires`

New entries: pick type matching content, don't default to `project`.

**Two stores — public and private.** The dotfiles repo is PUBLIC, so entry
location is a disclosure decision, not filing preference:

| Store | Path | Contents |
|-------|------|----------|
| public | `~/.claude/kb/entries/` | Generic, publishable lessons. May be tracked in the dotfiles repo. |
| private | `~/.claude/kb/private/` | Anything naming an employer, a private product, internal hosts/endpoints, or a private repo's internals. Never tracked, never symlinked into a repo. |

- **Search reads both by default.** Private rows are marked with a leading `*`
  in `--brief`/`--medium`, and `--full` prefixes them with a `PRIVATE KB ENTRY`
  banner.
- **`--no-private` when output is headed anywhere public** — a PR comment, an
  issue, a commit message, a shared doc. `--only-private` for the inverse.
- **When writing a new entry, default to `private/`.** Move it to `entries/`
  only after checking it names nothing employer- or private-product-specific.
- `kb/index.tsv` carries private descriptions and is gitignored — keep it so.

**Full content:** `~/.claude/kb/search-kb.sh <slug> --full` (resolves either
store) or read `~/.claude/kb/{entries,private}/<slug>.md`.

## Domain Rules

**Never guess identifiers.** Don't invent names for things — look them up from source.

**Never assume library versions from training data.** Check `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `build.gradle.kts`, or equivalent — project's manifest is ground truth.

## MUST FOLLOW — Non-Negotiable Behaviors

**1. Write at moment of insight (MUST)**
When user states correction, preference, or standing rule ("never do X", "always do Y", "we don't use Z"):
- **IMMEDIATELY create `type: feedback` KB entry** (same turn, before responding)
- Use `~/.claude/kb/TEMPLATE-feedback.md` schema: frontmatter, `**Why:**`, `**How to apply:**`
- **DO NOT** just verbally acknowledge and move on
- **DO NOT** inline rule into AGENTS.md prose (belongs in paged KB entry)
- **DO NOT** wait to be asked — capture now or re-teach next session

**2. Discovery via _index/ (MUST)**
When asked "what repos/projects do I have", "where is X repo", "show me my workspaces":
- **MUST use `ls -la ~/.claude/_index/`** to discover repos via symlinks
- **DO NOT** use `ls ~/Code/`, `find ~/Code`, or direct filesystem scans
- **DO NOT** hardcode or recite path lists from memory
- Rationale: _index/ is always current, direct scans miss symlinks and go stale

**3. KB search for standing rules (MUST)**
When asked about standing rules, corrections, domain rules, "what are our rules about X":
- **MUST use `~/.claude/kb/search-kb.sh --type feedback`** (with optional `--tag <tag>`)
- **DO NOT** answer from AGENTS.md content alone (AGENTS.md summarizes, KB has full Why/How)
- **DO NOT** use `--tag` or keyword search alone for rule lookups — `--type feedback` is primary filter
- Rationale: feedback entries are evergreen standing rules, AGENTS.md Domain Rules section is summary

## GitHub

**Always use `gh` CLI for GitHub operations.**

Common commands:
- `gh pr view/diff/checks/list/checkout <number>`
- `gh issue view/list <number>`
- `gh api repos/{owner}/{repo}/pulls/{number}/...`

## PR Reviews

- Post findings as **inline comments**, NOT summary comment
- Include AI disclaimer header
- **Flag deprecated/legacy API usage in new code** — "nearby code uses it" is not justification
- **Suggest idiomatic language APIs** when new code uses verbose/imperative patterns
- **Grep for existing repo utilities** before accepting hand-rolled patterns
- **Verify framework annotations are wired** — decorators without config, validators without constraints, etc.

## Git Conventions

**Always use git worktrees for feature work** (except quick single-file edits).

**Never commit directly to main/master.** Keep `.claude/` and `.planning/` files local.

**Use plain `git <command>` when CWD is already the repo.** Use `git -C <path>` only when targeting repo from different directory.

## Testing

**Before running tests:** verify environment, check module scope.

**When build/tests fail with multiple errors:**
1. Read **entire** output
2. Categorize all errors by type
3. Fix **all errors in one pass** — main AND test code together
4. Run **once** to verify

**Verification before claiming tests pass:** all green, no skipped, correct module/package shown.

> Detailed test structure, data rules, and commands in `~/.claude/rules/testing.md`.

## External Communications

**All external writes require draft approval.** Never post, comment, or transition without showing user first.

### GitHub PR Comments

All PR comments via `gh api` (issue comments, not inline review comments) must end with:

```
---
_Generated with AI_
```

### Slack / Messaging

Generating messages:
1. Show draft
2. Ask "Happy with this? Any changes before I copy to clipboard?"
3. Wait for confirmation or edits
4. Copy to clipboard with `pbcopy` (macOS)

## Permissions

- **Files:** Read/edit/create allowed. Delete/move/rename require permission.
- **Git:** Commit and push to feature branches allowed. PRs require user action.
- **gh CLI:** GET operations allowed. Write operations (`gh pr review`, POST/PATCH/DELETE) require confirmation.

## Skills & Workflows

**MUST invoke relevant skills before taking action.**

| Trigger | Skill |
|---------|-------|
| Cross-model review of plans/investigations | `adversarial-review` |
| Git commits | `conventional-commits` |
| Stress-test a plan or design | `grill-me` |
| Starting investigation/feasibility/spike | `investigation-intake` |
| Writing Jira from notes/bugs | `jira-writing` |
| Reviewing/writing Kotlin | `kotlin-review` |
| Review own code before PR | `self-review` |
| Archive session to KB (manual) | `session-archiver` |
| Skills getting bloated | `skill-audit` |
| Technical discovery documents | `tech-discovery` |
| UI/a11y review | `web-design-guidelines` |

### Red Flags — Check Skills

- "Let me commit this" → `conventional-commits`
- "The work is done" → verify before claiming
- "Let me review this PR" → review inline, not summary
- "Starting an investigation" → `investigation-intake`
- "Let me write this code" → consider `self-review` after

## Session Context — KB Is Source of Truth

No global `current.md` — single shared file collides across parallel sessions/worktrees. Instead: KB entry (`~/.claude/kb/entries/`) per feature/ticket is both working session log AND permanent record — one file, no duplication, naturally collision-free (dated + named).

Record in feature's KB entry as you go:
- Design decisions and why alternatives rejected
- Constraints discovered
- **User corrections** — log under "Corrections Made by User"

Resuming work: search KB for feature (`~/.claude/kb/search-kb.sh <keyword>` or `--tag`), not session file.

See `~/.claude/references/session.md` for format details.

## Workflow Checkpoints

**When starting significant work:** create KB entry draft at `~/.claude/kb/entries/<YYYY-MM-DD>-<slug>.md`. Append progress throughout session — after each significant finding, decision, or constraint. Don't wait until end. Guards against context compaction losing work mid-session.

**Before commit:** full build passes, not just tests.

**After significant `~/.claude` config changes:** update `~/.claude/README.md`.

**Session end, if any KB entries written/edited this session (consolidation sweep — bounded to what session touched, not full-KB rewrite):**
1. Merge any new entry that duplicates existing one — one canonical file, fix pointer/tag.
2. Sharpen vague `description:` lines down to load-bearing point (what shows in `--brief` search results).
3. Prune superseded facts inline — replace stale line, don't leave zombie next to new truth.
4. Cross-link entries noticed are related via `Related: [[slug]]`.

**Commit format:**
```
<type>(<scope>): <description>

Co-Authored-By: <Agent Name> <Model> <noreply@anthropic.com>
```
Types: `feat` `fix` `docs` `refactor` `test` `chore` | `BREAKING CHANGE`

## Rules (auto-loaded)

| Rule | Scope |
|------|-------|
| `rules/code-style.md` | Always |
| `rules/testing.md` | Always |
| `rules/git.md` | Always |
| `rules/shell.md` | Always |
| `rules/python.md` | `*.py` files only |

## References (re-read when needed)

NOT auto-loaded — read only when relevant.

| Topic | File |
|-------|------|
| Permissions syntax | `~/.claude/references/permissions.md` |
| Hook configuration | `~/.claude/references/hooks.md` |
| Memory system | `~/.claude/references/memory-system.md` |
| Session tracking | `~/.claude/references/session.md` |
| Agent best practices | `~/.claude/references/agent-best-practices.md` |
| Skill authoring | `~/.claude/references/skill-authoring-patterns.md` |
| PR ready checklist | `~/.claude/references/pr-ready-checklist.md` |
| Knowledge base search | `~/.claude/kb/search-kb.sh --list-tags` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails: multiple errors | Read ALL errors, fix ALL in one pass, rebuild once |
| Git command fails | Use plain `git` in repo CWD; `git -C <path>` only for cross-directory |
| Find past session knowledge | `~/.claude/kb/search-kb.sh --tag <tag>` |
| Can't find memory/conversation | `grep -r` in `~/.claude/sessions/` or `~/.claude/kb/entries/` |
| Hook not firing | `chmod +x ~/.claude/hooks/*.sh`; check settings.json hook syntax |
| KB search not found | `~/.claude/kb/search-kb.sh --rebuild-index` |
| `git add kb/index.tsv` rejected | `kb/index.tsv` is gitignored — auto-generated. Stage only `kb/entries/*.md` |
