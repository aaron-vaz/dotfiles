# Memory System Reference

## Knowledge Base

Curated feature/session knowledge in two stores: private `~/.agents/kb/private/` (default for new entries) and public `~/.agents/kb/entries/` (only entries naming nothing employer- or private-product-specific).

### Search

```bash
# By tag
~/.agents/kb/search-kb.sh --tag <tag>

# By project
~/.agents/kb/search-kb.sh --project <name>

# Full-text keyword
~/.agents/kb/search-kb.sh -- <keyword>

# List all tags
~/.agents/kb/search-kb.sh --list-tags

# Full entry content
~/.agents/kb/search-kb.sh --tag <tag> --full
```

### Design

- **Flat entry directories, no topic subdirectories.** Tags do the categorisation, because forcing one category on a cross-cutting entry creates friction.
- **A TSV index instead of parsing frontmatter on every search.** `index.tsv` is a generated cache that rebuilds when any entry is newer than it, and it is gitignored (`git add kb/index.tsv` is rejected for that reason). Grepping one TSV is faster than parsing dozens of YAML headers.
- **Shell scripts only.** `search-kb.sh` and `audit-kb.sh` need nothing beyond what a Claude Code hook already needs.
- **SessionStart output is injected as a system reminder, so it stays short and silent when empty.** The hook runs `search-kb.sh --project <repo> --brief`, caps it with `head -8`, and prints a header only when something matched.
- **Expiry forces review.** Entries default to 90 days; foundational ones use `expires: 2099-01-01` (see Entry Lifecycle).
- **One-off migration scripts are written, run and deleted in the same session.** They do not stay in the repository.

### Entry Lifecycle

```
active (default) → stale (expires date passed) → promoted (graduated to skill/reference) or pruned (deleted)
```

- `expires` defaults to 90 days from creation. For foundational entries, set `expires: 2099-01-01`.

### Auditing (monthly)

```bash
~/.agents/kb/audit-kb.sh --dry-run   # preview stale entries
~/.agents/kb/audit-kb.sh --apply     # mark stale entries
```

**Promotion:** When an entry's lessons are fully captured in a skill or reference file, set `status: promoted` and `promoted_to: <path>`.

### Adding New Entries

Use `~/.agents/kb/TEMPLATE.md`. Fill in frontmatter, set `expires` to 90 days out, write to `kb/private/YYYY-MM-DD-<slug>.md` (move to `kb/entries/` only if publishable).

Or invoke `/session-archiver` to archive a valuable session manually.

## Information Placement

1. **Cross-project rules/preferences** → `~/.claude/AGENTS.md`
2. **Feature-specific knowledge** → KB entry (`~/.agents/kb/private/` by default; `entries/` only if publishable)
3. **Project-specific conventions** → `<project>/AGENTS.md`

## Ideas & Brainstorming

Capture ideas that don't fit elsewhere in `~/.claude/ideas/`.

Update status when explored:
- `Pending investigation` → `Investigated, chose path X because Y`
- Archive if rejected with reason
