---
name: end-session
description: Use when ending a development session, running quality checks before closing Claude Code, or when typing ::end-session.
---

# End Session Workflow

## Workflow

### 1. Check for Pending Work

```bash
if git rev-parse --git-dir > /dev/null 2>&1; then
  git status --short
  git log --oneline -5 2>/dev/null || echo "No commits"
else
  echo "Not a git repository - skipping git checks"
fi

tail -20 ~/.claude/command-log.txt 2>/dev/null || echo "No command log"
```

If uncommitted changes with substantial code → run `self-review` skill before committing.

### 2. Run Learning Analyzer

**Always run the learning-analyzer agent:**

Use the Agent tool with the `learning-analyzer` agent definition. Provide this prompt:

```
Review session errors and update skills based on pattern detection guidelines in ~/.claude/references/learning-patterns.md

Check:
1. Last 7 days of error logs: ~/.claude/learnings/*.log
2. Command history: ~/.claude/command-log.txt
3. Session corrections: ~/.claude/sessions/current.md
4. Recent conversation context

Priority:
- HIGH: User corrections, 3+ tool failures, 2+ identical errors
- MEDIUM: Failures across multiple days, skill violations
- LOW: One-time mistakes (document but don't update)

Only update skills for generalizable patterns.

This session involved: [brief summary]
```

**Wait for agent completion** before proceeding.

### 3. Run CLAUDE.md / AGENTS.md Improver (if needed)

**Check if architectural changes were made:**
- Modified core architecture?
- Added new patterns or conventions?
- Discovered gotchas or non-obvious behavior?
- Added new commands or workflows?

**If YES to any above:** update `~/.claude/AGENTS.md` with the new patterns.

### 4. Archive to KB (if valuable)

**Archive if:** solved a complex problem, made architectural decisions, learned domain knowledge, user said "save this", or multi-turn exploration with valuable insights.

**Skip if:** simple Q&A, session-specific context only, pure execution without decisions.

**If archiving:**

1. Ask user: "Should we archive this session to the knowledge base? This session involved: [brief summary]"

2. If yes, write a KB entry to `~/.claude/kb/entries/$(date +%Y-%m-%d)-<slug>.md` with YAML frontmatter:
   - `title`, `date`, `project`, `tags`, `status: active`, `outcome`, `expires` (90 days)
   - Sections: Context, Key Decisions, Outcome, Lessons Learned, Related

3. Rebuild search index:
```bash
~/.claude/kb/search-kb.sh --rebuild-index 2>/dev/null || true
```

### 5. Session Summary

Read `~/.claude/sessions/current.md` for context, then output a summary covering: tasks completed, files modified, decisions made, quality checks run and their outcomes.

### 6. Commit Claude Config Changes

```bash
cd ~/.claude
if git rev-parse --git-dir > /dev/null 2>&1; then
  git status --short
fi
```

**If there are changes to config files** (skills/, hooks/, references/, scripts/, settings.json, persona.md, AGENTS.md):

```bash
cd ~/.claude
git add skills/ hooks/ references/ scripts/ settings.json persona.md AGENTS.md 2>/dev/null
git diff --cached --quiet || git commit -m "chore: update Claude config - [brief description]

Co-Authored-By: Claude <noreply@anthropic.com>"
git push 2>/dev/null || true
```
