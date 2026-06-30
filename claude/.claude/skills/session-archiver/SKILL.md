---
name: session-archiver
description: Archives valuable session context to the knowledge base for future reference. Use when archiving sessions not captured during the end-session workflow.
---

# Session Archiver

Automatically archives valuable sessions that weren't captured during end-session workflow.

## Workflow

### Step 1: Scan Recent Sessions

```bash
find ~/.claude/sessions -name "20*.md" -mtime -7 -type f | sort -r
```

**Exclude current session:** skip `current.md`.

### Step 2: Check Already Archived

```bash
# List existing KB entries to avoid duplicates
ls ~/.claude/kb/entries/ 2>/dev/null
```

### Step 3: Evaluate Each Session

**For each session file, read and evaluate:**

**Evaluation criteria (ALL must pass):**

1. **Size threshold:** Session file > 500 bytes (substantial content)
2. **Not already archived:** Date not already in KB entries
3. **Has valuable content:** Section headers, code blocks, structured content

**Skip if:**
- File < 500 bytes (trivial session)
- Already archived
- Only contains auto-generated headers
- Contains only "## Session YYYY-MM-DD" with no content after

### Step 4: Create KB Entry

For each qualifying session, write a KB entry to `~/.claude/kb/entries/<date>-<slug>.md` with YAML frontmatter:
- `title`, `date`, `project`, `tags`, `status: active`, `outcome`, `expires` (90 days)
- Sections: Context, Key Decisions, Outcome, Lessons Learned, Related

### Step 5: Report Summary

Report how many sessions were scanned, archived, already archived, and too small to archive.
