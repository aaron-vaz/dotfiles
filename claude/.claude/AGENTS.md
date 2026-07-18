# AGENTS.md

Instructions for all AI coding agents acting for Aaron. Tool-specific files (`CLAUDE.md`, `.cursor/rules/`, etc.) delegate here via `@./AGENTS.md` import or symlink. Single source of truth — edit here, not stubs.

## Project Locations

- `~/Code/` — Primary workspace

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

**Full content:** `~/.claude/kb/search-kb.sh <slug> --full` or read `~/.claude/kb/entries/<slug>.md`.

## Domain Rules

**Never guess identifiers.** Don't invent names for things — look them up from source.

**Never assume library versions from training data.** Check `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `build.gradle.kts`, or equivalent — project's manifest is ground truth.

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

## Workflow Checkpoints

**When starting significant work:** create KB entry draft at `~/.claude/kb/entries/<YYYY-MM-DD>-<slug>.md`. Append progress throughout session — after each significant finding, decision, or constraint. Don't wait until end. Guards against context compaction losing work mid-session.

**Before commit:** full build passes, not just tests.

**After significant `~/.claude` config changes:** update `~/.claude/README.md`.

**Commit format:**
```
<type>(<scope>): <description>

Co-Authored-By: <Agent Name> <Model> <noreply@anthropic.com>
```
Types: `feat` `fix` `docs` `refactor` `test` `chore` | `BREAKING CHANGE`

## Session Context — KB Is Source of Truth

No global `current.md` — a single shared file collides across parallel sessions/worktrees. Instead: KB entry (`~/.claude/kb/entries/`) per feature/ticket is both the working session log AND the permanent record — one file, no duplication, naturally collision-free (dated + named).

Record in the feature's KB entry as you go:
- Design decisions and why alternatives were rejected
- Constraints discovered
- **User corrections** — log under "Corrections Made by User"

Resuming work: search KB for the feature (`~/.claude/kb/search-kb.sh <keyword>` or `--tag`), not a session file.

See `~/.claude/references/session.md` for format details.

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
