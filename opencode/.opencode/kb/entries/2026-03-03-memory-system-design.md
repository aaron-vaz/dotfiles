---
title: "Building Global Conversation Archives"
date: 2026-03-03
project: claude-misc
tags: ["memory", "compaction", "search", "architecture", "knowledge-management"]
status: active
promoted_to: ""
outcome: "Created searchable conversation archive system to reduce token usage and preserve context"
expires: 2026-06-04
---

## Context
User asked how to build memory for Claude Code so less is forgotten during compaction. Wanted to store conversations in markdown files to make them searchable and token-efficient.

## Key Decisions

**Directory structure:**
- `~/.claude/conversations/by-topic/` - Organized by category for browsing
- `~/.claude/conversations/by-date/` - Organized chronologically for time-based search
- `INDEX.md` - Quick reference and search guide

**Why this structure:**
- Topic-based browsing for related problems
- Date-based for "what did we discuss last week?"
- Symlinks between by-topic and by-date for dual access
- Tags for cross-cutting searches

**Token efficiency:**
- Archive full conversations to markdown
- Use grep/glob to search when needed
- Only load relevant archived conversations into context
- Keeps working context lean

## Solution

Created:
1. Directory structure at `~/.claude/conversations/`
2. INDEX.md with usage guide and search patterns
3. TEMPLATE.md for consistent archiving
4. Example archive (this file)

Search patterns:
```bash
# Keyword search
grep -r "search term" ~/.claude/conversations/

# Tag search
grep -r "Tags:.*debugging" ~/.claude/conversations/

# Topic search
grep -r "gradle" ~/.claude/conversations/by-topic/jvm-builds/

# Recent conversations
ls -lt ~/.claude/conversations/by-date/2026-03/
```

## Code / Commands

```bash
# Create new archive
cat > ~/.claude/conversations/by-topic/<category>/YYYY-MM-DD-title.md

# Symlink to date view
ln -s ~/.claude/conversations/by-topic/<category>/YYYY-MM-DD-title.md \
      ~/.claude/conversations/by-date/YYYY-MM/YYYY-MM-DD-title.md

# Search examples
grep -r "metric ID" ~/.claude/conversations/
grep -r "Tags:.*jvm" ~/.claude/conversations/ | head -5
```

## Lessons Learned

**When to archive:**
- After solving complex problems that might recur
- After architectural discussions with reusable insights
- When user explicitly says "save this" or "document this"
- End of significant multi-turn explorations

**What to include:**
- Enough context to understand the problem without reading full conversation
- Key decisions and why alternatives were rejected
- Working code/commands
- Tags for future discoverability

**Integration with existing systems:**
- Memory files (`~/.claude/projects/<path>/memory/`) - active project knowledge
- Session tracking (`~/.claude/sessions/`) - current work context
- Conversations (`~/.claude/conversations/`) - historical searchable archive
- References (`~/.claude/references/`) - how-to guides and syntax docs

## Related
- Updated CLAUDE.md (next step) to document this system
- Complements existing memory system in `~/.claude/projects/`
- Different from session tracking (archived vs current)
