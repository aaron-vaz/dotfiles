# Scope Functions

Use sparingly - only when they add clarity. Don't use everywhere.

## What We Use

| Function | Use Case | Frequency |
|----------|----------|-----------|
| `apply` | Builder/DSL patterns, conditional object mutation | Common |
| `let` | Transform/project values (wrapping results) | Occasional |
| `also` | Side effects (logging errors) | Occasional |
| `takeIf` | Conditional transforms, validation | Common |
| `fold` | Functional pipelines, accumulation | Common |

## What We Don't Use
- `run` - never
- `with` - never

## Good - Our Patterns

```kotlin
// apply - DSL builder
inline fun createStats(block: StatsBuilder.() -> Unit): Stats =
    StatsBuilder().apply(block).build()

// apply - conditional object mutation
Criteria().apply {
    request.metricIds?.let { and(Criteria.where("metric_id").`in`(it)) }
    request.riskLevel?.let { and(Criteria.where("risk_level").`is`(it)) }
}

// let - transform/project result
repository.save(request).let { Response(id = it.id) }

// also - logging side effect
Response(status = Status.ERROR, message = e.message)
    .also { logger.error(e) }

// takeIf - conditional with default
getPValue(zScore, numberOfComparisons).takeIf { !it.isNaN() } ?: 1.0

// takeIf - proto has*() checks
result = this.result.takeIf { hasResult() }?.toDomain()

// fold - functional pipeline
processors.fold(readoutData) { acc, processor ->
    if (!processor.supports(acc, readoutType)) return@fold acc
    acc.copy(procedures = acc.procedures + processor.apply(acc))
}
```

## Bad - Unnecessary/Obfuscating

```kotlin
// Pointless let
val length = name.let { it.length }  // Bad
val length = name.length              // Good

// let on non-null - unnecessary
val name = "John"
name.let { println(it) }  // Bad
println(name)             // Good

// Nested scope functions - hard to follow
user?.let { u ->
    u.preferences?.run {
        theme.also { t -> applyTheme(t) }
    }
}

// Chained scope functions
thing.let { }.run { }.also { }  // Unreadable
```

## The Rule

**If removing the scope function makes code equally or more readable, remove it.**
