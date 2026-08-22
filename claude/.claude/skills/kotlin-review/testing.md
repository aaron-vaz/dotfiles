# Kotlin Test Style

## Method Naming

```kotlin
@Test
fun `should return calculator for metric type`() { ... }
```

---

## Given/When/Then

Always include all sections:

```kotlin
@Test
fun `should return default stats instance`() {
    // Given
    // No setup needed - testing default factory behavior

    // When
    val stats = StatsFactory.createStats()

    // Then
    assertNotNull(stats)
}
```

Group related assertions under "And":

```kotlin
// Then - custom corrections are used
assertSame(customCorrections, stats.corrections)

// And - defaults are used for unspecified dependencies
assertNotNull(stats.calculators)
```

---

## Assertions

- **Check the repo's existing test files first** — `~/.claude/rules/testing.md` is the authority
  on which assertion library a given project uses (some are on `kotlin.test`, some on JUnit 5
  directly). The rules below are the default when the repo has no established convention.
- Use JUnit 5 `org.junit.jupiter.api.Assertions.*`
- Individual static imports
- Use `@ParameterizedTest` with `@EnumSource`, `@ValueSource`
- **Pure JUnit5 is the default** (user preference) — don't introduce AssertJ (`assertThat`) into
  a new file just because it's available on the classpath.
- **Don't mix AssertJ and JUnit assertions in the same file.** If a file already uses AssertJ
  (an established convention in that specific file, not something you just added), stay on
  AssertJ throughout — don't drop in `Assertions.assertEquals`/`assertThrows` alongside it. Check
  the file's existing imports before adding a new assertion; match whichever library is already
  there rather than defaulting to JUnit.

---

## Example Parameterized Test

```kotlin
@ParameterizedTest
@EnumSource(MetricType::class)
fun `should handle all metric types`(metricType: MetricType) {
    // Given
    val calculator = calculatorFactory.forType(metricType)

    // When
    val result = calculator.calculate(testData)

    // Then
    assertNotNull(result)
}
```
