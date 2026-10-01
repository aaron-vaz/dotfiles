---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Kotlin Code Style

## Core Principle — Write Kotlin, Not Java in Kotlin Syntax

Never write Kotlin like Java dev. Line translates one-to-one back to Java → find Kotlin way:
null-safe types over null checks, expressions over statements, `data class` over POJO, extension functions over
`*Utils` classes, stdlib collection operators over loops, default and named arguments over overloads and builders.

**Exception: code consumed from Java.** Java callers exist → follow Java interop conventions (see
[Java Interop](#java-interop)), keep Java-friendly shape. Verify Java caller actually exists (grep for class in `*.java` files, check module's consumers). "Might be called from Java someday" not reason.

Check neighbouring files and repo conventions before applying anything below; repo's established style beats this
file (see Testing).

## Null Safety

- Model absence in type: `String?` vs `String`. Never sentinel (`""`, `-1`) for "missing".
- Prefer `?.`, `?:`, `let`, smart casts over `!!`. `!!` only when invariant guaranteed and comment or
  `requireNotNull`/`checkNotNull` message add nothing.
- `?:` carries control flow as guard clause: `val user = repo.find(id) ?: return null`,
  `?: throw NotFoundException(id)`, `?: error("...")`.
- No null-check on non-nullable values (`param != null` on `String`), including Reactor/Java lambdas whose
  parameters Kotlin-typed non-null.
- `as?` over `as` + `is` pre-check; `filterNotNull()`/`mapNotNull` over filter then `!!`.
- Treat Java platform types (`String!`) as nullable at boundary: declare type explicitly
  (`val name: String? = javaObj.name`) when Java side can return null.
- `lateinit` only for framework-injected state (DI, test setup); never domain data. Prefer constructor injection.
- `Optional` only at Java boundaries; never in Kotlin signatures.

## Immutability & Data

- `val` over `var`, immutable collection types (`List`, `Set`, `Map`) over mutable, `copy()` over mutation.
- Mutable collections may live in `val` — mutability is of contents.
- **Read-only is not immutable.** `List`/`Set`/`Map` are read-only *views*; caller may still hold mutable
  original. Defensive copy (`toList()`, `toSet()`, `toMap()`) when storing collection received from outside or
  returning internal mutable state. Never expose `MutableList` through `List` return type without copy.
- Value carriers = `data class` with `val` properties. No getters/setters, no builders, no hand-written `equals`/`hashCode`. Named arguments plus defaults instead of builder.
- Single-field wrapper for type safety = `@JvmInline value class` (`EmployeeId`, `CustomerId`), not `data class`.
- Stateless marker/singleton = `data object` (free `toString`), not plain `object`.
- Closed hierarchies = `sealed interface`/`sealed class` with exhaustive `when` and **no `else` branch**, so new
  subtypes fail compilation.
- Fixed sets = `enum class`. Use `entries` (not `values()`); give enums properties/functions rather than
  parallel `when` in another file.
- `Path` (`java.nio.file.Path`, `kotlin.io.path.*`) for file paths, never `String`.
- `typealias` for long generic or function types; not domain concepts (use value class).

## Functions

- Default parameters over overloads. Named arguments for booleans and several same-typed parameters; no mixing
  named and positional in one call.
- Single-expression bodies (`fun answer() = 42`) when body one expression. Explicit return type
  for public API and non-trivial expression bodies.
- **Extension functions and top-level functions over util classes** — any form: `object SomeUtils`, class with
  private constructor and statics, `companion object` of helpers. Operates on type → extension on it; no natural receiver → top-level. Extension discoverable via autocomplete:
  `context.registry`, not `ResourceUtils.getRegistry(context)`.
- Properties with custom getter over `getX()` functions when value cheap and side-effect free.
- **Extension property vs member property:**
  - *Member property* (declared in class) for type's own state or identity, and computed value
    (`val fullName get() = "$first $last"`) that is part of type's concept when type is yours.
  - *Extension property* for derived view on type you don't own (`val Path.extensionOrNull`, `val
    ExtensionContext.registry`), or on own type when value belongs to different layer and shouldn't widen
    type (persistence/mapping/presentation: `val Report.dto`). Extension properties have **no backing field** — getter
    only, no initializer, no state.
  - Either way getter cheap, pure, non-throwing — property reads as field. I/O, expensive allocation, can fail, or not idempotent → function (`loadX()`, `toX()`), not property.
  - Member always wins over same-name extension: extension duplicating member is dead code
    (compiler warns). Never name extension after stdlib/member API with different semantics.
- Trailing lambda syntax; name parameter when `it` unclear or lambda nested (never nest `it`).
- No function that only forwards arguments; no one-line helper wrapping stdlib call.
- **Operators where possible.** Method meaning matches Kotlin operator convention → define as `operator
  fun` instead of named method: `get`/`set` (`registry[key]` over `registry.get(key)`), `contains` (`x in set`),
  `plus`/`minus`/`times` (`a + b`, `metrics + tracing + logging` for composable handlers), `plusAssign`, `unaryMinus`,
  `invoke` (`validator(x)` for single-purpose function-like class), `compareTo` (`<`, `>`; implement `Comparable`),
  `iterator` (`for (x in thing)`), `rangeTo`/`rangeUntil` (`a..b`, `a..<b`), `componentN` (destructuring; automatic on
  `data class`), `getValue`/`setValue` (property delegates). `infix` for readable two-operand domain call
  (`a shouldBe b`, `key to value`). Operator must keep conventional meaning — never `plus` that mutates, or
  `get` with side effects — never as cleverness where named method reads clearer.
- `inline` only for functions taking lambdas (and `reified` type parameters). Not micro-optimization.
- `inline fun <reified T>` factory over passing `SomeType::class.java` at call sites.
- `@Deprecated` in new code uses `ReplaceWith`, and `DeprecationLevel.ERROR` when migration mechanical.
- Function taking `Boolean` flags that change behavior → two functions or enum.

## Classes & Objects

- Declare properties in primary constructor (`class Foo(private val bar: Bar)`); no separate field + assignment.
  `init` blocks only for validation or non-trivial derived state.
- Constructor injection; no field injection. Unused injected dependencies = dead code.
- No getter/setter pairs, no `Impl` suffix, no `Abstract*` base class when interface with default methods does it.
  Internal implementations of public interface are `Real*` (`RealReadoutCaptor`).
- Composition over inheritance. Forwarding every call to wrapped instance = `class Foo : Bar by impl`.
- Visibility: `private` default; `internal` for module-internal; public only for actual API. Everything
  `final` by default — no `open` unless subclass exists (framework-proxied classes handled by
  `kotlin-spring` / all-open plugin, not sprinkled `open`).
- Single-method interfaces consumed by lambdas = `fun interface`.
- `object` for real singletons only; stateless collection of functions = top-level functions.
- `lazy` for expensive, once-only properties (`val p by lazy { compute() }`); other delegates (`observable`, maps) when
  fit — no hand-rolled backing field.
- Backing property (`_items` private mutable, `items` public read-only) to expose read-only view of mutable state.

### Top-Level Constants and Functions — Not `companion object` or Util `object`s

**Constants, helper functions, factories = top-level declarations.** Never `companion object` that only holds
them, never `object FooUtils`/`FooHelper` (or `class` with `@JvmStatic` statics) that only holds functions —
both Java `static` habits. Kotlin has no statics; file is namespace.

- Constants: top-level `const val` (or `val` for non-primitive) in same file as class using them.
- Helpers used by one class: `private` top-level functions in that file. Used wider: top-level or extension functions
  in concern/type-named file (see File Organization).
- Factories and default instances: top-level `fun Foo(...): Foo` / top-level `val` (see below).
- `object` for real singleton with identity or state; `companion object` for what genuinely needs instance.

Details for constants:

- **Top-level `const val` in same file**, not `companion object` wrapping constants.
- `private const val` default; drop `private` only when something outside file genuinely needs it (test
  asserting bound, another class in module).
- `companion object` holding only constants = Java habit — creates real object and extra indirection for
  something compiler can inline. Reserve `companion object` for things needing instance:
  interface implementations and `@JvmStatic`/`@JvmField` interop.

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

- Factories = **file-level functions** named like type — `fun ReadoutClient(...): ReadoutClient` — over
  `companion object { fun create() }`. Singleton/default instances = top-level `val`s (`by lazy` if expensive).

## Namespacing Top-Level Declarations

Top-level code has no class to namespace it: public top-level name visible to whole package and, once imported,
shows in autocomplete everywhere. Being deliberate here = price of dropping `companion object`/`object` utils.

- **Least visibility first.** Top-level declarations `private` (file-scoped) by default, `internal` when module
  needs them, public only for real API. `private` top-level invisible outside file, can't collide.
- **Package is namespace.** Organise by feature/domain (`...notes`, `...readout`), not kind (`...utils`,
  `...constants`, `...helpers`). Public top-level lives in package owning concept; never catch-all
  package or root package.
- **Names carry own context.** No surrounding class → `MAX_LENGTH`, `DEFAULT_TIMEOUT`, `parse()`
  ambiguous. Name for concept: `MAX_NOTE_LENGTH`, `DEFAULT_READOUT_TIMEOUT`, `parseReadoutId()`. Private constant
  used by one class can stay short — file is context.
- **Extensions on widely used types scoped.** `fun String.clean()` or `fun Collection<T>.second()` pollutes every
  `String`/`Collection` in scope. Make `private`/`internal`, or give specific name and feature package so
  import is deliberate choice. Receiver is domain type: public fine. Never public extensions named like stdlib
  function.
- **File name = concern, named like stdlib.** File is unit of grouping (and JVM class `FooKt`). One file per
  receiver type's extensions or per concern, plain noun (`Strings.kt`, `Preconditions.kt` — see File
  Organization); no grab-bag `Constants.kt`/`Functions.kt`/`Utils.kt` for whole module.
- **No top-level mutable state** (`var`, mutable collections): no owner, no lifecycle. Shared state belongs in
  class with owner or DI-managed bean.
- **Collisions resolved at import**, not by prefixing names: `import com.a.Foo as AFoo`.
- **Prefix on several functions = missing namespace.** Top-level functions sharing prefix (`jsonEncode`,
  `jsonDecode`, `jsonPretty`) belong in own file/package, on receiver type, or in class holding
  dependencies. Named `object` acceptable only where qualified call site itself is point (`Json.encode(x)`)
  and functions share no state with type — not default home for helpers.
- **Java callers** of top-level code get `FileNameKt.fn()`; set `@file:JvmName("Notes")` for clean name (see Java
  Interop).

## Collections

- Stdlib operators over manual loops: `map`, `filter`, `mapNotNull`, `flatMap`, `groupBy`, `associate`, `associateBy`,
  `partition`, `fold`, `sumOf`, `any`/`all`/`none`, `firstOrNull`, `getOrPut`, `buildList`/`buildMap`/`buildString`.
- Plain `for` only for side effects or when early exit makes operator chain harder to read.
- Parameters and return types `List<T>`/`Set<T>`/`Map<K, V>`, never `ArrayList`/`HashSet`/`HashMap`.
- Factory functions: `listOf`, `setOf`, `mapOf`, `emptyList()`, `mutableListOf` — not `arrayListOf` or `ArrayList()`.
- Map access `map["key"]` / `map["key"] = v`, destructuring in loops (`for ((k, v) in map)`), `to` for pairs.
- `firstOrNull()`/`singleOrNull()` over `first()`/`single()` when empty possible; `first()` only when emptiness is
  bug and exception wanted.
- `isEmpty()`/`isNotEmpty()`/`isNullOrEmpty()` over `size == 0`; `any { }` over `filter { }.isNotEmpty()`;
  `count { }` over `filter { }.size`.
- `Sequence` (`asSequence()`) only for large data or lazy multi-step chains with early termination; typical short
  lists: plain chain clearer and faster.
- No chained transformations obscuring simple logic (`map().let{}.takeIf{}?.let{}` pipeline). Split into named
  steps when reader can't follow in 30 seconds.

## Control Flow

- `if`, `when`, `try` are expressions — `return if (x) a else b`, `val v = when (x) { ... }`. No ternary.
- `if` for two branches, `when` for three+. `when (subject)` for type or value matching, bare `when { }` for
  boolean conditions; no `is` checks mixed into boolean `when`.
- Guard clauses and early returns (see code-style.md). `?: return`/`?: continue` keeps happy path flat.
- Smart casts over explicit casts; no re-checking type compiler already knows.
- Ranges: `0..<n` (not `0..n - 1`), `step`, `downTo`; `until` only in older code. Iterate indices with `indices` /
  `withIndex()`, never `for (i in 0 until list.size)`.
- No C-style loops; no `break`/`continue` with labels unless nested loops truly need it.
- No `Unit`-returning ceremony: no `return Unit` or `: Unit`.

## Strings

- String templates over concatenation, `StringBuilder`, or `String.format`: `"Size ${children.size}"`, `"Name $name"`
  (no braces for simple identifier).
- `buildString { }` when assembling in loop.
- Raw strings with `trimIndent()`/`trimMargin()` for multi-line text, not `\n` concatenation.
- `isBlank()`/`isNotBlank()` and `ifBlank { }`/`takeIf` over manual `trim().isEmpty()`.

## Scope Functions

Use sparingly — only when adding clarity. **Removing scope function makes code equally or more readable →
remove it.**

| Function | Use |
|----------|-----|
| `apply` | Builder/DSL configuration, conditional object mutation; replaces builder's `return this` |
| `let` | Transform/project value, or run block on non-null (`value?.let { ... }`) |
| `also` | Side effects (logging, registering) without changing value |
| `takeIf` / `takeUnless` | Conditional values and validation (`x.takeIf { !it.isNaN() } ?: 1.0`) |
| `fold` | Accumulation pipelines |

- **Never `run` or `with`.**
- No pointless `let` on non-null (`name.let { it.length }`); no nested scope functions; no chained
  `let { }.run { }.also { }`.
- No redundant `this.` in extension functions or methods — use implicit receiver.

## Error Handling

- Validate with `require(cond) { "msg" }` (arguments), `check(cond) { "msg" }` (state), `requireNotNull`/`checkNotNull`,
  and `error("msg")` for unreachable branches or missing registry entries (`map[key] ?: error("No handler for $key")`).
  No `if (!x) throw IllegalArgumentException(...)`.
- Catch **specific** exception types. Not `Exception`, not `Throwable`; let NPE/`IllegalStateException`/OOME propagate as
  bugs they are.
- `runCatching` catches *everything* (programming errors, `CancellationException`, JVM errors). Only on
  happy-path-only code where any failure converts to `Result`, with `fold`/`getOrElse`; never when error types need
  distinguishing, never in coroutine code without rethrowing `CancellationException`.
- Never discard exception context: no `catch (_: X)`, log and chain — `catch (e: X) { log.warn("...", e); throw
  Wrapped(cause = e) }`.
- Kotlin has no checked exceptions: no declaring/annotating throws unless Java callers need `@Throws` (see Java Interop).
- Resources: `use { }` over try/finally.
- Return `null` or sealed result type for *expected* absence/failure; exceptions for bugs and exceptional conditions.
- No exceptions for control flow.

## Coroutines

- `suspend` functions over blocking calls. No `runBlocking` in production code (tests: see Testing), no `.block()` inside
  coroutines — use `suspend` + `awaitFirst()`/`awaitSingle()`/`asFlow()`.
- Structured concurrency: every coroutine belongs to scope tied to lifecycle. No `GlobalScope`.
- `coroutineScope { }` when one child's failure should cancel siblings; `supervisorScope { }` for independent
  parallel work. Shared `CoroutineScope` across independent listeners needs `SupervisorJob` per listener.
- `async` always paired with `await()` — fire-and-forget `async` swallows exceptions; use `launch`.
- Never swallow `CancellationException`: catch and rethrow, or catch narrower types.
- `Flow`: `flowOn(dispatcher)` to change context (never `withContext` inside `flow { }`); `channelFlow { send() }` when
  emitting from several coroutines; `flow { emit() }` single-coroutine only. Expose `Flow`, keep `MutableSharedFlow`
  / `MutableStateFlow` private behind read-only view.
- Dispatchers: shared `Dispatchers.Default`/`IO` fine on JVM server; long-lived daemon gets own named
  `Executors`-backed dispatcher. Inject dispatchers (or delays) where tests need control.
- Make time and delays injectable (`var delay: suspend (Long) -> Unit`) so tests run retry/backoff instantly.
- No blocking I/O on `Dispatchers.Default`; wrap blocking calls in `withContext(Dispatchers.IO)`.

## Naming & Formatting

- Packages lowercase, no underscores. Types UpperCamelCase. Functions/properties lowerCamelCase. Constants
  `SCREAMING_SNAKE_CASE`. Backing property `_elementList`. No meaningless names: `Util`, `Manager`, `Wrapper`,
  `Helper`.
- Acronyms: two letters stay upper (`IOStream`), longer capitalize first (`XmlFormatter`).
- **Booleans: no `is` prefix** on properties or locals — `qualified`, `confirmed`, `skewPrevented`, not `isQualified`.
  Kotlin exposes `val foo: Boolean` to Java as `getFoo()` and `val isFoo: Boolean` as `isFoo()` — prefix is a naming
  choice Kotlin doesn't add for you; repo rule is to drop it. Functions may use it (`isEmpty()`).
- Trailing commas in multi-line parameter lists, argument lists, collection literals.
- Spaces around binary operators (not `..`/`..<`), none around `.`, `?.`, `::`; no space before `?` in nullable type.
- Modifier order: visibility, `expect/actual`, `final/open/abstract/sealed/const`, `external`, `override`, `lateinit`,
  `tailrec`, `vararg`, `suspend`, `inner`, `enum/annotation/fun`, `companion`, `inline/value`, `infix`, `operator`,
  `data`.
- Class layout: properties and `init` blocks, secondary constructors, methods, `companion object`, nested classes.
  Group related members logically, not alphabetically; interface implementations keep interface's order.
- No annotating types compiler infers: no `val x: String = "a"` on locals, **no redundant type arguments**
  (`listOf(a, b)`, `ChangeChannel(name, UUID::toString, UUID::fromString)`). Keep only where inference fails:
  empty collections, untyped `mockk<T>()`, `MutableSharedFlow<T>()` with no seed.
- Unused `it` parameters get no name; unused lambda parameters are `_`; never shadow outer `it`.
- `@Suppress` only on narrowest scope with reason; no blanket suppression.
- Comments explain non-obvious *why* in code's own terms. Never narrate task numbers, design-doc decisions, or
  spec scenario names. KDoc (`/** */`) on public API; `@see` for related types.

## Imports

- No wildcard imports — explicit only (`import kotlin.test.*`, `import org.junit.jupiter.api.Assertions.*` included).
- Normal `import` by default. Inline FQN only for actual name collisions, not habit. Inline FQN already in
  file is drift, not precedent: new code imports type, existing FQNs converted when touched.
  - Bad: `java.util.concurrent.atomic.AtomicInteger(0)` with no colliding import.
  - Good: `import java.util.concurrent.atomic.AtomicInteger` then `AtomicInteger(0)`.

## File Organization

- **Name extension and top-level function files like stdlib does.** Stdlib files are plain nouns, no
  `Utils`/`Extensions`/`Helper` suffix: `Strings.kt`, `Collections.kt`, `Maps.kt`, `Sequences.kt`, `Ranges.kt`,
  `Comparisons.kt`, `Preconditions.kt`, `Lazy.kt`.
  - **Extensions on type**: plural of receiver type — `Paths.kt`, `Instants.kt`, `ExtensionContexts.kt`,
    `Readouts.kt` (domain type). Extensions on family of types go in family's plural (`Collections.kt` for
    `Collection`/`List`/`Set`).
  - **Top-level functions with no receiver**: plain noun for concern — `Preconditions.kt`, `Errors.kt`,
    `Transform.kt`, `Retries.kt`.
  - Never `*Utils.kt`, `*Util.kt`, `*Helper(s).kt`, `*Extensions.kt`, `*Ext.kt`, or bare `Utils.kt`/`Common.kt`.
- One primary declaration per file, named for it. File named for purpose rather than type may trip ktlint's
  filename rule; suppress with `@file:Suppress("ktlint:standard:filename")`.
- Keep coupled code together (annotation with its provider/processor); keep `data class` and extensions forming
  its public API in separate files.
- `internal/` subdirectory for implementation detail hidden from module consumers.
- `@PublishedApi internal` for non-public symbols touched by public `inline`/`reified` function.
- Repos with explicit-API mode: declare visibility and return types for public declarations explicitly.

## Idiomatic Gotchas

- `==` structural equality; `===` reference identity. Never `.equals()`.
- Stdlib before inventing: `require`, `lazy`, `use`, `buildList`, `Duration` (`5.seconds`, `kotlin.time`) over raw
  `Long` millis, `measureTimedValue`.
- `kotlin.time.Duration` / `java.time` over `Long`/`Int` for time; `Instant`/`LocalDate` over `Date`.
- `String.toIntOrNull()`/`toLongOrNull()` over try/catch around `toInt()`.
- `Comparator`: `compareBy`, `sortedBy`, `sortedWith(compareBy(...).thenBy(...))`.
- `Pair`/`Triple` only locally; return small `data class` from public functions.
- Destructuring only for `Pair`, `Map.Entry`, data classes with obvious component order.
- DSLs: lambdas with receivers (`Foo.() -> Unit`) with `@DslMarker` for nested builders.
- No reflection (`::class.java`, `javaClass`) at call sites when `reified` helper hides it.
- No literal Java API translation: `StringUtils.isEmpty(s)` → `s.isNullOrEmpty()`, `Collections.emptyList()` →
  `emptyList()`, `new Foo()` → `Foo()`, `getX()` → `x`, anonymous `Runnable` → lambda, `synchronized` blocks →
  coroutine `Mutex` or `@Synchronized` only on Java-facing method.

## Logging

- Logger = **top-level `private val`** in file, not `companion object` field (same rule as constants):
  `private val log = LoggerFactory.getLogger("com.example.Foo")` or repo's KotlinLogging equivalent
  (`private val log = KotlinLogging.logger {}`). Match repo's logging library.
- Never `println`/`print`/`printStackTrace` in committed code. Use logger, exception as last argument
  (`log.warn("msg", e)`).
- Parameterized messages (`log.info("saved {}", id)`) or library's lambda form
  (`log.debug { "expensive $x" }`) so disabled levels don't build string.

## Time

- Inject `java.time.Clock` (or repo's equivalent), read time from it. Never call `Instant.now()`,
  `LocalDate.now()`, `System.currentTimeMillis()` or `Clock.systemUTC()` inside logic; tests can't control them.
- `kotlin.time.Duration` (`5.seconds`, `Duration.ofMinutes(5)` at Java boundaries) over raw `Long`/`Int` millis or
  seconds in signatures and constants. Bare number whose unit not in type must carry it in name
  (`timeoutMillis`).
- `Instant` for points in time, `LocalDate`/`LocalDateTime` only for calendar values without zone; never `Date` or
  `Calendar`.

## Data Classes, Entities & Equality

- `data class` for value objects/DTOs. Generated `equals`/`hashCode`/`toString` use *all* constructor
  properties — wrong for identity-based or lazily-loaded types.
- **JPA/Hibernate entities not `data class`es** (equality over lazy proxies and generated ids breaks, `copy`
  bypasses persistence state). Regular class with `kotlin-jpa` (no-arg constructor) plus an explicit
  `allOpen { annotation("jakarta.persistence.Entity") ... }` block for proxies — `kotlin-spring` does not open entities. Explicit identity-based `equals`/`hashCode` only if persistence layer needs them.
- No arrays (`ByteArray`, `Array<T>`) as `data class` properties — compare by reference. Use `List<T>`, or
  override `equals`/`hashCode` with `contentEquals`/`contentHashCode`.
- Keep properties `val`, constructor only way to build valid instance; validate in `init` with `require`.
- `data class` with `private` constructor still exposes `copy()` — don't rely on privacy for invariants
  unless compiler warning for it addressed (check repo's Kotlin version).

## Banned in Committed Code

- `TODO()` and `println` (use logger; no `TODO()` throwing at runtime — open ticket instead).
- Blanket `@Suppress`, and `@Suppress("UNCHECKED_CAST")` where `reified` type parameter, `as?` or restructured API
  works. Suppression truly needed → narrowest scope plus one-line reason.
- `Any`/`Any?`-typed APIs where generic or sealed type works; `as` casts replaceable by smart cast or `when (x) { is ... }`.
- `!!` without guaranteed invariant (see Null Safety); `lateinit` for domain data; mutable top-level state.
- `GlobalScope`, `runBlocking` in production, `Thread.sleep` (use `delay`) in coroutine code.
- Commented-out code and dead `private` functions/properties.

## Formatting & Lint Tools Decide

- ktlint/Spotless/detekt (whichever repo configures) authoritative for formatting and style. No hand-formatting
  against them, no reflowing file you aren't changing, no `@Suppress`/`.editorconfig` exceptions just to
  pass check. Run formatter task (`spotlessApply` or `ktlintFormat`) rather than editing whitespace by hand.
- This file and repo's configured rules disagree on something tool enforces → tool wins; tool
  silent → this file applies.

## Serialization

Use library repo already uses (check build manifest — Jackson with Kotlin module, or
`kotlinx.serialization`); don't introduce other.

- Map nullability and defaults in type: `val x: String? = null` / `val x: Int = 0` rather than annotating every
  property. Jackson's Kotlin module binds constructor properties by name — no `@JsonProperty` boilerplate unless
  JSON name differs; `@field:`/`@get:` use-site targets for annotations that must land on field/getter.
- Prefer `data class` DTOs with `val` properties and defaults over mutable beans, builders, or `@JsonCreator` factories.
- `kotlinx.serialization`: `@Serializable` on class, `@SerialName` for differing names, `@Transient` for
  excluded properties (needs default), sealed hierarchies for polymorphism.
- Enums: serialize by stable name, never ordinal; unknown-value handling is deliberate decision.
- Test both `null` and absent for optional fields (see Testing).

## Newer Language Features

Features land in Kotlin versions repo may not have. **Read Kotlin version from build manifest
(`build.gradle.kts`/version catalog/`pom.xml`) before using any of these**, never assume from memory:

- `when` guard conditions (`is Foo if cond ->`), explicit backing fields, context parameters, name-based destructuring,
  `kotlin.uuid.Uuid`, newer `kotlin.time` APIs (`Clock`/`Instant`), and `data object` (`1.9+`).
- Version supports feature removing workaround (e.g. `entries` over `values()`, `..<` over `until`) → use it;
  project on older version → don't, and don't "upgrade" build to get it.
- Experimental APIs (`@OptIn`, `@ExperimentalXxx`) need explicit decision and narrowest opt-in scope — never
  module-wide `-opt-in` flag to silence warning.

## Gradle Kotlin DSL (`*.gradle.kts`, `*.kts`)

Build scripts are Kotlin too — same top-level/immutability/naming rules apply, plus:

- Dependencies and plugin versions from **version catalog** (`libs.versions.toml`); no hard-coded versions or
  string coordinates scattered across modules.
- Type-safe accessors (`libs.foo`, `project.the<...>()`, `tasks.named<Test>("test")`) over string lookups.
- Lazy task APIs: `tasks.register` over `tasks.create`, `tasks.named` over `tasks.getByName`, `configureEach` over
  `all`/`afterEvaluate`.
- Shared build logic in convention plugins (`buildSrc` or `build-logic`), not copy-pasted blocks between modules.
- Pin toolchain (`kotlin { jvmToolchain(N) }`), treat compiler warnings as errors where repo already does.
- Scripts stay declarative: no I/O or network at configuration time, no mutable top-level `var`s for state.

## Java Interop

Applies only when Java code calls this Kotlin (or code is library for mixed callers). Kotlin-idiomatic form
stays default everywhere else.

- `@JvmStatic` on companion functions Java calls statically; `@JvmField` for constants-like fields; `@JvmOverloads`
  where default arguments must be visible as overloads; `@JvmName` to resolve platform clashes or give better Java
  name; `@Throws` on functions Java callers need to catch as checked exceptions.
- `const val` for compile-time constants Java needs; `companion object` acceptable here (exception to
  "no `companion object` constants" rule above).
- Prefer Java-friendly types at boundary (`List`, `Map`, `Function`/`Supplier`) over Kotlin-only (`Sequence`,
  `suspend`, `Result`, inline value classes — mangled).
- Nullability annotations (`@Nullable`/`@NotNull`) inferred from Kotlin types; keep accurate.
- Boolean naming rule: Java sees `getFoo()` for `val foo: Boolean`, `isFoo()` for `val isFoo: Boolean`.

## Testing (Kotlin)

Generic structure (Given/When/Then, fixtures, commands) in `testing.md`. Kotlin specifics:

- **Check neighbouring tests first.** Repo's established test conventions outrank this file and `testing.md` — e.g.
  some repos use `snake_case` test names with no Given/When/Then. Follow repo; don't "fix" it.
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