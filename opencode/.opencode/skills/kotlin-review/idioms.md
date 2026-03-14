# Kotlin Idioms

## Extension Functions Over Java-Style Util Classes

Prefer extension functions and top-level functions over Java-style utility classes:

```kotlin
// ❌ Don't: Java-style utility class
object ResourceUtils {
    fun getRegistry(context: ExtensionContext): ResourceRegistry { ... }
    fun registerResource(context: ExtensionContext, resource: Resource) { ... }
}

class ResourceHelper {
    companion object {
        @JvmStatic
        fun getRegistry(context: ExtensionContext): ResourceRegistry { ... }
    }
}

// ✅ Do: Kotlin extension functions
val ExtensionContext.resourceRegistry: ResourceRegistry
    get() = resourceStore.getOrCreate { ResourceRegistry() }

fun ExtensionContext.registerResource(resource: Resource): Map<String, String> { ... }
```

**Benefits:**
- IDE discovers via autocomplete on receiver type
- Natural call syntax: `context.resourceRegistry` vs `ResourceUtils.getRegistry(context)`
- Follows Kotlin stdlib patterns (Strings.kt, Collections.kt)

**File naming:** `Resources.kt` (plural of type), not `ResourceUtils.kt` or `ResourceHelper.kt`

---

## Validation & Guard Clauses

```kotlin
// Argument validation
require(filePath.exists()) { "Test data file not found: $filePath" }

// Null check that throws
requireNotNull(loadersByExtension[extension]) { "Unsupported file extension: $extension" }

// State validation
check(condition) { "message" }

// Unreachable code / missing registry entries
calculators[metricType] ?: error("No calculator found for metric type: $metricType")
```

---

## Error Handling

### When to Use runCatching

Use `runCatching` + `fold` for **happy-path-only code** where you want to convert any failure to a Result:

```kotlin
runCatching {
    repository.saveAll(readouts.asFlux()).awaitLast()
}.fold(
    onSuccess = { Response(status = Status.OK) },
    onFailure = { e ->
        logger.error("Error saving readouts", e)
        Response(status = Status.ERROR, message = e.message)
    },
)
```

### ⚠️ When NOT to Use runCatching

**CRITICAL:** `runCatching` catches **EVERYTHING** including:
- Programming errors (NullPointerException, IllegalStateException)
- Coroutine cancellation (CancellationException)
- JVM errors (OutOfMemoryError, StackOverflowError)
- Bugs in your code

**Don't use runCatching when:**
- You need to distinguish between different error types
- Programming errors should crash (not be silently caught)
- You want specific handling for specific exceptions

**Instead, use specific exception handling:**

```kotlin
// ✅ Good - Catch only expected exceptions
try {
    apiClient.call()
} catch (e: WebClientResponseException) {
    // Expected API error - handle it
    logger.error("API call failed: ${e.statusCode}", e)
    throw ApiException(cause = e)
} catch (e: TimeoutException) {
    // Expected timeout - handle it
    logger.error("API timeout", e)
    throw ApiException(cause = e)
}
// Let NPE, IllegalStateException, OOME propagate - they're bugs!

// ❌ Bad - Catches bugs and treats them as API failures
runCatching {
    apiClient.call()
}.fold(
    onSuccess = { it },
    onFailure = { e ->
        // This catches NPE, OOME, bugs - masks problems!
        throw ApiException(cause = e)
    }
)
```

### Generic Exception Catches

Avoid `catch (e: Exception)` - it's almost as bad as `runCatching`:

```kotlin
// ❌ Bad - Hides all error types
try {
    processData()
} catch (e: Exception) {
    logger.error("Failed", e)
    return ErrorResponse()
}

// ✅ Good - Catch specific types
try {
    processData()
} catch (e: ValidationException) {
    logger.error("Validation failed", e)
    return ErrorResponse(type = "VALIDATION_ERROR")
} catch (e: NetworkException) {
    logger.error("Network failed", e)
    return ErrorResponse(type = "NETWORK_ERROR")
}
// IllegalArgumentException, NPE, etc. propagate as bugs
```

### Never Discard Exception Context

Always log the exception, never use underscore:

```kotlin
// ❌ Bad - Loses valuable debugging info
} catch (_: RequestNotPermitted) {
    logger.warn("Rate limit exceeded")
    throw RateLimitException()
}

// ✅ Good - Preserves exception context
} catch (e: RequestNotPermitted) {
    logger.warn("Rate limit exceeded: ${e.message}", e)
    throw RateLimitException(cause = e)
}
```

---

## Type Safety (Team Preferences)

- Use `java.nio.file.Path` instead of `String` for file paths
- Use `kotlin.io.path.extension` for file extensions
- Use inline value classes for type-safe IDs:

```kotlin
@JvmInline value class EmployeeId(private val id: String)
@JvmInline value class CustomerId(private val id: String)
```

---

## By Delegation

Use `by` delegation for decorator/composition patterns:

```kotlin
@Repository
class SummaryESRepository(
    private val summaryRepository: SummaryRepository,
    private val reactiveElasticsearchOperations: ReactiveElasticsearchOperations,
) : SummaryRepository by summaryRepository {
    // Custom overrides here
    suspend fun save(entity: SummaryDocument): SummaryDocument {
        // custom implementation
    }
}
```

---

## Sealed Types

```kotlin
/**
 * Sealed interface for data loaders.
 *
 * @see JsonDataLoader
 * @see CsvDataLoader
 */
sealed interface DataLoader { ... }
```

---

## Strings

```kotlin
// Templates
"Name $name"                    // Simple variable
"Size ${children.size}"         // Expression

// Multiline - prefer over \n
val text = """
    |Tell me and I forget.
    |Teach me and I remember.
""".trimMargin()
```

---

## Lazy Properties

```kotlin
val p: String by lazy { computeValue() }
```

---

## Try-With-Resources

```kotlin
reader.use { println(it.readText()) }
```
