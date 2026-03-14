# OpenCode Global Instructions

Personal coding preferences and workflow conventions.

## Knowledge Base

Search for relevant patterns from past sessions:

```bash
~/.config/opencode/kb/search-kb.sh --medium          # Medium output
~/.config/opencode/kb/search-kb.sh --tag kotlin     # Search by tag
~/.config/opencode/kb/search-kb.sh "error pattern"  # Full-text search
```

## Code Style

- **No comments** unless explicitly requested
- Use existing code patterns and conventions from the project
- Follow project's existing style, naming, and architecture

## Build/Test Commands

- Run lint and typecheck after changes (e.g., `./gradlew spotlessCheck`, `npm run lint`)
- Run tests after edits if requested or before committing

## Git Workflow

- Use conventional commits
- Prefer `git -C <dir>` for cross-directory operations
- Use `gh` CLI for GitHub operations

## Debugging Approach

- Reference KB for past patterns and solutions
- Use systematic debugging methodology
- Check existing code for similar patterns before implementing new ones

## Project-Specific

- Read `AGENTS.md` or `CLAUDE.md` in project root for project-specific instructions
- Auto-detect build system from project files (Gradle, npm, cargo, etc.)
