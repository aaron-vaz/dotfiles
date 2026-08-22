---
name: session-archiver
description: Archives valuable session context to the knowledge base for future reference. Use when manually archiving a session or feature.
---

# Session Archiver

Manually archive valuable sessions to the knowledge base.

## Workflow

### Step 1: Identify Session to Archive

**Option A: From session file**
```bash
find ~/.claude/sessions -name "20*.md" -mtime -7 -type f | sort -r
```
Skip `current.md`.

**Option B: From current context** — if user says "archive this session", use the current session's content.

### Step 2: Check for Duplicates

```bash
~/.agents/kb/search-kb.sh --brief <keyword-from-session>
```

If an existing entry already covers the same decision/root cause, skip or note as a follow-up.

### Step 3: Evaluate

**Size is a prerequisite, not a qualifier.** A long session with no conclusion is noise.

**Evaluation criteria (ALL must pass):**

1. **Size threshold:** > 500 bytes (prerequisite only — filters truly empty sessions)
2. **Not a duplicate:** Existing KB entry doesn't already cover the same topic
3. **Contains durable, non-derivable knowledge** — at least one of:
   - A root cause was identified for a bug/incident
   - A concrete decision was made with a stated why (tradeoff, constraint, rejected alternative)
   - A reusable gotcha/pattern was discovered that isn't obvious from reading the code
   - A fact about an external system (API quirk, infra behavior) was learned
4. **Not superseded or abandoned** — the session reached a real stopping point

**Skip if (any one disqualifies):**
- File < 500 bytes
- Near-duplicate of existing KB entry
- Only auto-generated headers
- Pure exploration with no decision/fix/answer reached
- Content fully derivable from code/git history
- One-off throwaway query with no reusable insight

**When in doubt, skip.** A missing KB entry costs nothing — the session file still exists. A junk KB entry wastes time on every future search. Bias toward under-archiving.

### Step 4: Create KB Entry

Write to `~/.agents/kb/entries/<date>-<slug>.md` with YAML frontmatter:
```yaml
---
name: <short-slug>
description: <one-line summary>
date: <YYYY-MM-DD>
tags: [<relevant-tags>]
status: active
---
```

Sections:
- **Context** — What was the problem/task
- **Key Decisions** — What was decided and why
- **Outcome** — What was the result
- **Lessons Learned** — Gotchas, patterns, non-obvious facts
- **Related** — Links to other KB entries or references

### Step 5: Rebuild Index

```bash
~/.agents/kb/search-kb.sh --rebuild-index 2>/dev/null || true
```

### Step 6: Report

Report: what was archived (filename), what was skipped and why.
