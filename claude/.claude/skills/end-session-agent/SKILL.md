---
name: end-session-agent
description: Automated agent that runs retrospective quality checks at session startup. Scans previous sessions for archive-worthy content and runs learning analysis.
---

# End-Session Agent

Autonomous agent that runs retrospective quality checks on previous session at startup.

**Spawned by:** `startup/session-start.md` (every session)
**Runs:** In parallel with user's work (non-blocking)

## Workflow

### Step 1: Initialize and Load Context

```bash
PREV_SESSION=$(find ~/.claude/sessions -name "20*.md" -type f ! -name "current.md" -mtime -1 | sort -r | head -1)

if [[ -z "$PREV_SESSION" ]]; then
  echo "No recent session found - nothing to check"
  exit 0
fi
```

### Step 2: Evaluate Session

```bash
HAS_DECISIONS=$(grep -c "Decision:" "$PREV_SESSION" 2>/dev/null || echo 0)
HAS_PATTERNS=$(grep -c "Pattern:" "$PREV_SESSION" 2>/dev/null || echo 0)
HAS_ARCHITECTURE=$(grep -iE "architecture|design|refactor" "$PREV_SESSION" | wc -l)
SESSION_SIZE=$(wc -c < "$PREV_SESSION")

ARCHIVE_WORTHY=false
if [[ $SESSION_SIZE -gt 1000 ]] &&
   [[ $HAS_DECISIONS -gt 0 || $HAS_PATTERNS -gt 0 || $HAS_ARCHITECTURE -gt 2 ]]; then
  ARCHIVE_WORTHY=true
fi
```

### Step 3: Build Checklist

```
CHECKS_NEEDED=()

if [[ $ARCHIVE_WORTHY == "true" ]]; then
  CHECKS_NEEDED+=("archive_session")
fi

if [[ $HAS_ARCHITECTURE -gt 3 ]]; then
  CHECKS_NEEDED+=("agents_md_improver")
fi

# Run learning analyzer unless already run today
if [[ ! "$SKIP_LEARNING_ANALYZER" == "true" ]]; then
  CHECKS_NEEDED+=("learning_analyzer")
fi
```

### Step 4: Report Findings

Send findings to user. List what checks are needed. Note learning analyzer runs automatically.

### Step 5: Execute Approved Checks

**A. Archive session (if archive-worthy):**

Write KB entry to `~/.claude/kb/entries/<date>-<title>.md` with YAML frontmatter.

**B. Run Learning Analyzer:**

```bash
if [[ ! -f ~/.claude/learnings/.last-analyzed-$(date +%Y-%m-%d) ]]; then
  # Run learning-analyzer agent
  touch ~/.claude/learnings/.last-analyzed-$(date +%Y-%m-%d)
fi
```

### Step 6: Report Summary and Shut Down

List which checks ran and their outcomes.
