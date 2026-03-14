# Kotlin Style Guide

## Naming Conventions

### Packages & Classes
- Package names lowercase, no underscores: `org.example.project`
- Class/object names upper camel case: `DeclarationProcessor`
- Avoid meaningless names: `Util`, `Manager`, `Wrapper`

### Functions & Properties
- Start lowercase, use camel case: `processDeclarations()`
- Constants: `SCREAMING_SNAKE_CASE`
- Backing properties: underscore prefix `_elementList`
- Acronyms: two-letter = uppercase (`IOStream`), longer = capitalize first (`XmlFormatter`)

### Boolean Naming (Kotlin — NOT Java Bean Spec)
- **Properties:** Use natural names WITHOUT `is` prefix: `sampleSizeCallable`, `beforeMinDuration`, `qualified`
  - Kotlin generates `isFoo` getters/setters automatically for `val foo: Boolean`
  - Adding `is` yourself creates `isIsFoo()` in Java interop
- **Local variables:** Same rule — `confirmed`, `skewPrevented`, NOT `isConfirmed`, `isSkewPrevented`
- **Exception:** Kotlin stdlib follows this: `isEmpty()`, `isBlank()` are *functions*, not properties

### Test Methods
- Backticks with spaces allowed: `` fun `should return calculator for metric type`() ``

---

## Formatting

### Whitespace
- Spaces around binary operators: `a + b` (exception: range `0..i`)
- No spaces around unary: `a++`
- Space after control flow: `if (`, `when (`
- No spaces around `.`, `?.`, `::`
- No space before `?` in nullable: `String?`

### Trailing Commas
Use consistently:
```kotlin
class Person(
    val firstName: String,
    val lastName: String,
)
```

### Modifiers Order
```
public/protected/private/internal
expect/actual
final/open/abstract/sealed/const
external override lateinit tailrec vararg suspend
inner enum/annotation/fun companion
inline/value infix operator data
```

---

## Class Layout Order

```kotlin
class MyClass {
    // 1. Property declarations and initializer blocks
    // 2. Secondary constructors
    // 3. Method declarations
    // 4. Companion object
    // 5. Nested classes (after companion if used externally)
}
```

- Group related methods logically, not alphabetically
- Interface implementations: keep member order matching interface

---

## File Organization

### Naming Conventions for Extension Files
Follow Kotlin stdlib conventions - use **plural of the type being extended**:
- `Paths.kt` for `Path` extensions
- `Strings.kt` for `String` extensions
- `Collections.kt` for collection extensions
- `Resources.kt` for `Resource` extensions
- `ExtensionContexts.kt` for `ExtensionContext` extensions

**Not:** `PathExtensions.kt`, `StringUtils.kt`, `CollectionHelper.kt`

### Coupled vs Decoupled Code
- **Annotations + providers/processors:** Keep together (they're coupled)
- **Data classes + their extensions:** Separate files (extensions are the public API)

```kotlin
// ScenarioSource.kt - annotation + provider together
@ArgumentsSource(ScenarioSourceProvider::class)
annotation class ScenarioSource(val subdirectory: String)

class ScenarioSourceProvider : ArgumentsProvider { ... }

// TestScenario.kt - data class + extensions separate
data class TestScenario(val name: String, val inputFile: Path, ...)

fun TestScenario.loadInputs(): List<T> = inputFile.loadListOf()
```

### Singleton Instances
Use companion objects for default/singleton instances:

```kotlin
class DataLoaderRegistry(objectMapper: ObjectMapper) {
    companion object {
        val defaultObjectMapper: ObjectMapper by lazy { ... }
        val default: DataLoaderRegistry by lazy { DataLoaderRegistry(defaultObjectMapper) }
    }
}
```

### @PublishedApi internal
Needed when inline functions with reified types access non-public symbols:

```kotlin
@PublishedApi
internal val defaultRegistry: DataLoaderRegistry by lazy { ... }

inline fun <reified T : Any> Path.loadListOf(): List<T> {
    return defaultRegistry.loaderFor(this).loadMany(...)
}
```
