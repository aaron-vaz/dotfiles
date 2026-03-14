---
title: "Tagged Memory System Design"
date: 2026-03-03
project: claude-misc
tags: ["architecture", "knowledge-management", "memory-system", "learning-system", "token-efficiency"]
status: active
promoted_to: ""
outcome: "Created comprehensive tagged memory system with search tools and CLAUDE.md integration"
expires: 2026-06-04
---

## Context

User requested to extend the existing conversation archive tagging system to the project memory system for filtering by relevance. The goal was to create a unified, searchable knowledge system that enables both Claude and learning-analyzer to discover patterns across projects efficiently.

## Key Decisions

### Decision 1: Tag Schema Matching Conversation Archives
**Rationale:** Consistency between memory and conversation systems reduces cognitive load and enables unified search patterns.

**Tag Categories:**
- **Domain:** `#jvm`, `#kotlin`, `#java`, `#sql`, `#trino`, `#testing`, `#experimentation`
- **Activity:** `#debugging`, `#refactoring`, `#architecture`, `#ci-cd`, `#build`, `#deployment`
- **Tool:** `#git`, `#gradle`, `#maven`, `#github`, `#jira`, `#confluence`
- **Relevance:** `project-specific`, `cross-project`, `tool-specific`

### Decision 2: MEMORY.md as Index (200-line limit)
**Rationale:** First 200 lines of MEMORY.md are always loaded into context. Using it as an index rather than detailed storage maximizes token efficiency while providing quick navigation.

**Structure:**
- Quick reference links to topic files
- Cross-project pattern summaries
- Brief project-specific notes only
- Move detailed memories to separate files

### Decision 3: Topic-Based File Organization
**Rationale:** Separates concerns, enables focused loading, matches how people think about problems.

**Files:**
- `debugging.md` - Error patterns and solutions
- `architecture.md` - Design decisions and tradeoffs
- `patterns.md` - Build/test patterns
- `workflows.md` - Git/automation workflows
- `tools.md` - Tool-specific usage
- `domain-knowledge.md` - Business logic concepts

### Decision 4: grep-Based Search with Helper Script
**Rationale:** Searching via grep doesn't load files into context until needed. Shell script provides user-friendly interface while preserving token efficiency.

**Implementation:** `~/.claude/scripts/search-memories.sh`
- Tag filtering (`--tag debugging`)
- Relevance filtering (`--relevance cross-project`)
- Keyword search
- Project-specific search
- List tags/projects helpers

## Solution / Outcome

### What Was Built

1. **Memory Templates**
   - Created template structure in `~/.claude/projects/-Users-avaz-Code-claude-misc/memory/`
   - MEMORY.md index file
   - 6 topic-specific template files with tag format

2. **Search Tool**
   - `~/.claude/scripts/search-memories.sh` (executable)
   - Supports multiple search modes
   - Color-coded output
   - Context snippets for keyword searches

3. **Documentation**
   - Updated `~/.claude/CLAUDE.md` with complete memory system section
   - Added quick-start section for common tasks
   - Added troubleshooting reference
   - Updated references to include search script

4. **CLAUDE.md Quality Improvements**
   - Ran claude-md-improver skill
   - Score: 94/100 → 96/100 (Grade A)
   - Enhanced discoverability and navigation

### Integration Points

**Learning-Analyzer Integration:**
- Searches memories for cross-project patterns
- Patterns in 2+ projects → update relevance to cross-project
- Patterns in 3+ projects → promote to global CLAUDE.md
- Links related memories and conversations

**Token Efficiency:**
- Only MEMORY.md (200 lines) always loaded
- Topic files loaded on-demand when relevant
- Search via grep doesn't load into context
- Keeps working context lean

**Workflow Integration:**
- end-session skill archives valuable sessions
- learning-analyzer promotes patterns automatically
- claude-md-improver suggests additions
- User can manually add via `#` shortcut

## Code / Commands

### Creating Memory Structure
```bash
mkdir -p ~/.claude/projects/<project-path>/memory/
```

### Memory Tag Format
```markdown
# Memory Title

**Relevance:** cross-project
**Last Updated:** YYYY-MM-DD

## Pattern
...
```

### Search Examples
```bash
# Find debugging memories
~/.claude/scripts/search-memories.sh --tag debugging

# Find cross-project patterns
~/.claude/scripts/search-memories.sh --relevance cross-project

# Keyword search
~/.claude/scripts/search-memories.sh "gradle build"

# List all tags
~/.claude/scripts/search-memories.sh --list-tags

# Manual grep
grep -r "Tags:.*#debugging" ~/.claude/projects/*/memory/
```

### CLAUDE.md Quick Start
```markdown
## Quick Start (Common Tasks)

| Task | Command/Action |
|------|----------------|
| Search memories | `~/.claude/scripts/search-memories.sh --tag <tag>` |
| Search conversations | `grep -r "term" ~/.claude/conversations/` |
```

## Lessons Learned

### Pattern: Semantic Organization Over Chronological
Memory organized by topic (debugging, architecture) rather than by date makes it easier to find relevant patterns when facing similar problems. MEMORY.md index provides navigation without needing to load all files.

### Pattern: Tag Consistency Across Systems
Using same tag schema for both conversations and memories enables unified search patterns. Learning-analyzer can query both systems with same grep patterns.

### Pattern: Relevance as Promotion Path
Starting patterns as `project-specific` and promoting to `cross-project` creates natural knowledge evolution. Learning-analyzer detects patterns automatically and updates relevance, eventually promoting to global CLAUDE.md.

### Pattern: Token-Efficient Search
grep-based search allows filtering thousands of lines without loading into context. Only load specific files after finding matches. Keeps baseline context minimal.

### Anti-Pattern: Verbose Memory Files
Initial instinct was to create detailed explanations in memory files. Better approach: concise, actionable entries. Let the conversation archives hold verbose discussions; memories should be quick reference.

### Integration Insight: Memory → Conversation → Learning → CLAUDE.md
Knowledge flows through the system:
1. Pattern discovered → Written to project memory
2. Valuable session → Archived to conversations
3. Learning-analyzer → Searches both, identifies cross-project
4. Cross-project pattern → Promoted to global CLAUDE.md

This creates feedback loop where local discoveries become global knowledge.

## Related

### Files Created/Modified
- `~/.claude/projects/-Users-avaz-Code-claude-misc/memory/MEMORY.md`
- `~/.claude/projects/-Users-avaz-Code-claude-misc/memory/debugging.md`
- `~/.claude/projects/-Users-avaz-Code-claude-misc/memory/architecture.md`
- `~/.claude/projects/-Users-avaz-Code-claude-misc/memory/patterns.md`
- `~/.claude/projects/-Users-avaz-Code-claude-misc/memory/workflows.md`
- `~/.claude/projects/-Users-avaz-Code-claude-misc/memory/tools.md`
- `~/.claude/projects/-Users-avaz-Code-claude-misc/memory/domain-knowledge.md`
- `~/.claude/scripts/search-memories.sh`
- `~/.claude/CLAUDE.md` (added memory section, quick-start, troubleshooting)

### Related Systems
- Conversation Archives: `~/.claude/conversations/LEARNING-SYSTEM.md`
- Session Tracking: `~/.claude/sessions/current.md`
- Learning System: `~/.claude/learnings/YYYY-MM-DD.log`

### Next Steps
- Populate memory files as patterns discovered in actual work
- Test search script across multiple projects
- Monitor learning-analyzer pattern promotion
- Consider migration tool to extract patterns from existing conversation archives into memories
