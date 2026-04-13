---
name: learnings
description: Manage and query the learnings database. Captures corrections, preferences, and learned information to prevent repeated mistakes. Workflow: capture → review → promote/discard.
model: opencode-go/kimi-k2.5
---

# Learnings Manager

Manages the structured learnings database for corrections and preferences with a lifecycle: capture → review → promote to AGENTS.md or discard.

## LIFECYCLE

```
Correction → learnings.json (status: pending_review)
                    ↓
            End of session review
                    ↓
    ┌───────────────┴───────────────┐
    ↓                               ↓
promote to AGENTS.md           discard
    ↓
Update AGENTS.md (or AGENTS.<topic>.md)
```

## QUICK START

```bash
# After being corrected, capture it immediately
@learnings capture

# Or capture specific topic
@learnings capture "config structure"

# Review pending learnings at end of session
@learnings review

# Promote important learnings to AGENTS.md
@learnings promote <id> [target]

# Search before making assumptions
@learnings search "dotfiles"
```

## COMMANDS

### Capture Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `@learnings capture` | Capture last correction | Immediately after being corrected |
| `@learnings capture "topic"` | Capture specific topic | When you want to name it |
| `@learnings quick-add` | Interactive capture | Easiest way - asks questions |

### Review Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `@learnings review` | List pending_review learnings | End of session |
| `@learnings review --all` | List ALL learnings | Full audit |
| `@learnings promote <id>` | Move learning to AGENTS.md | Important patterns |
| `@learnings discard <id>` | Mark as not worth promoting | Noise learnings |

### Query Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `@learnings search "term"` | Full-text search | `@learnings search "config"` |
| `@learnings tags "tag"` | Search by tag | `@learnings tags "dotfiles"` |
| `@learnings list` | List all entries | `@learnings list` |
| `@learnings list --category config` | List by category | Filter by category |
| `@learnings show "id"` | Show specific entry | `@learnings show opencode-config-structure` |

### Management Commands

| Command | Purpose |
|---------|---------|
| `@learnings edit` | Open learnings.json in editor |
| `@learnings validate` | Check JSON syntax |
| `@learnings commit` | Commit changes to dotfiles |

## ENTRY FORMAT

```json
{
  "id": "short-descriptive-id",
  "timestamp": "2026-04-13",
  "status": "pending_review",
  "promotedTo": null,
  "context": "When discussing/working on...",
  "whatIGotWrong": "I incorrectly assumed...",
  "correction": "The correct understanding is...",
  "details": {},
  "tags": ["category", "topic"]
}
```

**Status values:**
- `pending_review` - New entry, needs review
- `promoted` - Moved to AGENTS.md
- `discarded` - Not worth promoting

## CATEGORIES

| Category | Purpose | Example |
|----------|---------|---------|
| `misconceptions` | Things I got wrong | "Thought X was in Y location" |
| `preferences` | Your workflow choices | "Prefer conventional commits" |
| `config` | Configuration details | "Config is in .opencode/" |
| `commands` | Command corrections | "Use gh pr create not git pr" |
| `patterns` | Code patterns learned | "Use asProvider().get() for protobuf" |
| `workflows` | Workflow corrections | "Check git status before branching" |

## WHEN TO CAPTURE

### Capture Immediately When:

1. **You correct me** → `@learnings capture`
2. **You state a preference** → `@learnings quick-add`
3. **I make a wrong assumption** → `@learnings capture "topic"`
4. **New pattern discovered** → `@learnings capture "pattern name"`

### Promote to AGENTS.md When:

1. Pattern that should be followed consistently
2. Workflow that prevents common mistakes
3. Convention that new team members should know
4. Anti-pattern that should be avoided

### Discard When:

1. One-off mistake unlikely to repeat
2. Very specific to current context
3. Already captured elsewhere (e.g., in code)

## WORKFLOW

### Daily Usage

```
1. Start session
2. You ask about X
3. I search: @learnings search "X"
4. Found relevant entry → Use it
5. No entry found → Proceed carefully
6. You correct me → @learnings capture
```

### End of Session

```
1. @learnings review
2. For each pending_review entry:
   - @learnings promote <id>     → if worth keeping
   - @learnings discard <id>      → if noise
3. @learnings commit              → save changes
```

## LOCATION

```
~/.config/opencode/learnings/learnings.json
```

**Source of truth**: `~/Code/shell/dotfiles/opencode/.opencode/learnings/learnings.json`

## INTEGRATION WITH AGENTS.MD

Learnings that are promoted get added to relevant AGENTS files:

| Learning type | Target file |
|--------------|-------------|
| Workflow | `AGENTS.workflows.md` or `AGENTS.md` |
| Pattern | `AGENTS.conventions.md` or project `AGENTS.md` |
| Config | `AGENTS.config.md` |
| Command | `AGENTS.commands.md` |

Promoted learnings should be written as instructions/conventions, not as "what I got wrong" narratives.

## ANTI-PATTERNS

| Never | Instead |
|-------|---------|
| Capture without context | Include when/where it applies |
| Keep everything | Review and discard at end of session |
| Never promote | Share valuable learnings via AGENTS.md |
| Ignore the lifecycle | Let learnings pile up unchecked |