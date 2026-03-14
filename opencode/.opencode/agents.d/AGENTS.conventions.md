# Conventions & Anti-Patterns

## ANTI-PATTERNS (Never Do)

| Never | Instead |
|-------|---------|
| `as any` | Fix types properly |
| `@ts-ignore`, `@ts-expect-error` | Fix types properly |
| Empty catch blocks `catch(e) {}` | Handle errors explicitly |
| Deleting failing tests | Fix the underlying issue |
| Shotgun debugging | Systematic hypothesis testing |
| `git push --force` on main/master | Never force push to protected branches |
| `git commit --amend` on pushed commits | Create new commit |
| Commit without explicit request | Only commit when user asks |
| Assume version numbers | Verify via web search/catalogs |
| Assume API signatures | Check docs with Context7 |
| Assume default values | Verify from actual files |

### Code Anti-Patterns

```kotlin
// WRONG: Suppress types
val result = something() as any

// WRONG: Empty catch
try {
    doSomething()
} catch(e) {}

// WRONG: Ignore warnings
// @ts-ignore
someCode()

// RIGHT: Fix properly
val result: ExpectedType = requireNotNull(something())

// RIGHT: Handle errors
try {
    doSomething()
} catch(e: Exception) {
    logger.error("Failed", e)
    throw e
}
```

## CONVENTIONS

### Test Style

```kotlin
// Use Given/When/Then pattern
@Test
fun `should return user when id exists`() {
    // Given
    val userId = 123L
    val expectedUser = User(userId, "John")
    every { repository.findById(userId) } returns expectedUser

    // When
    val result = service.getUser(userId)

    // Then
    assertEquals(expectedUser, result)
}
```

- Co-located test files: `src/main/kotlin/User.kt` → `src/test/kotlin/UserTest.kt`
- Never use "Arrange-Act-Assert" comments in tests

### Commit Style

```bash
# Format: type(scope): description
feat(api): add user authentication
fix(ui): resolve button alignment issue
refactor(core): extract validation logic
docs(readme): update installation steps
test(unit): add coverage for UserService
chore(deps): upgrade gradle plugins
```

### Worktree Convention

```bash
.worktrees/
├── feat-user-auth/      # Feature branch: feat-user-auth
├── fix-login-bug/       # Fix branch: fix-login-bug
└── refactor-api/        # Refactor branch: refactor-api
```

### Config Symlinks

```bash
# All configs symlinked to git repo
~/.config/opencode → ~/Code/shell/dotfiles/opencode
~/.gitconfig → ~/Code/shell/dotfiles/git/gitconfig.symlink
~/.gitignore → ~/Code/shell/dotfiles/git/gitignore.symlink
```

## CODE STYLE

### General Rules

- **No comments** unless explicitly requested
- Use existing code patterns and conventions from the project
- Follow project's existing style, naming, and architecture
- Match existing patterns in disciplined codebases
- Propose approach first in chaotic/legacy codebases

### Naming Conventions

| Language | Convention |
|----------|------------|
| Kotlin | camelCase for functions/properties, PascalCase for classes |
| TypeScript | camelCase for functions/variables, PascalCase for components |
| Files | Match language convention, `kebab-case.kt` for Kotlin |

### Import Order

Follow language-specific conventions. For Kotlin:
1. Standard library
2. Third-party libraries
3. Project imports
4. Same-package imports