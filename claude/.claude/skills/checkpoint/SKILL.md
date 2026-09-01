---
name: checkpoint
description: Save current session state to a KB entry so work survives a context clear. Prints the /pickup command to resume. Use when user says "checkpoint", "save state", before an expected context clear/compaction, at a natural milestone mid-task, or when a PreCompact hook reminder fires.
---

# Checkpoint

Dump current session state into a KB entry (disk, not conversation memory — survives context clear/compaction). No evaluation gate like `session-archiver` — checkpoint always writes, on request or nudge, mid-work.

## Workflow

### 1. Resolve project and slug

```bash
PROJECT="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"
```

SLUG = kebab-case of the task/topic — from what the user named this turn if they gave one, else inferred from the current work (branch name, active goal). **No date in the filename** — a fixed name keeps the `/pickup` command printed at step 6 permanently valid, and turns the dedupe check in step 2 into an exact match instead of a fuzzy search.

Filename: `checkpoint-<PROJECT>-<SLUG>.md`

### 2. Prefer the feature's existing entry over a new file

Per AGENTS.md, a feature already worked on this session likely has a session-log KB entry ("one file, no duplication"). Check first:

```bash
~/.agents/kb/search-kb.sh --project "$PROJECT" --brief
```

If an entry for this exact feature/task exists, append a `## Checkpoint <timestamp>` section to **that** file instead (add `checkpoint` to its `tags:` if missing) — skip straight to step 4. Only create a dedicated `checkpoint-*.md` file when no feature entry exists (ad hoc/exploratory session).

### 3. Otherwise, check for an existing checkpoint file (exact match only)

```bash
ls ~/.agents/kb/private/checkpoint-"$PROJECT"-"$SLUG".md ~/.agents/kb/entries/checkpoint-"$PROJECT"-"$SLUG".md 2>/dev/null
```

If found, append a new `## Checkpoint <timestamp>` section to it. **Never** resolve this with a keyword/tag search instead of the exact filename — `search-kb.sh`'s full-text fallback drops the `--tag` filter on a miss and can match into an unrelated, non-checkpoint KB entry; appending there corrupts it.

If not found: new file. Store defaults to **`~/.agents/kb/private/`** (session state routinely names repos/branches/internals); use `entries/` only if confirmed to name nothing employer- or private-product-specific.

### 4. Gather state

- **Repo/worktree — mandatory, absolute path** (`pwd` or `git rev-parse --show-toplevel`). A fresh session starts in an arbitrary CWD; without this, pickup can't find the work. If CWD isn't a git repo, record the path anyway and note "not a git repo."
- Branch: `git branch --show-current`
- Working tree: full `git status --short` output (not just clean/dirty — pickup needs to know what's uncommitted)
- Task/goal — what's being done, why
- Decisions made and why (rejected alternatives if relevant)
- Files touched/created
- Next steps — ordered, concrete (this is what pickup executes)
- Blockers or open questions

### 5. Write the entry

New-file frontmatter:
```yaml
---
name: checkpoint-<project>-<slug>
description: <one-line: what this checkpoint covers>
type: project
tags: [checkpoint, <project>]
status: active
date: <YYYY-MM-DD>
---
```
`date:` is required, not optional — `search-kb.sh` builds its index date column, and pickup's recency-ordered listing, from this field. Without it the listing has no dates and no reliable ordering.

Body (new file, or a section appended to an existing one):
```markdown
## Checkpoint <YYYY-MM-DD HH:MM>

### Task
What's being done, why.

### State
Repo: <absolute path>
Branch: <branch>
Working tree: <git status --short output, or "clean">

### Decisions
- Decision: rationale, alternatives rejected

### Files Touched
- path — what changed

### Next Steps
1. Concrete next action
2. ...

### Blockers
Open questions or "none".
```

### 6. Print pickup command

Last line of output, exactly this (nothing else on the line, so it copy-pastes clean):

```
/pickup <filename-without-.md>
```
i.e. `/pickup checkpoint-<project>-<slug>` for a new dedicated file, or `/pickup <existing-entry-slug>` when appended to a feature entry.

## Known limitation

Same slug checkpointed by two parallel sessions on the identical task can race on append (last write wins). Named-per-task files avoid the old global `current.md` collision, but don't add locking. Keep concurrent sessions on distinct slugs/subtasks.
