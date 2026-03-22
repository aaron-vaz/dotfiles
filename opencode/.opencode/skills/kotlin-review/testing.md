# Kotlin Test Style

## Method Naming

```kotlin
@Test
fun `should return calculator for metric type`() { ... }
```

---

## Given/When/Then (REQUIRED)

**MANDATORY:** Every test MUST have all three sections as explicit comments, even if empty:

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

**NEVER combine When/Then.** These are always separate phases:

```kotlin
// ❌ WRONG - Combined When/Then
webTestClient.get()
    .uri("/api/v1/...")
    .exchange()  // When
    .expectStatus().isOk  // Then

// ✅ CORRECT - Separate phases
// When
val response = webTestClient.get()
    .uri("/api/v1/...")
    .exchange()

// Then
response.expectStatus().isOk
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
- Individual static imports: `import org.junit.jupiter.api.Assertions.assertEquals`
- Use `@ParameterizedTest` with `@EnumSource`, `@ValueSource`

**Extract values in Then, don't chain expectations:**

```kotlin
// ❌ WRONG - Chained expectations blur When/Then
webTestClient.get()
    .uri("/api/v1/users/1")
    .exchange()
    .expectStatus().isOk
    .expectBody()
    .jsonPath("$.name").isEqualTo("John")

// ✅ CORRECT - Capture response, assert in Then
// When
val response = webTestClient.get()
    .uri("/api/v1/users/1")
    .exchange()

// Then
assertEquals(HttpStatus.OK, response.status())

// And - verify response body
val user = response.expectBody(User::class.java).returnResult().responseBody
assertEquals("John", user?.name)
```

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
