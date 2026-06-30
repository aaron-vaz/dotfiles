# Memory System Reference

## Project Memory (`~/.claude/projects/{project}/memory/MEMORY.md`)

Persistent knowledge auto-loaded into every session for a specific project.

**Use project memory sparingly.** The KB handles most persistence needs better — it has lifecycle, tags, and search without consuming context window. Project memory is only justified for things that must be in context automatically every session.

### When project memory is justified (narrow)

- Critical lookup rules that prevent wasted tool calls
- In-progress ideas or notes that need to be visible every session without searching
- Things where forgetting = significant wasted time or mistakes

### Use KB instead when

- It's a pattern, decision, or lesson from a session → KB entry
- It's cross-project behavior or a user preference → global `~/.claude/AGENTS.md`
- It only needs to be found occasionally, not always in context → KB (searchable)
- It's an idea to revisit → `~/.claude/ideas/`

### Structure

**MEMORY.md is auto-loaded** — first 200 lines included in conversation context. Keep it short.

### Format Example

```markdown
## User Preferences

- Always create worktrees for feature work

## Recurring Solutions

### Some Recurring Issue
Root cause: ...
Solution: ...
Last encountered: 2026-06-30

## Important Paths

- Config: `config/`
- Tests: `tests/`
```

### Updating Memory

When correcting a memory entry:
1. Read the existing entry
2. Update or replace it
3. Include date of correction
4. Explain why it was wrong (for learning)

## Knowledge Base

Curated session knowledge at `~/.claude/kb/entries/`.

### Search

```bash
# By tag
~/.claude/kb/search-kb.sh --tag <tag>

# By project
~/.claude/kb/search-kb.sh --project <name>

# Full-text keyword
~/.claude/kb/search-kb.sh -- <keyword>

# List all tags
~/.claude/kb/search-kb.sh --list-tags

# Full entry content
~/.claude/kb/search-kb.sh --tag <tag> --full
```

### Entry Lifecycle

```
active (default) → stale (expires date passed) → promoted (graduated to skill/reference) or pruned (deleted)
```

- `expires` defaults to 90 days from creation. For foundational entries, set `expires: 2099-01-01`.

### Auditing (monthly)

```bash
~/.claude/kb/audit-kb.sh --dry-run   # preview stale entries
~/.claude/kb/audit-kb.sh --apply     # mark stale entries
```

**Promotion:** When an entry's lessons are fully captured in a skill or reference file, set `status: promoted` and `promoted_to: <path>`.

### Adding New Entries

Use `~/.claude/kb/TEMPLATE.md`. Fill in frontmatter, set `expires` to 90 days out, write to `kb/entries/YYYY-MM-DD-<slug>.md`. The end-session skill does this automatically.

## Learning System

### Error Logs (`~/.claude/learnings/YYYY-MM-DD.log`)

Tracks mistakes and false starts for learning analysis.

### Learning Analyzer (`learning-analyzer` agent)

Reviews session errors and updates skills:
1. Read error logs
2. Categorize by type
3. Extract generalizable patterns
4. Suggest AGENTS.md updates
5. Surface recurring issues for skill development

Use after significant debugging sessions or when catching repeated mistakes.

## Ideas & Brainstorming

Capture ideas that don't fit elsewhere in `~/.claude/ideas/`.

Update status when explored:
- `Pending investigation` → `Investigated, chose path X because Y`
- Move to MEMORY.md if confirmed pattern
- Archive if rejected with reason

## Inter-Session Workflow

1. **Start new session**: Check `MEMORY.md` for context
2. **Discover pattern**: Add to MEMORY.md with "confirmed" marker
3. **Correct memory**: Update existing entry with date + explanation
4. **End session**: Archive to KB + log learnings
5. **Next session**: Learnings from previous inform approach
