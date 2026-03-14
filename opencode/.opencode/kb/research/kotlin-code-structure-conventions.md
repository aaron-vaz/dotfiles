# Kotlin Code Structure Conventions (Gold Standard)

**Sources:** kotlinx.coroutines, OkHttp (Square), Ktor

---

## kotlinx.coroutines

**Package structure:** Feature-first (`flow/`), then role-by-subdirectory: `operators/`, `terminal/`, `internal/`. One file per semantic concern.

**Operator file naming:** Named by operation category — `Errors.kt`, `Transform.kt`, `Limit.kt`, `Delay.kt`, `Distinct.kt`, `Merge.kt`, `Zip.kt`. No `*Extensions.kt` pattern.

**`internal` modifier:** Helpers shared across files within a module are `internal`, not `private`. Applies to functions, constructors, and companion members.

---

## OkHttp (Square)

**Package structure:** Public API is a flat list of domain types in `okhttp3/` (one file per type). All implementation in `okhttp3/internal/` with subdirectories by protocol/concern (`http/`, `http2/`, `tls/`, `connection/`).

**`Real*` prefix:** Concrete implementations of public interfaces are always `internal class Real*` — `RealInterceptorChain`, `RealCall`, `RealWebSocket`.

**Companion objects:** Hold `internal` constants only. Public construction goes through nested `Builder` class.

**`operator fun invoke` on companion:** Used on `fun interface` types to provide clean lambda construction syntax: `Interceptor { chain -> ... }`.

---

## Ktor

**Lowercase filenames for top-level-function-only files:** `builders.kt`, `utils.kt` — lowercase signals "this file contains no type definition, only top-level functions." Type-defining files are always `PascalCase.kt`.

**File-level factory functions over companion objects:** `HttpClient(block)` is a file-level function sharing the class name — no companion object needed for factories.

**`internal` constructor on public classes:** `internal constructor(...)` forces consumers through factory functions while keeping the class public.

---

## Adoption Priorities for egtnl-learnings-api

| Priority | Pattern | Example |
|----------|---------|---------|
| High | Concern-named function files | `Errors.kt`, `Captors.kt` not `ReadoutUtils.kt` |
| ~~High~~ | ~~Lowercase = top-level functions, PascalCase = types~~ | Not adopted — preference is PascalCase throughout |
| High | `internal/` subdirectory for implementation | `readout/internal/RealReadoutCaptor.kt` |
| High | `Real*` prefix for internal implementations | `internal class RealReadoutLearningsCaptor` |
| Medium | File-level factory functions over companion objects | `fun ReadoutClient(...): ReadoutClient` at file level |
| Medium | No `*Extensions.kt` — fold into concern-named files | Extensions on `Flow<Learning>` go in `Transform.kt` |
| Medium | `internal constructor` on public classes | Forces consumers through factory |
| Low | `operator fun invoke` on companion for `fun interface` | Clean lambda construction for captor interfaces |