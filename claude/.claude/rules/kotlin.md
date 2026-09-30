---
paths:
  - "**/*.kt"
  - "**/*.kts"
---

# Kotlin Code Style

## Kotlin Test Style (JVM / JUnit5 projects)

- **Assertions:** Check existing test files first — follow repo pattern.
  - Some projects use `kotlin.test` (`kotlin.test.assertEquals`, `kotlin.test.assertTrue`, etc.)
  - Some projects use JUnit5 directly (`org.junit.jupiter.api.Assertions.assertEquals`, etc.)
  - Pick per repo by looking at a neighbouring test, not by preference — a repo without a
    `kotlin.test` dependency can only use JUnit 5
- **`@Test` annotation:** `org.junit.jupiter.api.Test` (not `kotlin.test.Test`)
- **No wildcard imports** — explicit only; never `import kotlin.test.*` or `import org.junit.jupiter.api.Assertions.*`

### Mockk unit test structure

- **Class-level:** mocks with default stubs (returns empty/false) + service under test
- **Per-test:** all data variables — ids, flags, etc. declared inside the test, never as class fields
- **Test data objects:** single `data` variable of full type, reference `data.field` in verify — do NOT split into separate field variables
  ```kotlin
  val data = ReportPayload(
      sections = mapOf("SUMMARY" to listOf<Any>()),
      recommendations = emptyMap(),
  )
  coEvery { fetchService.buildPayload(entityId, enabled, baselineId) } returns data
  // ...
  coVerify { repo.upsert(Report(runId, entityId, enabled, data.sections, emptyMap())) }
  ```
- **Structure:** `// Given / When / Then` comments in every test

## Kotlin Import Style
- Normal `import` by default. Inline FQN only for actual name collisions, not habit.
- Bad: `java.util.concurrent.atomic.AtomicInteger(0)` inline with no colliding import.
- Good: `import java.util.concurrent.atomic.AtomicInteger` then `AtomicInteger(0)`.

## Kotlin Constants — No `companion object`
- **Top-level `const val` in the same file**, not a `companion object` wrapping constants.
- `private const val` by default; drop `private` only when something outside the file genuinely
  needs it (a test asserting the bound, another class in the module).
- A `companion object` holding only constants is a Java habit — it creates a real object and an
  extra indirection for something the compiler can inline. Reserve `companion object` for things
  that actually need an instance: factory functions, interface implementations, `@JvmStatic` interop.

```kotlin
// Bad — object exists solely to hold a number
class NoteValidator {
    companion object {
        const val MAX_LENGTH = 500
    }
}

// Good — top-level, file-scoped
private const val MAX_LENGTH = 500

class NoteValidator { /* ... */ }
```

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
