# Learnings & Corrections

System for capturing corrections, preferences, and learned information to prevent repeated mistakes.

## OVERVIEW

The learnings system captures:
- **Misconceptions** - Things I got wrong that need correction
- **Preferences** - User preferences and workflow choices  
- **Config details** - Configuration structure and specifics
- **Commands** - Command corrections and clarifications
- **Patterns** - Code patterns and conventions learned
- **Workflows** - Workflow corrections and improvements

## LOCATION

```
~/.config/opencode/learnings/
└── learnings.json          # Structured learnings database
```

## STRUCTURE

```json
{
  "version": "1.0",
  "lastUpdated": "2026-03-14",
  "categories": {
    "misconceptions": {
      "description": "Things I got wrong that need correction",
      "entries": []
    },
    "preferences": {
      "description": "User preferences and workflow choices",
      "entries": []
    },
    "config": {
      "description": "Configuration details and structure",
      "entries": [
        {
          "id": "unique-id",
          "timestamp": "2026-03-14",
          "context": "What situation this applies to",
          "whatIGotWrong": "Description of the mistake",
          "correction": "The correct understanding",
          "details": { /* Additional structured data */ },
          "tags": ["tag1", "tag2"]
        }
      ]
    },
    "commands": { "description": "...", "entries": [] },
    "patterns": { "description": "...", "entries": [] },
    "workflows": { "description": "...", "entries": [] }
  }
}
```

## CURRENT LEARNINGS

### Config Structure

**Learning:** `opencode-config-structure`

| Aspect | Detail |
|--------|--------|
| **Context** | Understanding where opencode config files live |
| **What I got wrong** | Confused about dotfiles structure - thought config was directly in `dotfiles/opencode/` |
| **Correction** | Config lives in `~/Code/shell/dotfiles/opencode/.opencode/` (note the `.opencode/` subdirectory) |
| **Actual location** | `/Users/aaronvaz/Code/shell/dotfiles/opencode/.opencode/` |
| **Symlink target** | `~/.config/opencode/` |
| **Key files** | `AGENTS.md`, `settings.json`, `opencode.json` |
| **Install** | `install.sh` symlinks individual files from `.opencode/` to `~/.config/opencode/` |

```bash
# Correct paths
~/Code/shell/dotfiles/opencode/.opencode/AGENTS.md     # Source
~/.config/opencode/AGENTS.md                           # Symlinked

# To update
cd ~/Code/shell/dotfiles/opencode/.opencode
# Edit files...
git add -A && git commit -m "config: ..." && git push
```

## ADDING NEW LEARNINGS

### Method 1: Quick Capture (Recommended)

Use immediately after being corrected:

```bash
@learnings capture              # Capture last correction
@learnings capture "topic"      # Name the topic
@learnings quick-add            # Interactive mode
```

### Method 2: Manual Edit

For complex entries or bulk edits:

```bash
@learnings edit                 # Open in $EDITOR
@learnings validate             # Check syntax
@learnings commit               # Commit changes
```

### Entry Template

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

## USING LEARNINGS

Before making assumptions, check:

1. **Search learnings** for relevant context
2. **Search KB** for patterns: `~/.config/opencode/kb/search-kb.sh "pattern"`
3. **Verify** if unsure - don't repeat known mistakes

## COMMANDS

Use `@learnings` or `skill(name="learnings")`:

### Capture Commands

| Command | Purpose |
|---------|---------|
| `@learnings capture` | Capture last correction (immediate) |
| `@learnings capture "topic"` | Capture specific topic |
| `@learnings quick-add` | Interactive mode - easiest way |

### Query Commands

| Command | Purpose |
|---------|---------|
| `@learnings search "term"` | Full-text search |
| `@learnings tags "tag"` | Search by tag |
| `@learnings list` | List all entries |
| `@learnings list --category X` | List by category |
| `@learnings show "id"` | Show specific entry |

### Management

| Command | Purpose |
|---------|---------|
| `@learnings edit` | Open in editor |
| `@learnings validate` | Check JSON syntax |
| `@learnings commit` | Commit to dotfiles |

## WORKFLOW

### Capture Immediately After Correction

```
You: "No, the config is in .opencode/ not opencode/"
Me: "Got it - capturing that"

@learnings capture "config location"
[Auto-fills from context, you confirm, then commit]
```

### Search Before Making Assumptions

```
You: "Work on my opencode config"
Me: [Before assuming location]

@learnings search "config"
→ Found: opencode-config-structure
→ Use correct path: ~/Code/shell/dotfiles/opencode/.opencode/
```
