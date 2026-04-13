# Workflows Reference

## BUILD/TEST WORKFLOW

### Project Type Detection

| Project Files | Build System |
|---------------|--------------|
| `build.gradle.kts`, `settings.gradle.kts` | Gradle (Kotlin DSL) |
| `build.gradle`, `settings.gradle` | Gradle (Groovy DSL) |
| `pom.xml` | Maven |
| `package.json` | npm |
| `pnpm-lock.yaml` | pnpm |
| `Cargo.toml` | Cargo |
| `Makefile` | Make |

### Commands by Project Type

#### Gradle (Kotlin DSL)
```bash
./gradlew build                  # Full build
./gradlew test                   # Run tests
./gradlew spotlessCheck          # Lint/format check
./gradlew spotlessApply          # Auto-format
./gradlew ktlintCheck            # Kotlin lint (optional - only if ktlint plugin configured)
```

#### npm/pnpm
```bash
npm run lint                     # Lint check
npm test                         # Run tests
npm run build                    # Production build
pnpm lint && pnpm test           # pnpm equivalents
```

### Build Verification

**Always run after changes:**
1. Lint/typecheck (`./gradlew spotlessCheck` or `npm run lint`)
2. Tests if requested or before committing
3. Verify build passes before marking complete

## GIT WORKFLOW

### Conventional Commits

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code refactoring |
| `docs` | Documentation only |
| `test` | Adding/modifying tests |
| `chore` | Maintenance tasks |

Format: `type(scope): description`

### Git Worktrees for Parallel Work

```bash
# Create worktree for new feature
git worktree add -b feat-my-feature .worktrees/feat-my-feature main

# List worktrees
git worktree list

# Work in worktree (shares .git directory)
cd .worktrees/feat-my-feature
# Make changes, commit, push

# Clean up after merge
git worktree remove .worktrees/feat-my-feature
git branch -d feat-my-feature
```

**Rules:**
- Worktrees go in `.worktrees/<branch-name>`
- Changes to tracked files visible across all worktrees
- Add `.worktrees/` to `.gitignore`

### GitHub CLI Usage

```bash
gh pr create --title "feat: description" --body "..."
gh pr list --state open
gh pr view 123
gh pr merge 123 --squash
gh issue create --title "Bug: ..."
gh issue list --state open
```

## DEBUGGING WORKFLOW

### Step-by-Step

1. **Reference KB first** for past patterns and solutions
2. **Identify the symptom** - what's failing?
3. **Find similar patterns** in existing code
4. **Hypothesize** the root cause
5. **Test hypothesis** with minimal changes
6. **Fix root cause, not symptom**
7. **Verify fix** with tests

### After 3 Failed Attempts

1. **STOP** all further edits immediately
2. **REVERT** to last known working state
3. **DOCUMENT** what was attempted and what failed
4. **CONSULT** Oracle with full failure context
5. If Oracle cannot resolve → **ASK USER** before proceeding

### Never Do

- Shotgun debugging (random changes hoping something works)
- Delete failing tests to "pass"
- Leave code in broken state after failures
- Suppress errors (`as any`, `@ts-ignore`, empty catch)

## KNOWLEDGE BASE

```bash
# Search patterns from past sessions
~/.config/opencode/kb/search-kb.sh --medium          # Medium output
~/.config/opencode/kb/search-kb.sh --tag kotlin     # Search by tag
~/.config/opencode/kb/search-kb.sh "error pattern"  # Full-text search
```