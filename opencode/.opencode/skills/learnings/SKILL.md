---
name: learnings
description: Manage and query the learnings database. Captures corrections, preferences, and learned information to prevent repeated mistakes.
model: opencode-go/kimi-k2.5
---

# Learnings Manager

Manages the structured learnings database for corrections and preferences.

## QUICK START

```bash
# After being corrected, capture it immediately
@learnings capture

# Or capture specific topic
@learnings capture "config structure"

# Search before making assumptions
@learnings search "dotfiles"

# Interactive mode - easiest way to add
@learnings quick-add
```

## COMMANDS

### Capture Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `@learnings capture` | Capture last correction | Immediately after being corrected |
| `@learnings capture "topic"` | Capture specific topic | When you want to name it |
| `@learnings quick-add` | Interactive capture | Easiest way - asks 3 questions |
| `@learnings suggest` | Suggest based on context | When unsure what to capture |

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

## CAPTURE WORKFLOW

### Method 1: Quick-Capture (Recommended)

Use immediately after being corrected:

```
You: "No, the config is in .opencode/ not opencode/"
Me: "Got it - capturing that now"

@learnings capture "config location"

[Auto-fills from context:]
- Category: config
- Context: "Understanding opencode config structure"  
- What I got wrong: "Thought config was in opencode/ directly"
- Correction: "Config is in .opencode/ subdirectory"
- Tags: ["config", "dotfiles", "structure"]

You confirm or edit, then commit.
```

### Method 2: Interactive Mode

When you want to guide the capture:

```
@learnings quick-add

[Interactive prompts:]
1. What category? (misconceptions/preferences/config/commands/patterns/workflows)
   → config
2. Briefly, what context does this apply to?
   → "When discussing opencode file locations"
3. What was the correction or preference?
   → "Config files live in .opencode/ subdirectory"

[Auto-generates entry and shows preview]
```

### Method 3: Manual Edit

For complex entries or bulk edits:

```
@learnings edit

[Opens learnings.json in $EDITOR]
→ Add/modify entries
→ Save
→ @learnings validate
→ @learnings commit
```

## LOCATION

```
~/.config/opencode/learnings/learnings.json
```

**Source of truth**: `~/Code/shell/dotfiles/opencode/.opencode/learnings/learnings.json`

## CATEGORIES

| Category | Purpose | Example |
|----------|---------|---------|
| `misconceptions` | Things I got wrong | "Thought X was in Y location" |
| `preferences` | Your workflow choices | "Prefer conventional commits" |
| `config` | Configuration details | "Config is in .opencode/" |
| `commands` | Command corrections | "Use gh pr create not git pr" |
| `patterns` | Code patterns learned | "Use Result type for errors" |
| `workflows` | Workflow corrections | "Always run tests before commit" |

## ENTRY FORMAT

```json
{
  "id": "short-descriptive-id",
  "timestamp": "2026-03-14",
  "context": "When discussing/working on...",
  "whatIGotWrong": "I incorrectly assumed...",
  "correction": "The correct understanding is...",
  "details": {
    "field1": "value1",
    "field2": "value2"
  },
  "tags": ["category", "topic", "specific"]
}
```

## EXAMPLES

### Example 1: Config Correction

```bash
@learnings capture "config structure"
```

Generates:
```json
{
  "id": "opencode-config-structure",
  "timestamp": "2026-03-14",
  "context": "Understanding opencode config location",
  "whatIGotWrong": "Confused about dotfiles structure - thought config was in opencode/ directly",
  "correction": "Config lives in ~/Code/shell/dotfiles/opencode/.opencode/ subdirectory",
  "details": {
    "actualLocation": "/Users/aaronvaz/Code/shell/dotfiles/opencode/.opencode/",
    "symlinkTarget": "~/.config/opencode/",
    "keyFiles": ["AGENTS.md", "settings.json", "opencode.json", "oh-my-opencode.json"]
  },
  "tags": ["config", "dotfiles", "symlinks", "structure"]
}
```

### Example 2: Preference

```bash
@learnings quick-add
→ Category: preferences
→ Context: "Code style preferences"
→ Correction: "No comments unless explicitly requested"
```

Generates:
```json
{
  "id": "no-comments-default",
  "timestamp": "2026-03-14",
  "context": "Code style and documentation",
  "whatIGotWrong": "Adding comments by default",
  "correction": "Only add comments when user explicitly requests them",
  "tags": ["preferences", "code-style", "comments"]
}
```

### Example 3: Pattern

```bash
@learnings capture "test pattern"
```

Generates:
```json
{
  "id": "given-when-then-tests",
  "timestamp": "2026-03-14",
  "context": "Writing tests",
  "whatIGotWrong": "Using Arrange-Act-Assert comments",
  "correction": "Use Given/When/Then pattern without AAA comments",
  "details": {
    "example": "// Given\nval user = User(1)\n// When\nval result = service.save(user)\n// Then\nassertEquals(user, result)"
  },
  "tags": ["patterns", "testing", "kotlin"]
}
```

## WHEN TO CAPTURE

### Capture Immediately When:

1. **You correct me** → `@learnings capture`
2. **You state a preference** → `@learnings quick-add`
3. **I make a wrong assumption** → `@learnings capture "topic"`
4. **New pattern discovered** → `@learnings capture "pattern name"`

### Search First When:

1. **Before making assumptions** about config/paths/commands
2. **When unsure** about your preferences
3. **Before suggesting** workflows or patterns
4. **When I think** "I might have gotten this wrong before"

## WORKFLOW

### Daily Usage

```
1. Start session
2. You ask about X
3. I search: @learnings search "X"
4. Found relevant entry → Use it
5. No entry found → Proceed carefully
6. You correct me → @learnings capture
7. Commit at end of session or significant change
```

### End of Session

```bash
# Check if any learnings need committing
@learnings validate
@learnings commit "learnings: add config structure correction"
```

## CHECKLIST

### Before Answering:
- [ ] Search learnings for relevant context
- [ ] Check KB for patterns
- [ ] Verify against actual files if uncertain

### After Being Corrected:
- [ ] Acknowledge the correction
- [ ] Capture with `@learnings capture` or `@learnings quick-add`
- [ ] Include context, what was wrong, correction
- [ ] Add relevant tags
- [ ] Commit to dotfiles

### Categories to Check:
- [ ] Config locations → `config` category
- [ ] File paths → `config` or `misconceptions`
- [ ] Commands → `commands` category
- [ ] Workflows → `workflows` category
- [ ] Patterns → `patterns` category
- [ ] Preferences → `preferences` category

## ANTI-PATTERNS

| Never | Instead |
|-------|---------|
| Assume I remember | Check learnings.json first |
| Repeat known mistakes | Reference previous corrections |
| Guess at preferences | Query learnings or ask |
| Let corrections fade | Capture immediately |
| Capture without context | Include when/where it applies |
| Ignore tags | Use tags for discoverability |

## INTEGRATION

### With AGENTS.md

The main `AGENTS.md` references learnings in:
- "Where to Look" section
- "Before Making Assumptions" workflow
- Links to `AGENTS.learnings.md`

### With KB

```bash
# Search both systems
@learnings search "error" && ~/.config/opencode/kb/search-kb.sh "error"
```

### With Self-Review

After implementing, check:
1. Did I follow learnings?
2. Any new patterns to capture?
3. Did I repeat any mistakes?
