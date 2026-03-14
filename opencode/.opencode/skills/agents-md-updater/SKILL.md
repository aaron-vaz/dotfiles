---
name: agents-md-updater
description: Use when implementing features or making architectural changes that may require documentation updates.
model: haiku
---

# AGENTS.md Documentation Sync

After making code changes, check if documentation needs updating.

## Files to Check

1. **Project AGENTS.md** (`./AGENTS.md` or `./.claude/CLAUDE.md`)
   - Module structure changes
   - New build commands
   - Architecture updates
   - Code pattern changes

2. **Global AGENTS.md** (`~/.config/opencode/AGENTS.md` or `~/.claude/CLAUDE.md`)
   - New workflow preferences
   - Updated tool versions
   - New patterns or idioms learned

## When to Update

| Change Type | Update |
|-------------|--------|
| New module added | Module structure section |
| New annotation/API | Code patterns section |
| Build process change | Build commands section |
| New dependency pattern | Architecture section |
| Test framework change | Testing section |

## Checklist

After implementation:
- [ ] Do build commands still work?
- [ ] Is module structure accurate?
- [ ] Are code examples still valid?
- [ ] Any new patterns worth documenting?
- [ ] Are there new commands users should know?

## Style Rules

- Keep concise and actionable
- Use tables for structured data
- Include realistic code examples
- Use ASCII directory trees for file structures
- Prefer bullet points over prose