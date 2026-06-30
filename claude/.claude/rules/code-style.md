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

## Kotlin Test Style (JVM / JUnit5 projects)

- **Assertions:** Check existing test files first — follow repo pattern.
  - Some projects use `kotlin.test` (`kotlin.test.assertEquals`, `kotlin.test.assertTrue`, etc.)
  - Some projects use JUnit5 directly (`org.junit.jupiter.api.Assertions.assertEquals`, etc.)
  - **REDACTED:** JUnit 5 directly (no `kotlin.test` dependency)
  - **REDACTED:** `kotlin.test`
- **`@Test` annotation:** `org.junit.jupiter.api.Test` (not `kotlin.test.Test`)
- **No wildcard imports** — explicit only; never `import kotlin.test.*` or `import org.junit.jupiter.api.Assertions.*`

### Mockk unit test structure (REDACTED)

- **Class-level:** mocks with default stubs (returns empty/false) + service under test
- **Per-test:** all data variables — `experimentId`, `instanceId`, `qualified`, etc. declared inside test, never class fields
- **Test data objects:** single `data` variable of full type, reference `data.field` in verify — do NOT split into separate field variables
  ```kotlin
  val data = InsightsAndRecommendations(
      insights = mapOf("INSTANCE" to listOf<Any>()),
      recommendations = emptyMap(),
  )
  coEvery { fetchService.insightsAndRecommendations(instanceId, qualified, baselineBucketId) } returns data
  // ...
  coVerify { repo.upsert(Learnings(experimentId, instanceId, qualified, data.insights, emptyMap())) }
  ```
- **Structure:** `// Given / When / Then` comments in every test

## Kotlin Boolean Naming
- Properties: NO `is` prefix — use `qualified`, `beforeMinDuration`, `sampleSizeCallable`
- Local variables: NO `is` prefix — use `confirmed`, `skewPrevented`
- Kotlin auto-generates `is` getters; adding it yourself creates `isIsFoo()` in Java interop

## Kotlin File Naming (from kotlinx.coroutines, OkHttp, Ktor)
- **Concern-named files** for top-level functions — `Errors.kt`, `Transform.kt`, not `ReadoutUtils.kt`
- **No `*Extensions.kt`** — fold extension functions into concern-named files
- **`Real*` prefix** for internal implementations of public interfaces (`RealReadoutCaptor`)
- **`internal/` subdirectory** for implementation details hidden from module consumers
- **File-level factory functions** over companion object factories — `fun ReadoutClient(...): ReadoutClient` at file level

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

## Java Logging (Lombok)
Use `@Slf4j` annotation — no manual `Logger` fields.

## Java `final` — Use Liberally
Apply `final` to all method parameters and all local variable declarations unless the variable is intentionally reassigned.

```java
// Good
public void process(final String id, final int count) {
    final MetricConfig config = metricConfigMap.get(id);
    final boolean skip = shouldSkip(config);
}

// Bad — missing final on params and locals
public void process(String id, int count) {
    MetricConfig config = metricConfigMap.get(id);
    boolean skip = shouldSkip(config);
}
```

Exception: loop variables being incremented (`for (int i = 0; ...)`), variables reassigned in branches.

## Java Braces
Always use braces for `if`, `else`, `for`, `while` — even single-line bodies.

## General Principles
- Prefer immutability (`val` over `var`, immutable collections)
- Explicit over implicit
- Fail fast with clear error messages
- Functions small and focused
- Clear names — no abbreviations