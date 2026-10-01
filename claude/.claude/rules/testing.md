# Testing Rules

## Test Structure

Tests follow **Given-When-Then** pattern with `// Given`, `// When`, `// Then` labels (capitalised, no description after label).

- **Kotlin tests** — naming, `runTest`, `assertThrows`, Mockk and field rules live in `rules/kotlin.md` (Testing section)
- **No exceptions for simple tests** — even one-liners need Given/When/Then
- **Comments always own line** — never append to end of code line
- **Never skip `// Given`** — always include. No setup code? Add comment explaining why:
  ```kotlin
  // Given
  // setup in before each
  ```
- **Never leave `// Then` empty** — omit only if no assertions
- **Use `assertEquals` not `assert()`** — better error messages
- **Never `assertTrue(x == y)`** — beginner mistake; use specific assertions so failures show actual values:
  - `assertTrue(a == b)` → `assertEquals(b, a)`
  - `assertTrue(!x)` → `assertFalse(x)`
  - `assertTrue(str.contains("..."))` → `assertContains(str, "...")`
  - `assertTrue(collection.contains(x))` → `assertContains(collection, x)`
  - `assertTrue(a === b)` → `assertSame(a, b)` from `org.junit.jupiter.api.Assertions`

## Test Data Rules

### JSON Fixtures
- Store in `src/test/resources/` or `integration-tests/.../tests/{TestClassName}/`
- One fixture per file
- Meaningful names: `valid-request.json`, `edge-case-empty-list.json`
- Pretty-print JSON (2-space indent)

### Enum Casing and Field Types
- Match production enum constants exactly; verify JSON ↔ model nullability, and test both `null` and `{}` for optional
  fields. Kotlin specifics: `rules/kotlin.md`.

## Running Tests

```bash
./gradlew test                                              # All tests
./gradlew :module:test                                      # Specific module
./gradlew :module:test --tests "TestClass"                  # Specific class
./gradlew :module:test --tests "TestClass.testMethod"       # Specific method
./gradlew :integration-tests:test                           # Integration tests
./gradlew clean test                                        # Clean + run
```

### Testcontainers
- Elasticsearch container shared singleton across all tests (see `ESContainer.kt`)
- Orphaned containers: `docker ps -aq --filter "label=org.testcontainers" | xargs docker rm -f`

## Verification Checklist

Before marking tests passing:
- All green (no failures, no skipped)
- Correct module/package in output
- No deprecated API warnings

## Common CI Pitfalls

1. **Gradle build cache false passes** — cache key unchanged after dependency upgrade, Gradle skips tests. Fix: `./gradlew clean test`
2. **WireMock fixture staleness** — upgraded lib changes serialization format, old fixtures break. Fix: run with `--info`, compare actual vs fixture, update. Use `ignoreExtraElements: true`.
3. **Spotless version constraints** — pin deliberately: a newer Spotless may not be present in the repo's configured artifact mirror, and an older one can break against the project's Spring Boot major. Check what the project already resolves before bumping.