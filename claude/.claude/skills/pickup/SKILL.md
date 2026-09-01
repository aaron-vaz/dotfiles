---
name: pickup
description: Resume session state saved by /checkpoint. Pass the checkpoint slug printed at checkpoint time (e.g. "/pickup checkpoint-myrepo-auth-refactor"). With no slug, lists active checkpoints to choose from.
---

# Pickup

Restore state from a `/checkpoint` KB entry and resume work.

## Workflow

### 1. No slug given

```bash
~/.agents/kb/search-kb.sh --tag checkpoint --brief
```
(`--status active` is the default filter — done checkpoints are excluded automatically.) List results (date, slug, description), ask the user which to resume.

### 2. Load the entry

```bash
~/.agents/kb/search-kb.sh --full <slug>
```

If that misses (entry moved/renamed), fall back to a direct read, then a glob for a partial/fragment slug:
```bash
cat ~/.agents/kb/private/<slug>.md 2>/dev/null || cat ~/.agents/kb/entries/<slug>.md 2>/dev/null
ls ~/.agents/kb/private/*<slug>*.md ~/.agents/kb/entries/*<slug>*.md 2>/dev/null
```

### 3. Verify before touching anything

Read the entry's `Repo:` path. If it differs from CWD, confirm with the user before `cd`-ing there — changing directory is a session-level move, not implied by a resume request.

Compare current state against what was recorded:
```bash
git branch --show-current
git status --short
```

- **Match:** proceed to step 4.
- **Drift** (different branch, working tree changed since the checkpoint, uncommitted changes now gone) — **stop**. Show the user what's recorded vs. what's actually there and ask how to proceed. Do not resume Next Steps or treat Decisions as settled against state that no longer matches — a drifted premise can make the recorded next step wrong or destructive.

### 4. Resume

Summarize Task, State, Decisions, Next Steps, Blockers back to the user. Resume from the first Next Steps item. Treat Decisions as settled — don't re-litigate them without new information.

### 5. Keep it current

Append progress to the **same** entry (new `## Checkpoint <timestamp>` section) rather than creating a new one, so a later `/pickup <slug>` still finds one coherent file. When all Next Steps are done, set the entry's `status: done` — this excludes it from `search-kb.sh`'s default active-only listing (step 1's no-slug case) without deleting the record.
