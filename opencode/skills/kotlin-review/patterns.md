# Kotlin Patterns

## Null Safety

### Operators

| Operator | Use Case | Risk |
|----------|----------|------|
| `?.` | Safe access/chaining | None |
| `?:` | Provide defaults (Elvis) | None |
| `!!` | Assert not null | **NPE if wrong** |
| `as?` | Safe type casting | None |

### Patterns

```kotlin
// Safe call chaining
bob?.department?.head?.name

// Elvis with fallback
val l = b?.length ?: 0

// Elvis with control flow
val parent = node.getParent() ?: return null
val name = node.getName() ?: throw IllegalArgumentException("name expected")

// Execute if not null
value?.let { processValue(it) }

// Filter nulls from collection
val nonNulls: List<Int> = nullableList.filterNotNull()
```

**Best Practice:** Prefer `?.`, `?:`, `let`, and `if` checks over `!!`. Only use `!!` when certain value is not null.

---

## Collections

### Read-Only vs Mutable

| Read-Only | Mutable | Default Implementation |
|-----------|---------|----------------------|
| `List<T>` | `MutableList<T>` | `ArrayList` |
| `Set<T>` | `MutableSet<T>` | `LinkedHashSet` |
| `Map<K,V>` | `MutableMap<K,V>` | `LinkedHashMap` |

### Best Practices

```kotlin
// Prefer immutable types in function signatures
fun validateValue(actualValue: String, allowedValues: Set<String>) { }  // Good
fun validateValue(actualValue: String, allowedValues: HashSet<String>) { }  // Bad

// Use factory functions
val list = listOf("a", "b", "c")  // Good
val list = arrayListOf("a", "b", "c")  // Avoid

// Map access
println(map["key"])
map["key"] = value

// Traversal with destructuring
for ((k, v) in map) { println("$k -> $v") }

// Safe first element
val first = list.firstOrNull() ?: ""
```

---

## Control Flow

### Prefer Expressions

```kotlin
// Good - expression
return if (x) foo() else bar()

// Good - when expression
return when(x) {
    0 -> "zero"
    else -> "nonzero"
}
```

### When vs If
- Binary conditions: use `if`
- 3+ options: use `when`

### Ranges

```kotlin
for (i in 1..100) { }      // closed range (includes 100)
for (i in 1..<100) { }     // open range (excludes 100) - PREFERRED
for (i in 0..n - 1) { }    // Bad - use ..< instead
for (x in 2..10 step 2) { }
for (x in 10 downTo 1) { }
```

---

## Functions

### Default Parameters over Overloads

```kotlin
// Bad
fun foo() = foo("a")
fun foo(a: String) { }

// Good
fun foo(a: String = "a") { }
```

### Single-Expression Functions

```kotlin
fun theAnswer() = 42

fun transform(color: String): Int = when (color) {
    "Red" -> 0
    "Green" -> 1
    else -> throw IllegalArgumentException("Invalid color")
}
```

### Named Arguments
Use for multiple same-type parameters or booleans:
```kotlin
drawSquare(x = 10, y = 10, width = 100, height = 100, fill = true)
```

---

## Immutability

- Prefer `val` over `var`
- Use immutable collection types by default
- Mutable collections can use `val` (mutability is contents, not reference)

```kotlin
val numbers = mutableListOf("one", "two")
numbers.add("three")  // OK - modifying contents
// numbers = mutableListOf("four")  // Error - can't reassign
```

---

## Readability Anti-Patterns

### Redundant Null Checks

Kotlin's type system makes explicit null checks unnecessary:

```kotlin
// ❌ Bad - Redundant check on non-nullable parameter
fun process(value: String) {
    if (value != null) {  // Always true - String is non-nullable!
        println(value)
    }
}

// ✅ Good - Trust the type system
fun process(value: String) {
    println(value)  // value is guaranteed non-null by type
}

// ❌ Bad - Redundant check on Reactor Predicate<Throwable>
.filter { throwable -> throwable != null && condition(throwable) }

// ✅ Good - Type is non-nullable
.filter { throwable -> condition(throwable) }
```

### Unnecessary Transformations

```kotlin
// ❌ Bad - Chained transformations obscure simple logic
val result = notes
    .map { it.toInput() }
    .let { inputs ->
        inputs.filter { it.isValid() }
    }
    .takeIf { it.isNotEmpty() }
    ?.let { processNotes(it) }

// ✅ Good - Simple, clear logic
val validInputs = notes
    .map { it.toInput() }
    .filter { it.isValid() }
if (validInputs.isNotEmpty()) {
    processNotes(validInputs)
}
```

### Complex When Expressions

```kotlin
// ❌ Bad - Mixed pattern matching obscures structure
val message = when {
    cause is TypeA -> "message A"
    cause is TypeB -> "message B"
    underlyingCause is TypeC && underlyingCause.condition -> "message C"
    else -> "default"
}

// ✅ Good - Use when(subject) for type matching
val message = when (cause) {
    is TypeA -> "message A"
    is TypeB -> "message B"
    else -> {
        val underlying = (cause as? WrapperException)?.cause
        when {
            underlying is TypeC && underlying.condition -> "message C"
            else -> "default"
        }
    }
}
```

### Redundant this. Qualifiers

```kotlin
// ❌ Bad - Unnecessary this. in extension function
fun User.toDto(): UserDto = UserDto(
    id = this.id,
    name = this.name,
    email = this.email
)

// ✅ Good - Implicit receiver
fun User.toDto(): UserDto = UserDto(
    id = id,
    name = name,
    email = email
)
```

### The 30-Second Rule

**If a team member can't understand the code in 30 seconds, it needs simplification.**

Ask:
- Can this scope function be removed?
- Can this transformation be split into steps?
- Are variable names clear?
- Is the control flow obvious?
