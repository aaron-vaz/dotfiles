# Code Style (All Languages)

## Guard Clauses
Early returns keep happy path left-aligned. Edge cases first, main logic unindented.

```
// Bad - nested happy path
if (user != null) {
    if (user.isActive) {
        if (user.hasPermission) {
            doWork(user)
        }
    }
}

// Good - guard clauses
if (user == null) return
if (!user.isActive) return
if (!user.hasPermission) return

doWork(user)
```

## PR Description Style

- **`## Summary`** — bullet list for simple PRs; named `##` sections (e.g. `## Primary`, `## Toolchain`) for complex PRs
- **`## Context`** — use when motivation isn't obvious from summary
- **Inline comments on change bullets** — parenthetical notes for rationale, constraints, caveats:
  `- **Spotless**: 7.2.1 → 8.2.1 (8.2.1 required — 8.0.0 breaks with Spring Boot 4 transitive deps)`
- **Test plan** — include only when manual verification needed post-merge (unchecked boxes); omit when covered by automated tests
- **No checked-box test plan** — no `- [x]` checklists

### Self-Annotating PRs with Inline Diff Comments

After PR creation, post inline comments on specific diff lines — rationale for non-obvious choices, constraints, areas needing careful review.

Use `gh api repos/{owner}/{repo}/pulls/{number}/reviews` with `comments` array (each with `path`, `line`, `body`) to batch-post diff comments. Separate from PR description — draws reviewer attention to specific lines.

## General Principles
- Prefer immutability (`val` over `var`, immutable collections)
- Explicit over implicit
- Fail fast with clear error messages
- Functions small and focused
- Clear names — no abbreviations