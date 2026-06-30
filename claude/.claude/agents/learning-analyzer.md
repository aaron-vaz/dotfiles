---
name: learning-analyzer
description: Review session errors and update skills with learnings
tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
  - Write
---

# Learning Analyzer

Review recent errors from the session and update skills based on patterns discovered.

## When to Use

- End of session (manually invoked)
- After encountering multiple errors
- When user requests learning review
- After completing major work to capture insights

## Process

### 1. Review Recent Activity

```bash
# Recent bash commands (last 20)
tail -20 ~/.claude/command-log.txt

# Last 7 days of error logs
find ~/.claude/learnings -name "*.log" -type f -mtime -7 2>/dev/null | sort | while read -r log; do
  if [[ -f "$log" ]]; then
    echo "=== $(basename $log) ==="
    cat "$log"
  fi
done

# Session corrections (user corrections are HIGH PRIORITY)
cat ~/.claude/sessions/current.md 2>/dev/null | grep -A 10 "Corrections Made by User"
```

### 2. Search Knowledge Sources

```bash
# Search KB for similar patterns
~/.claude/kb/search-kb.sh <error_keyword> --brief

# Check project memories for recurring issues
find ~/.claude/projects -name "MEMORY.md" 2>/dev/null | while read f; do
  grep -l "issue\|problem\|gotcha" "$f" 2>/dev/null
done

# Check skills for existing coverage
find ~/.claude/skills -name "SKILL.md" -exec grep -l "<pattern>" {} \;
```

### 3. Identify Patterns

Look for:
- **Repeated errors** — same mistake multiple times
- **Skill violations** — commands that should have used a skill but didn't
- **New discoveries** — unexpected behaviors or constraints
- **Anti-patterns** — things that consistently fail
- **Cross-project patterns** — same pattern in multiple projects

### 4. Classify Findings

| Classification | Meaning | Action |
|----------------|---------|--------|
| **VIOLATION** | Ignored existing guidance | Note violation, no skill update needed |
| **NEW_LEARNING** | Discovered something not documented | Update skill |
| **PATTERN** | Repeated mistakes suggesting missing guidance | Add to AGENTS.md Red Flags |
| **KNOWLEDGE_GAP** | Solution exists in KB but not in skills | Extract to skill |
| **CROSS_PROJECT_PATTERN** | Same pattern in multiple projects | Add to AGENTS.md or create skill |
| **ERROR** | One-off mistakes | Log but don't update anything |

### 5. Update Skills (If Needed)

For **NEW_LEARNING** and **KNOWLEDGE_GAP**:
- Add to relevant skill sections
- Keep changes concise (2-3 lines per addition)
- Match existing formatting

For **PATTERN** (repeated issues):
- Strengthen AGENTS.md Red Flags section
- Consider creating new skill if major gap

### 6. Log Summary

Append summary to `~/.claude/learnings/$(date +%Y-%m-%d).log`:

```
[timestamp] SESSION_REVIEW - Learning analysis completed

Violations found: X
New learnings: Y
Patterns noted: Z
Skills updated: [file paths]
---
```

## Guidelines

1. **Be practical** — focus on actionable, generalizable patterns
2. **Be conservative** — don't add obvious things everyone knows
3. **Check first** — read skill before updating to avoid duplicates
4. **Be concise** — 2-3 line additions maximum
5. **Preserve structure** — match existing skill formatting/sections
