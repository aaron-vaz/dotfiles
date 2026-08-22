---
name: kotlin-review
description: Use when reviewing PRs, code changes, or after writing Kotlin code to check for idiomatic patterns and anti-patterns.
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "if [[ \"$CLAUDE_FILE_PATH\" == *.kt ]]; then ./gradlew spotlessApply -q 2>/dev/null || true; fi"
          timeout: 30
---

# Kotlin Code Review

## Critical Rules

1. Prefer `val` over `var`
2. Use `?.`, `?:`, `let` over `!!` (NPE risk)
3. No `run` or `with` - use `apply`, `let`, `also`, `takeIf`
4. **Specific exception handling over catch-all** - Catch specific exception types, not `Exception` or `Throwable`
5. Default parameters over overloads
6. **Extension functions over utility objects** - Prefer top-level/extension functions to `object SomeUtil`

## Quick Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| `!!` without certainty | `?.`, `?:`, `let` |
| Nested scope functions | Separate statements |
| `var` when value doesn't change | `val` |
| `HashSet<String>` in signatures | `Set<String>` |
| `for (i in 0..n-1)` | `for (i in 0..<n)` |
| Pointless `let` on non-null | Direct property access |
| `object MyUtil` with methods | Extension functions in `MyTypes.kt` |
| `SomeTypeExtensions.kt` | `SomeTypes.kt` (plural of type) |
| `runCatching` for everything | Specific try-catch for expected errors |
| `catch (e: Exception)` | Catch specific exception types |
| `catch (_: SomeException)` | `catch (e: SomeException)` + log `e` |
| `param != null` on non-nullable | Remove redundant check |
| `runBlocking` in production | Use `suspend` functions |
| `.block()` inside coroutines | Use `suspend` + `asFlow()`/`awaitFirst()` |
| Constants in `companion object` (no Java interop) | Top-level declarations |
| Manual delegation (forward all calls) | `class Foo : Bar by impl` |
| Mixed named + positional params | All named or all positional |
| `data class Id(val value: String)` (single field) | `@JvmInline value class Id(val value: String)` |
| `object Signal` (stateless marker) | `data object Signal` — gives free `toString()`, equals, hashCode |
| `MergedAnnotations.from()` for annotation lookup | `AnnotatedElementUtils.findMergedAnnotation()` — clearer intent, handles meta-annotations |
| `coroutineScope` for independent parallel work | `supervisorScope` — one child failure cancels all siblings in `coroutineScope` |
| Mutable builder returning `this` | `apply { }` eliminates `return this` boilerplate |
| `SomeType::class.java` at call sites | `inline fun <reified T>` extension on the factory |
| `@Deprecated` with WARNING level | `DeprecationLevel.ERROR` + `ReplaceWith` for guided migration |
| Internal impl class named arbitrarily | `Real*` prefix (`RealReadoutCaptor`) — clear convention from OkHttp |
| Fixed `delay` in retry logic | Injectable `var delay: suspend (Long) -> Unit` — overridable in tests for instant retry |
| Composing listeners/handlers manually | `operator fun plus` on abstract class — `metrics + tracing + logging` |
| `withContext(Dispatchers.IO)` inside `flow { }` | `flowOn(Dispatchers.IO)` — `withContext` in a flow builder throws |
| `flow { emit() }` from multiple coroutines | `channelFlow { send() }` — `flow { }` is single-coroutine only |
| `GlobalScope.launch` | Structured scope — always tie coroutines to a lifecycle |
| `async { }` without `await()` | Fire-and-forget `async` swallows exceptions silently; use `launch` |
| Shared `CoroutineScope` across independent listeners | `SupervisorJob` per listener — one failure cancels all siblings in a shared scope |

## Re-read Triggers

- For null safety patterns: Read `patterns.md`
- For scope function rules: Read `scope-functions.md`
- For naming/formatting: Read `style.md`
- For test conventions: Read `testing.md`
- For idioms (require, runCatching, etc.): Read `idioms.md`

## Scope Function Rule

If removing the scope function makes code equally or more readable, remove it.
