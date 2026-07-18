# Memory System Reference

## Knowledge Base

Curated feature/session knowledge at `~/.claude/kb/entries/`.

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

Use `~/.claude/kb/TEMPLATE.md`. Fill in frontmatter, set `expires` to 90 days out, write to `kb/entries/YYYY-MM-DD-<slug>.md`.

Or invoke `/session-archiver` to archive a valuable session manually.

## Information Placement

1. **Cross-project rules/preferences** → `~/.claude/AGENTS.md`
2. **Feature-specific knowledge** → KB entry (`~/.claude/kb/entries/`)
3. **Project-specific conventions** → `<project>/AGENTS.md`

## Ideas & Brainstorming

Capture ideas that don't fit elsewhere in `~/.claude/ideas/`.

Update status when explored:
- `Pending investigation` → `Investigated, chose path X because Y`
- Archive if rejected with reason
