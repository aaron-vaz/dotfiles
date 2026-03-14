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

- Use JUnit 5 `org.junit.jupiter.api.Assertions.*`
- Individual static imports
- Use `@ParameterizedTest` with `@EnumSource`, `@ValueSource`

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
