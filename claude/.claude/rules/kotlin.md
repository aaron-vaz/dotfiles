---
paths:
  - "**/*.kt"
  - "**/*.kts"
---

# Kotlin Code Style

## Core Principle — Write Kotlin, Not Java in Kotlin Syntax

Never write Kotlin as a Java developer would. If a line translates one-to-one back to Java, look for the Kotlin way:
null-safe types over null checks, expressions over statements, `data class` over POJO, extension functions over
`*Utils` classes, stdlib collection operators over loops, default and named arguments over overloads and builders.

**Exception: code consumed from Java.** Where Java callers exist, follow Java interop conventions (see
[Java Interop](#java-interop)) and keep the Java-friendly shape. Verify a Java caller actually exists (grep for the
class in `*.java` files and check the module's consumers) — "might be called from Java someday" is not a reason.

Check the neighbouring files and repo conventions before applying anything below; a repo's established style beats this
file (see Testing).

## Null Safety

- Model absence in the type: `String?` vs `String`. Never use a sentinel (`""`, `-1`) for "missing".
- Prefer `?.`, `?:`, `let` and smart casts over `!!`. `!!` only when the invariant is guaranteed and a comment or
  `requireNotNull`/`checkNotNull` message would add nothing.
- `?:` carries control flow as a guard clause: `val user = repo.find(id) ?: return null`,
  `?: throw NotFoundException(id)`, `?: error("...")`.
- Don't null-check non-nullable values (`param != null` on a `String`), including in Reactor/Java lambdas whose
  parameters are Kotlin-typed non-null.
- `as?` over `as` + `is` pre-check; `filterNotNull()`/`mapNotNull` over filtering then `!!`.
- Treat Java platform types (`String!`) as nullable at the boundary: declare the type explicitly
  (`val name: String? = javaObj.name`) when the Java side can return null.
- `lateinit` only for framework-injected state (DI, test setup); never for domain data. Prefer constructor injection.
- Use `Optional` only at Java boundaries; never in Kotlin signatures.

## Immutability & Data

- `val` over `var`, immutable collection types (`List`, `Set`, `Map`) over mutable ones, `copy()` over mutation.
- Mutable collections may be held in a `val` — mutability is of the contents.
- Value carriers are `data class` with `val` properties. No getters/setters, no builders, no `equals`/`hashCode`
  written by hand. Use named arguments plus defaults instead of a builder.
- Single-field wrapper for type safety is an `@JvmInline value class` (`EmployeeId`, `CustomerId`), not a `data class`.
- Stateless marker/singleton is `data object` (free `toString`), not a plain `object`.
- Closed hierarchies are `sealed interface`/`sealed class` with an exhaustive `when` and **no `else` branch**, so new
  subtypes fail compilation.
- Fixed sets are `enum class` — use `entries` (not `values()`), and give enums properties/functions rather than a
  parallel `when` in another file.
- Use `Path` (`java.nio.file.Path`, `kotlin.io.path.*`) for file paths, never `String`.
- `typealias` for long generic or function types; not for domain concepts (use a value class).

## Functions

- Default parameters over overloads. Named arguments for booleans and for several same-typed parameters; don't mix
  named and positional in one call.
- Single-expression bodies (`fun answer() = 42`) when the body is one expression. Declare the return type explicitly
  for public API and for non-trivial expression bodies.
- Extension functions and top-level functions over `object SomeUtils` or static-style helpers. An extension on the
  receiver is discoverable via autocomplete: `context.registry`, not `ResourceUtils.getRegistry(context)`.
- Properties with a custom getter over `getX()` functions when the value is cheap and side-effect free.
- Trailing lambda syntax; name the parameter when `it` would be unclear or the lambda is nested (never nest `it`).
- Don't write a function that only forwards its arguments, and don't wrap a stdlib call in a one-line helper.
- `infix`/`operator` only where the call site reads like the domain (`a + b` for composable handlers) — not for
  cleverness.
- `inline` only for functions taking lambdas (and `reified` type parameters). Not as a micro-optimization.
- `inline fun <reified T>` factory over passing `SomeType::class.java` at call sites.
- `@Deprecated` in new code uses `ReplaceWith`, and `DeprecationLevel.ERROR` when the migration is mechanical.
- A function taking `Boolean` flags that change behavior wants two functions or an enum.

## Classes & Objects

- Declare properties in the primary constructor (`class Foo(private val bar: Bar)`); no separate field + assignment.
  Use `init` blocks only for validation or non-trivial derived state.
- Constructor injection; no field injection. Unused injected dependencies are dead code.
- No getter/setter pairs, no `Impl` suffix, no `Abstract*` base class when an interface with default methods does it.
  Internal implementations of a public interface are `Real*` (`RealReadoutCaptor`).
- Composition over inheritance. Forwarding every call to a wrapped instance is `class Foo : Bar by impl`.
- Visibility: `private` by default; `internal` for module-internal; public only for the actual API. Everything is
  `final` by default — don't write `open` unless a subclass exists (framework-proxied classes are handled by the
  `kotlin-spring` / all-open plugin, not by sprinkling `open`).
- Single-method interfaces consumed by lambdas are `fun interface`.
- `object` for real singletons only; a stateless collection of functions is top-level functions.
- `lazy` for expensive, once-only properties (`val p by lazy { compute() }`); other delegates (`observable`, maps) when
  they fit — don't hand-roll the backing field.
- Backing property (`_items` private mutable, `items` public read-only) to expose a read-only view of mutable state.

### Constants — No `companion object`

- **Top-level `const val` in the same file**, not a `companion object` wrapping constants.
- `private const val` by default; drop `private` only when something outside the file genuinely needs it (a test
  asserting the bound, another class in the module).
- A `companion object` holding only constants is a Java habit — it creates a real object and an extra indirection for
  something the compiler can inline. Reserve `companion object` for things that need an instance: interface
  implementations and `@JvmStatic`/`@JvmField` interop.

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

- Factories are **file-level functions** named like the type — `fun ReadoutClient(...): ReadoutClient` — over a
  `companion object { fun create() }`. Singleton/default instances are top-level `val`s (with `by lazy` if expensive).

## Collections

- Stdlib operators over manual loops: `map`, `filter`, `mapNotNull`, `flatMap`, `groupBy`, `associate`, `associateBy`,
  `partition`, `fold`, `sumOf`, `any`/`all`/`none`, `firstOrNull`, `getOrPut`, `buildList`/`buildMap`/`buildString`.
- Use plain `for` only for side effects or when early exit makes the operator chain harder to read.
- Parameters and return types are `List<T>`/`Set<T>`/`Map<K, V>`, never `ArrayList`/`HashSet`/`HashMap`.
- Factory functions: `listOf`, `setOf`, `mapOf`, `emptyList()`, `mutableListOf` — not `arrayListOf` or `ArrayList()`.
- Map access with `map["key"]` / `map["key"] = v`, destructuring in loops (`for ((k, v) in map)`), `to` for pairs.
- `firstOrNull()`/`singleOrNull()` over `first()`/`single()` when empty is possible; `first()` only when emptiness is
  a bug and you want the exception.
- `isEmpty()`/`isNotEmpty()`/`isNullOrEmpty()` over `size == 0`; `any { }` over `filter { }.isNotEmpty()`;
  `count { }` over `filter { }.size`.
- `Sequence` (`asSequence()`) only for large data or lazy multi-step chains with early termination; for typical short
  lists a plain chain is clearer and faster.
- Don't chain transformations that obscure simple logic (a `map().let{}.takeIf{}?.let{}` pipeline). Split into named
  steps when a reader can't follow it in 30 seconds.

## Control Flow

- `if`, `when`, `try` are expressions — `return if (x) a else b`, `val v = when (x) { ... }`. There is no ternary.
- `if` for two branches, `when` for three or more. `when (subject)` for type or value matching, bare `when { }` for
  boolean conditions; don't mix `is` checks into a boolean `when`.
- Guard clauses and early returns (see code-style.md). `?: return`/`?: continue` keeps the happy path flat.
- Smart casts over explicit casts; don't re-check a type the compiler already knows.
- Ranges: `0..<n` (not `0..n - 1`), `step`, `downTo`; `until` only in older code. Iterate indices with `indices` /
  `withIndex()`, never `for (i in 0 until list.size)`.
- No C-style loops; no `break`/`continue` with labels unless nested loops truly need it.
- No `Unit`-returning ceremony: don't write `return Unit` or `: Unit`.

## Strings

- String templates over concatenation, `StringBuilder`, or `String.format`: `"Size ${children.size}"`, `"Name $name"`
  (no braces for a simple identifier).
- `buildString { }` when assembling in a loop.
- Raw strings with `trimIndent()`/`trimMargin()` for multi-line text, not `\n` concatenation.
- `isBlank()`/`isNotBlank()` and `ifBlank { }`/`takeIf` over manual `trim().isEmpty()`.

## Scope Functions

Use sparingly — only when they add clarity. **If removing the scope function makes the code equally or more readable,
remove it.**

| Function | Use |
|----------|-----|
| `apply` | Builder/DSL configuration, conditional object mutation; replaces a builder's `return this` |
| `let` | Transform/project a value, or run a block on a non-null (`value?.let { ... }`) |
| `also` | Side effects (logging, registering) without changing the value |
| `takeIf` / `takeUnless` | Conditional values and validation (`x.takeIf { !it.isNaN() } ?: 1.0`) |
| `fold` | Accumulation pipelines |

- **Never `run` or `with`.**
- No pointless `let` on non-null (`name.let { it.length }`); no nested scope functions; no chained
  `let { }.run { }.also { }`.
- No redundant `this.` in extension functions or methods — use the implicit receiver.

## Error Handling

- Validate with `require(cond) { "msg" }` (arguments), `check(cond) { "msg" }` (state), `requireNotNull`/`checkNotNull`,
  and `error("msg")` for unreachable branches or missing registry entries (`map[key] ?: error("No handler for $key")`).
  Don't write `if (!x) throw IllegalArgumentException(...)`.
- Catch **specific** exception types. Not `Exception`, not `Throwable`; let NPE/`IllegalStateException`/OOME propagate as
  the bugs they are.
- `runCatching` catches *everything* (programming errors, `CancellationException`, JVM errors). Use it only on
  happy-path-only code where any failure converts to a `Result`, with `fold`/`getOrElse`; never when you need to
  distinguish error types, and never in coroutine code without rethrowing `CancellationException`.
- Never discard exception context: no `catch (_: X)`, log and chain it — `catch (e: X) { log.warn("...", e); throw
  Wrapped(cause = e) }`.
- Kotlin has no checked exceptions: don't declare/annotate throws unless Java callers need `@Throws` (see Java Interop).
- Resources: `use { }` over try/finally.
- Return `null` or a sealed result type for *expected* absence/failure; exceptions for bugs and exceptional conditions.
- Don't use exceptions for control flow.

## Coroutines

- `suspend` functions over blocking calls. No `runBlocking` in production code (tests: see Testing), no `.block()` inside
  coroutines — use `suspend` + `awaitFirst()`/`awaitSingle()`/`asFlow()`.
- Structured concurrency: every coroutine belongs to a scope tied to a lifecycle. No `GlobalScope`.
- `coroutineScope { }` when one child's failure should cancel the siblings; `supervisorScope { }` for independent
  parallel work. A shared `CoroutineScope` across independent listeners needs a `SupervisorJob` per listener.
- `async` is always paired with `await()` — fire-and-forget `async` swallows exceptions; use `launch`.
- Never swallow `CancellationException`: catch and rethrow it, or catch narrower types.
- `Flow`: `flowOn(dispatcher)` to change context (never `withContext` inside `flow { }`); `channelFlow { send() }` when
  emitting from several coroutines; `flow { emit() }` is single-coroutine only. Expose `Flow`, keep `MutableSharedFlow`
  / `MutableStateFlow` private behind a read-only view.
- Dispatchers: the shared `Dispatchers.Default`/`IO` are fine on a JVM server; a long-lived daemon gets its own named
  `Executors`-backed dispatcher. Inject dispatchers (or delays) where tests need to control them.
- Make time and delays injectable (`var delay: suspend (Long) -> Unit`) so tests run retry/backoff instantly.
- No blocking I/O on `Dispatchers.Default`; wrap blocking calls in `withContext(Dispatchers.IO)`.

## Naming & Formatting

- Packages lowercase, no underscores. Types UpperCamelCase. Functions/properties lowerCamelCase. Constants
  `SCREAMING_SNAKE_CASE`. Backing property `_elementList`. No meaningless names: `Util`, `Manager`, `Wrapper`,
  `Helper`.
- Acronyms: two letters stay upper (`IOStream`), longer capitalize first (`XmlFormatter`).
- **Booleans: no `is` prefix** on properties or locals — `qualified`, `confirmed`, `skewPrevented`, not `isQualified`.
  Kotlin generates `isFoo` accessors for `val foo: Boolean`; writing `isFoo` yourself produces `isIsFoo()` for Java
  callers. Functions may use it (`isEmpty()`).
- Trailing commas in multi-line parameter lists, argument lists and collection literals.
- Spaces around binary operators (not `..`/`..<`), none around `.`, `?.`, `::`; no space before `?` in a nullable type.
- Modifier order: visibility, `expect/actual`, `final/open/abstract/sealed/const`, `external`, `override`, `lateinit`,
  `tailrec`, `vararg`, `suspend`, `inner`, `enum/annotation/fun`, `companion`, `inline/value`, `infix`, `operator`,
  `data`.
- Class layout: properties and `init` blocks, secondary constructors, methods, `companion object`, nested classes.
  Group related members logically, not alphabetically; interface implementations keep the interface's order.
- Don't annotate types the compiler infers: no `val x: String = "a"` on locals, **no redundant type arguments**
  (`listOf(a, b)`, `ChangeChannel(name, UUID::toString, UUID::fromString)`). Keep them only where inference fails:
  empty collections, untyped `mockk<T>()`, `MutableSharedFlow<T>()` with no seed.
- Unused `it` parameters get no name; unused lambda parameters are `_`; never shadow an outer `it`.
- `@Suppress` only on the narrowest scope with a reason; no blanket suppression.
- Comments explain the non-obvious *why* in the code's own terms. Never narrate task numbers, design-doc decisions or
  spec scenario names. KDoc (`/** */`) on public API; `@see` for related types.

## Imports

- No wildcard imports — explicit only (`import kotlin.test.*`, `import org.junit.jupiter.api.Assertions.*` included).
- Normal `import` by default. Inline FQN only for actual name collisions, not habit. An inline FQN already in the
  file is drift, not precedent: new code imports the type, and existing FQNs are converted when you touch them.
  - Bad: `java.util.concurrent.atomic.AtomicInteger(0)` with no colliding import.
  - Good: `import java.util.concurrent.atomic.AtomicInteger` then `AtomicInteger(0)`.

## File Organization

- **Extensions on a type** live in the plural of that type, like the stdlib: `Paths.kt`, `Strings.kt`, `Collections.kt`,
  `ExtensionContexts.kt`. **Other top-level functions** are named for the concern: `Errors.kt`, `Transform.kt`. Never
  `*Utils.kt`, `*Helper.kt`, or `*Extensions.kt`.
- One primary declaration per file, named for it. A file named for purpose rather than its type may trip ktlint's
  filename rule; suppress with `@file:Suppress("ktlint:standard:filename")`.
- Keep coupled code together (an annotation with its provider/processor); keep a `data class` and the extensions that
  form its public API in separate files.
- `internal/` subdirectory for implementation detail hidden from consumers of the module.
- `@PublishedApi internal` for the non-public symbols that a public `inline`/`reified` function touches.
- Repos with explicit-API mode: declare visibility and return types for public declarations explicitly.

## Idiomatic Gotchas

- `==` is structural equality; `===` is reference identity. Never `.equals()`.
- Use stdlib before inventing: `require`, `lazy`, `use`, `buildList`, `Duration` (`5.seconds`, `kotlin.time`) over raw
  `Long` millis, `measureTimedValue`.
- `kotlin.time.Duration` / `java.time` over `Long`/`Int` for time; `Instant`/`LocalDate` over `Date`.
- `String.toIntOrNull()`/`toLongOrNull()` over try/catch around `toInt()`.
- `Comparator`: `compareBy`, `sortedBy`, `sortedWith(compareBy(...).thenBy(...))`.
- `Pair`/`Triple` only locally; return a small `data class` from public functions.
- Destructuring only for `Pair`, `Map.Entry`, and data classes with obvious component order.
- Operator overloads and `infix` only where they match a domain meaning.
- DSLs: lambdas with receivers (`Foo.() -> Unit`) with `@DslMarker` for nested builders.
- Don't use reflection (`::class.java`, `javaClass`) at call sites when a `reified` helper hides it.
- Don't translate Java APIs literally: `StringUtils.isEmpty(s)` → `s.isNullOrEmpty()`, `Collections.emptyList()` →
  `emptyList()`, `new Foo()` → `Foo()`, `getX()` → `x`, anonymous `Runnable` → lambda, `synchronized` blocks →
  coroutine `Mutex` or `@Synchronized` only on a Java-facing method.

## Java Interop

Applies only when Java code calls this Kotlin (or the code is a library for mixed callers). The Kotlin-idiomatic form
stays the default everywhere else.

- `@JvmStatic` on companion functions Java calls statically; `@JvmField` for constants-like fields; `@JvmOverloads`
  where default arguments must be visible as overloads; `@JvmName` to resolve platform clashes or give a better Java
  name; `@Throws` on functions Java callers need to catch as checked exceptions.
- `const val` for compile-time constants Java needs; a `companion object` is acceptable here (it is the exception to the
  "no `companion object` constants" rule above).
- Prefer Java-friendly types at the boundary (`List`, `Map`, `Function`/`Supplier`) over Kotlin-only ones (`Sequence`,
  `suspend`, `Result`, inline value classes — which are mangled).
- Nullability annotations (`@Nullable`/`@NotNull`) are inferred from Kotlin types; keep them accurate.
- Remember the Boolean naming rule: Java sees `isFoo()` for `val foo: Boolean`.

## Testing (Kotlin)

Generic structure (Given/When/Then, fixtures, commands) lives in `testing.md`. Kotlin specifics:

- **Check neighbouring tests first.** A repo's established test conventions outrank this file and `testing.md` — e.g.
  some repos use `snake_case` test names with no Given/When/Then. Follow the repo; don't "fix" it.
- **Names:** backticks with spaces — `` fun `should return calculator for metric type`() ``.
- **Assertions:** match the repo — `kotlin.test` (`kotlin.test.assertEquals`) or JUnit 5
  (`org.junit.jupiter.api.Assertions.assertEquals`); a repo without a `kotlin.test` dependency can only use JUnit 5.
  Default to pure JUnit 5; do not introduce AssertJ into a file that doesn't already use it, and never mix AssertJ and
  JUnit assertions in one file. Individual imports, no wildcards.
- **`@Test`:** `org.junit.jupiter.api.Test`, not `kotlin.test.Test`.
- **Parameterized:** `@ParameterizedTest` with `@EnumSource`/`@ValueSource`/`@MethodSource`.
- **Structure:** `// Given / When / Then` comments in every test, own line (see `testing.md`).
- **Field initialization:** `var x: Type = default` when a sensible default exists; `lateinit var` only for fields with
  no default, set in `@BeforeEach`.
- **Coroutines:** exactly one `runTest` wrapping the whole test body (`fun \`...\`() = runTest { ... }` or a block
  inside). Not `runBlocking`, not several builders per test, and don't return `TestResult` from a non-`runTest` function.
  `runBlocking` only when a real clock is needed (`runTest`'s virtual clock skips `delay`). Don't copy a neighbour's
  `runBlocking`.
- **Exception assertions** go under `// Then`, never `// When`. `// When` captures the action as a lambda; `// Then`
  asserts. Applies to non-suspend tests too. `org.junit.jupiter.api.assertThrows` does not accept suspend lambdas, so
  capture a `suspend { }` and call it inside the assertion:
  ```kotlin
  // When
  val action = suspend { mySuspendFun() }

  // Then
  val thrown = assertThrows<MyException> { action() }
  assertEquals("expected message", thrown.message)
  ```
- **JSON ↔ data class:** verify the mapping (nullable vs non-nullable fields); test both `null` and `{}` for optional
  fields. Enum constants in test data match production exactly (`SOME_CONSTANT`) — check `src/main/kotlin/` if a test
  fails.

### Mockk

- **Mockk** is the mocking library for Kotlin — not Mockito.
- **Class level:** mocks with default stubs (returns empty/false) + the service under test.
- **Per test:** all data (ids, flags, ...) declared inside the test, never as class fields.
- **Test data objects:** a single `data` variable of the full type; reference `data.field` in `verify`. Do not split it
  into separate field variables.
  ```kotlin
  val data = ReportPayload(
      sections = mapOf("SUMMARY" to listOf<Any>()),
      recommendations = emptyMap(),
  )
  coEvery { fetchService.buildPayload(entityId, enabled, baselineId) } returns data
  // ...
  coVerify { repo.upsert(Report(runId, entityId, enabled, data.sections, emptyMap())) }
  ```
- `coEvery`/`coVerify` for suspend functions; `every`/`verify` otherwise. Type arguments on `mockk<T>()` stay (inference
  can't supply them).
