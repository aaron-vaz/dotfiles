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
- **Read-only is not immutable.** `List`/`Set`/`Map` are read-only *views*; the caller may still hold the mutable
  original. Take a defensive copy (`toList()`, `toSet()`, `toMap()`) when storing a collection received from outside or
  returning internal mutable state — never expose a `MutableList` through a `List` return type without copying.
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
- **Extension functions and top-level functions over util classes** — in any form: `object SomeUtils`, a class with a
  private constructor and statics, a `companion object` of helpers. Operating on a type means an extension on it; a
  function with no natural receiver is just top-level. An extension is discoverable via autocomplete:
  `context.registry`, not `ResourceUtils.getRegistry(context)`.
- Properties with a custom getter over `getX()` functions when the value is cheap and side-effect free.
- **Extension property vs member property:**
  - *Member property* (declared in the class) for the type's own state or identity, and for a computed value
    (`val fullName get() = "$first $last"`) that is part of the type's concept and the type is yours.
  - *Extension property* for a derived view on a type you don't own (`val Path.extensionOrNull`, `val
    ExtensionContext.registry`), or on your own type when the value belongs to a different layer and shouldn't widen the
    type (persistence/mapping/presentation: `val Report.dto`). Extension properties have **no backing field** — a getter
    only, no initializer, no state.
  - Either way the getter is cheap, pure and non-throwing, since a property reads as a field. Anything that does I/O,
    allocates something expensive, can fail, or isn't idempotent is a function (`loadX()`, `toX()`), not a property.
  - A member always wins over an extension of the same name: an extension that duplicates a member is dead code
    (the compiler warns). Never name an extension after a stdlib/member API with different semantics.
- Trailing lambda syntax; name the parameter when `it` would be unclear or the lambda is nested (never nest `it`).
- Don't write a function that only forwards its arguments, and don't wrap a stdlib call in a one-line helper.
- **Operators where possible.** When a method's meaning matches a Kotlin operator convention, define it as an `operator
  fun` instead of a named method: `get`/`set` (`registry[key]` over `registry.get(key)`), `contains` (`x in set`),
  `plus`/`minus`/`times` (`a + b`, `metrics + tracing + logging` for composable handlers), `plusAssign`, `unaryMinus`,
  `invoke` (`validator(x)` for a single-purpose function-like class), `compareTo` (`<`, `>`; implement `Comparable`),
  `iterator` (`for (x in thing)`), `rangeTo`/`rangeUntil` (`a..b`, `a..<b`), `componentN` (destructuring; automatic on
  `data class`), `getValue`/`setValue` (property delegates). Use `infix` for a readable two-operand domain call
  (`a shouldBe b`, `key to value`). The operator must keep its conventional meaning — never `plus` that mutates, or
  `get` with side effects — and never as cleverness where the named method reads clearer.
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

### Top-Level Constants and Functions — Not `companion object` or Util `object`s

**Constants, helper functions and factories are top-level declarations.** Never a `companion object` that only holds
them, and never an `object FooUtils`/`FooHelper` (or `class` with `@JvmStatic` statics) that only holds functions —
both are Java `static` habits. Kotlin has no statics; the file is the namespace.

- Constants: top-level `const val` (or `val` for non-primitive) in the same file as the class using them.
- Helpers used by one class: `private` top-level functions in that file. Used wider: top-level or extension functions
  in a concern/type-named file (see File Organization).
- Factories and default instances: top-level `fun Foo(...): Foo` / top-level `val` (see below).
- `object` is for a real singleton with identity or state; `companion object` is for what genuinely needs an instance.

Details for constants:

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

## Namespacing Top-Level Declarations

Top-level code has no class to namespace it: a public top-level name is visible to the whole package and, once imported,
shows up in autocomplete wherever it is. Being deliberate here is the price of dropping `companion object`/`object` utils.

- **Least visibility first.** Top-level declarations are `private` (file-scoped) by default, `internal` when the module
  needs them, public only for real API. A `private` top-level is invisible outside its file, so it can't collide.
- **The package is the namespace.** Organise by feature/domain (`...notes`, `...readout`), not by kind (`...utils`,
  `...constants`, `...helpers`). A public top-level lives in the package that owns the concept; never in a catch-all
  package or the root package.
- **Names carry their own context.** Without a surrounding class, `MAX_LENGTH`, `DEFAULT_TIMEOUT` or `parse()` is
  ambiguous. Name for the concept: `MAX_NOTE_LENGTH`, `DEFAULT_READOUT_TIMEOUT`, `parseReadoutId()`. A private constant
  used by one class can stay short — the file is its context.
- **Extensions on widely used types are scoped.** `fun String.clean()` or `fun Collection<T>.second()` pollutes every
  `String`/`Collection` in scope. Make them `private`/`internal`, or give them a specific name and a feature package so
  an import is a deliberate choice. Receiver is a domain type: public is fine. Never public extensions named like a stdlib
  function.
- **File name = concern, named like the stdlib.** A file is the unit of grouping (and the JVM class `FooKt`). One file per
  receiver type's extensions or per concern, as a plain noun (`Strings.kt`, `Preconditions.kt` — see File
  Organization); don't build a grab-bag `Constants.kt`/`Functions.kt`/`Utils.kt` for the whole module.
- **No top-level mutable state** (`var`, mutable collections): there is no owner and no lifecycle. Shared state belongs in
  a class with an owner or a DI-managed bean.
- **Collisions are resolved at the import**, not by prefixing names: `import com.a.Foo as AFoo`.
- **A prefix on several functions is a missing namespace.** If top-level functions share a prefix (`jsonEncode`,
  `jsonDecode`, `jsonPretty`) they belong in their own file/package, on a receiver type, or in a class that holds
  dependencies. A named `object` is acceptable only where the qualified call site is itself the point (`Json.encode(x)`)
  and the functions share no state with a type — not as a default home for helpers.
- **Java callers** of top-level code get `FileNameKt.fn()`; set `@file:JvmName("Notes")` for a clean name (see Java
  Interop).

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

- **Name extension and top-level function files the way the stdlib does.** The stdlib's files are plain nouns with no
  `Utils`/`Extensions`/`Helper` suffix: `Strings.kt`, `Collections.kt`, `Maps.kt`, `Sequences.kt`, `Ranges.kt`,
  `Comparisons.kt`, `Preconditions.kt`, `Lazy.kt`.
  - **Extensions on a type**: the plural of the receiver type — `Paths.kt`, `Instants.kt`, `ExtensionContexts.kt`,
    `Readouts.kt` (domain type). Extensions on a family of types go in the family's plural (`Collections.kt` for
    `Collection`/`List`/`Set`).
  - **Top-level functions with no receiver**: the plain noun for the concern — `Preconditions.kt`, `Errors.kt`,
    `Transform.kt`, `Retries.kt`.
  - Never `*Utils.kt`, `*Util.kt`, `*Helper(s).kt`, `*Extensions.kt`, `*Ext.kt`, or a bare `Utils.kt`/`Common.kt`.
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
- DSLs: lambdas with receivers (`Foo.() -> Unit`) with `@DslMarker` for nested builders.
- Don't use reflection (`::class.java`, `javaClass`) at call sites when a `reified` helper hides it.
- Don't translate Java APIs literally: `StringUtils.isEmpty(s)` → `s.isNullOrEmpty()`, `Collections.emptyList()` →
  `emptyList()`, `new Foo()` → `Foo()`, `getX()` → `x`, anonymous `Runnable` → lambda, `synchronized` blocks →
  coroutine `Mutex` or `@Synchronized` only on a Java-facing method.

## Logging

- The logger is a **top-level `private val`** in the file, not a `companion object` field (same rule as constants):
  `private val log = LoggerFactory.getLogger("com.example.Foo")` or the repo's KotlinLogging equivalent
  (`private val log = KotlinLogging.logger {}`). Match the repo's logging library.
- Never `println`/`print`/`printStackTrace` in committed code. Use the logger, with the exception as the last argument
  (`log.warn("msg", e)`).
- Use parameterized messages (`log.info("saved {}", id)`) or the lambda form your library offers
  (`log.debug { "expensive $x" }`) so disabled levels don't build the string.

## Time

- Inject a `java.time.Clock` (or the repo's equivalent) and read time from it. Never call `Instant.now()`,
  `LocalDate.now()`, `System.currentTimeMillis()` or `Clock.systemUTC()` inside logic; tests can't control them.
- `kotlin.time.Duration` (`5.seconds`, `Duration.ofMinutes(5)` at Java boundaries) over raw `Long`/`Int` millis or
  seconds in signatures and constants. A bare number whose unit isn't in the type must carry it in the name
  (`timeoutMillis`).
- `Instant` for points in time, `LocalDate`/`LocalDateTime` only for calendar values without a zone; never `Date` or
  `Calendar`.

## Data Classes, Entities & Equality

- `data class` is for value objects/DTOs. Its generated `equals`/`hashCode`/`toString` use *all* constructor
  properties — wrong for identity-based or lazily-loaded types.
- **JPA/Hibernate entities are not `data class`es** (equality over lazy proxies and generated ids breaks, and `copy`
  bypasses persistence state). Use a regular class with the no-arg/all-open compiler plugins (`kotlin-jpa`,
  `kotlin-spring`) and explicit identity-based `equals`/`hashCode` only if the persistence layer needs them.
- No arrays (`ByteArray`, `Array<T>`) as `data class` properties — they compare by reference. Use `List<T>`, or
  override `equals`/`hashCode` with `contentEquals`/`contentHashCode`.
- Keep properties `val` and the constructor the only way to build a valid instance; validate in `init` with `require`.
- A `data class` with a `private` constructor still exposes `copy()` — don't rely on privacy to enforce invariants
  unless the compiler warning for it is addressed (check the repo's Kotlin version).

## Banned in Committed Code

- `TODO()` and `println` (use the logger; leave no `TODO()` throwing at runtime — open a ticket instead).
- Blanket `@Suppress`, and `@Suppress("UNCHECKED_CAST")` where a `reified` type parameter, `as?` or a restructured API
  works. If a suppression is truly needed, narrowest scope plus a one-line reason.
- `Any`/`Any?`-typed APIs where a generic or sealed type works; `as` casts that a smart cast or `when (x) { is ... }`
  could replace.
- `!!` without a guaranteed invariant (see Null Safety); `lateinit` for domain data; mutable top-level state.
- `GlobalScope`, `runBlocking` in production, `Thread.sleep` (use `delay`) in coroutine code.
- Commented-out code and dead `private` functions/properties.

## Formatting & Lint Tools Decide

- ktlint/Spotless/detekt (whichever the repo configures) are authoritative for formatting and style. Don't hand-format
  against them, don't reflow a file you aren't changing, and don't add `@Suppress`/`.editorconfig` exceptions just to
  pass a check. Run the formatter task (`spotlessApply` or `ktlintFormat`) rather than editing whitespace by hand.
- When this file and the repo's configured rules disagree on something the tool enforces, the tool wins; when the tool is
  silent, this file applies.

## Serialization

Use whichever library the repo already uses (check the build manifest — Jackson with the Kotlin module, or
`kotlinx.serialization`); don't introduce the other.

- Map nullability and defaults in the type: `val x: String? = null` / `val x: Int = 0` rather than annotating every
  property. With Jackson's Kotlin module, constructor properties bind by name — no `@JsonProperty` boilerplate unless
  the JSON name differs; `@field:`/`@get:` use-site targets for annotations that must land on the field/getter.
- Prefer `data class` DTOs with `val` properties and defaults over mutable beans, builders or `@JsonCreator` factories.
- With `kotlinx.serialization`: `@Serializable` on the class, `@SerialName` for differing names, `@Transient` for
  excluded properties (needs a default), sealed hierarchies for polymorphism.
- Enums: serialize by stable name, never by ordinal; unknown-value handling is a deliberate decision.
- Test both `null` and absent for optional fields (see Testing).

## Newer Language Features

Features land in Kotlin versions the repo may not have. **Read the Kotlin version from the build manifest
(`build.gradle.kts`/version catalog/`pom.xml`) before using any of these**, and never assume it from memory:

- `when` guard conditions (`is Foo if cond ->`), explicit backing fields, context parameters, name-based destructuring,
  `kotlin.uuid.Uuid`, newer `kotlin.time` APIs (`Clock`/`Instant`), and `data object` (`1.9+`).
- If the version supports a feature that removes a workaround (e.g. `entries` over `values()`, `..<` over `until`), use it;
  if the project is on an older version, don't, and don't "upgrade" the build to get it.
- Experimental APIs (`@OptIn`, `@ExperimentalXxx`) need an explicit decision and the narrowest opt-in scope — never a
  module-wide `-opt-in` flag to silence a warning.

## Gradle Kotlin DSL (`*.gradle.kts`, `*.kts`)

Build scripts are Kotlin too — the same top-level/immutability/naming rules apply, plus:

- Dependencies and plugin versions come from the **version catalog** (`libs.versions.toml`); no hard-coded versions or
  string coordinates scattered across modules.
- Type-safe accessors (`libs.foo`, `project.the<...>()`, `tasks.named<Test>("test")`) over string lookups.
- Lazy task APIs: `tasks.register` over `tasks.create`, `tasks.named` over `tasks.getByName`, `configureEach` over
  `all`/`afterEvaluate`.
- Shared build logic lives in convention plugins (`buildSrc` or `build-logic`), not copy-pasted blocks between modules.
- Pin the toolchain (`kotlin { jvmToolchain(N) }`) and treat compiler warnings as errors where the repo already does.
- Scripts stay declarative: no I/O or network at configuration time, no mutable top-level `var`s for state.

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
- **No relaxed mocks by default** (`mockk(relaxed = true)`): they hide unstubbed calls. Stub what the test needs; use a
  relaxed mock only for a collaborator the test truly ignores, and say why.
- **Verify precisely:** `verify(exactly = n)`/`coVerify(exactly = n)` when the count matters, `verify { ... wasNot Called }`
  for "never", and `confirmVerified(mock)` where unexpected extra calls would be a bug.

### Test data factories

- Build test data with **top-level factory functions with default arguments** (`fun aReport(id: UUID = randomUuid(),
  status: Status = Status.OPEN) = Report(id, status)`), overriding only what the test is about. No builder classes, no
  shared mutable fixtures, and no `object TestData` grab-bag.
- Keep a factory next to the tests that use it, in a concern-named file (`ReportFixtures.kt`); share across modules
  only through a test-fixtures source set.
- Inject a fixed `Clock` (`Clock.fixed(...)`) instead of reading the real time in tests (see Time).
