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
- **Git worktrees for parallel work:**
  - Create worktrees in `.worktrees/<branch-name>` directory (e.g., `.worktrees/feat-my-feature`)
  - Use `git worktree add -b <branch> .worktrees/<branch-name> <base-branch>`
  - Worktrees share `.git` directory - changes to tracked files are visible across all worktrees
  - Clean up with `git worktree remove <path>` and `git branch -d <branch>`
  - `.worktrees/` should be in `.gitignore`

## Tool Verification Over Training Data

- **NEVER assume version numbers** - always verify via web search, package repositories, or version catalogs
- **NEVER assume API signatures or imports** - check actual docs or source code with Context7 or web search
- **NEVER assume default values or configuration** - verify from actual files or documentation
- Training data is stale; tools provide current information
- When unsure about an external library, use `websearch_web_search_exa` or `context7_resolve-library-id` + `context7_query-docs`

## Debugging Approach

- Reference KB for past patterns and solutions
- Use systematic debugging methodology
- Check existing code for similar patterns before implementing new ones

## Project-Specific

- Read `AGENTS.md` or `CLAUDE.md` in project root for project-specific instructions
- Auto-detect build system from project files (Gradle, npm, cargo, etc.)

## Dotfiles & OpenCode Configuration

**Configuration is managed via symlinks to a git repo:**

| Config | Location | Symlink Target |
|--------|----------|----------------|
| OpenCode config | `~/.config/opencode` | `/Users/aaronvaz/Code/shell/dotfiles/opencode` |
| Git config | `~/.gitconfig` | `/Users/aaronvaz/Code/shell/dotfiles/git/gitconfig.symlink` |
| Git ignore | `~/.gitignore` | `/Users/aaronvaz/Code/shell/dotfiles/git/gitignore.symlink` |

**Dotfiles repo:** `/Users/aaronvaz/Code/shell/dotfiles`

**Setup symlink (one-time):**
```bash
# Backup existing config if needed
mv ~/.config/opencode ~/.config/opencode.backup

# Create symlink
ln -s /Users/aaronvaz/Code/shell/dotfiles/opencode ~/.config/opencode
```

**When updating configs:**
1. Edit files in the dotfiles repo (not the symlinks)
2. Changes are immediately reflected via symlinks
3. Always commit and push changes:
   ```bash
   cd /Users/aaronvaz/Code/shell/dotfiles
   git add -A
   git commit -m "config: describe change"
   git push
   ```