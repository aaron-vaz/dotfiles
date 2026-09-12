---
name: 2026-09-06-assertthrows-belongs-in-then
description: assertThrows is an assertion and goes under `// Then`, never `// When` — the When block captures the action as a lambda (`val action = { ... }` / `suspend { ... }`), Then does `val thrown = assertThrows<X> { action() }` and inspects it. Applies to non-suspend code too, not just the runTest case the testing rule documents. Aaron's correction on the change-signal tests.
type: feedback
tags: [testing, kotlin, junit, given-when-then, assertions]
status: active
date: 2026-09-06
---

**Rule:** `assertThrows` (and any `assertFailsWith`/`runCatching`-then-assert variant) lives under
`// Then`. `// When` holds the action only, captured as a lambda so it can be invoked from Then:

```kotlin
// When
val action = { ChangeChannel<String>("Bad-Name", { it }, { it }) }

// Then
val thrown = assertThrows<IllegalArgumentException> { action() }
assertContains(thrown.message.orEmpty(), "lower-case Postgres identifier")
```

For a suspending action inside `runTest`, `val action = suspend { ... }` and the same
`assertThrows { action() }` — `org.junit.jupiter.api.assertThrows` is `inline`, so the suspend
call inside its lambda compiles. Do not substitute `runCatching { action() }.exceptionOrNull()`
plus `assertIs`; that is the same assertion with a worse failure message.

**Why:** Aaron: "your assert throws goes against my prefs", on tests that wrote
`// When val thrown = assertThrows<X> { doIt() }`. The testing rule already shows the
capture-then-assert shape for `runTest`; the point is that it is the shape for *every* exception
test, because `assertThrows` is the assertion and the When/Then split is meaningless if the
assertion sits in When. Also: a `map { assertThrows ... }` over several inputs in When is the same
mistake multiplied.

**How to apply:**
- Before writing an exception test, write the three sections first: Given (inputs), When
  (`val action = { ... }`), Then (`assertThrows` + message/type assertions).
- Several inputs that must all fail: loop in Then, or one test per input — never a `map` of
  `assertThrows` in When.
- Existing files in a repo may carry the When-placed form. Follow the preference for anything you
  write; do not reformat the pre-existing tests unless asked.

Related: [[2026-09-05-composed-integration-test-properties-alias]]
