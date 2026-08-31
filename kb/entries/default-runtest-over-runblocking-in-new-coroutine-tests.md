---
name: default-runtest-over-runblocking-in-new-coroutine-tests
description: Use runTest, not runBlocking, for a new coroutine test, and use exactly one runTest encompassing the whole test body. The only sanctioned reason for runBlocking is a real clock for real polling, since runTest's virtual clock skips delay(). Covers the traps — copying a neighbouring file, runTest returning TestResult rather than the lambda's value, and splitting one test across several builders.
type: feedback
tags: [kotlin, coroutines, testing, kotlinx-coroutines-test]
status: active
---

Default to `kotlinx.coroutines.test.runTest` for a new coroutine-based test (`suspend fun`, `Flow`,
and friends). Reach for `runBlocking` only when the test has a concrete reason to need a *real*
clock, never as a default habit.

**Why:** caught twice now, both times by the same question — "why runBlocking, not runTest?" — and
both times there was no answer beyond habit or imitation. `runTest` is the documented default in my
own testing rules (`~/.claude/rules/testing.md`: "`runTest` block — use for all coroutine-based
tests"), and both times the test converted cleanly and passed unchanged, which is proof the
`runBlocking` was never load-bearing.

## The one real reason: a real clock for real polling

`runTest` runs on a **virtual clock** — it advances `delay()` instantly instead of elapsing real
time. That is a feature when testing timeouts and retries, and a silent bug when the test is waiting
for genuinely asynchronous work (a fire-and-forget listener, a background write, a round trip landing
out of band) to complete for real:

```kotlin
// Broken under runTest: the loop spins through all 25 iterations in one tick,
// so the only real elapsed time is the 25 DB round trips it makes.
repeat(25) {
    row = repository.findById(id)
    if (row?.processedAt != null) return@repeat
    delay(200.milliseconds)   // virtual — does not wait
}
```

Two fixes, both fine:

```kotlin
// Keep runTest, opt one delay out of the virtual clock:
withContext(Dispatchers.Default) { delay(200.milliseconds) }

// Or use runBlocking, which has a real clock and needs no wrapping:
fun `waits for the listener to land`() = runBlocking { /* poll with a bare delay */ }
```

So: **if the sentence "this test needs a real clock because ___" has no ending, it is `runTest`.**
No `delay`, no polling, no fire-and-forget work means the virtual scheduler has nothing to interact
with badly.

Don't assume a framework's coroutine bridging needs `runBlocking` either (Spring AOP proxies,
reactive bridges, anything that might hop threads internally). Write a scratch copy with `runTest`
and run it before concluding otherwise; several bridge fine when no real timing is involved.

## Trap 1 — the trigger is usually imitation, not habit

The second occurrence was not habit. It was **modelling a new test file on the existing file being
extended**, which happened to use `runBlocking` throughout for no stated reason. That is the "nearby
code uses it" justification my own PR-review rules reject, and it survives self-review precisely
because the new file looks internally consistent.

**Count the repo, don't read one neighbour.** One `grep -c` per file across the same test category
settles it in seconds; in the case that prompted this, the split was 22 files on `runTest` against 3
on `runBlocking`, and two of those three were the sanctioned real-clock cases.

## Trap 2 — `runTest` returns `TestResult`, not the lambda's value

This breaks any mechanical find-and-replace conversion, and it is a compile error rather than a
silent one, so it is easy to mistake for "the conversion doesn't work here":

```kotlin
// Compiles: runBlocking returns the lambda's value.
val id = runBlocking { insertRow() }

// Does NOT compile: runTest returns TestResult (Unit on JVM).
val id = runTest { insertRow() }
```

The fix is not a holder variable or a `lateinit`. **Hoist the builder to the whole test body**, and
the arrangement calls become plain suspend calls needing no builder at all:

```kotlin
@Test
fun `does the thing`() = runTest {
    // Given
    val id = insertRow()            // direct suspend call, no builder
    val record = seedRecord(id)

    // When / Then
    client.get().uri("/things/$id").exchange().expectStatus().isOk
}
```

A blocking HTTP/test-client call inside `runTest` is fine — there is no `delay` for the virtual
clock to skip.

## One `runTest` per test, encompassing the whole body

`runTest` is the test's coroutine scope, not a helper for bridging individual suspend calls. Sprinkling
several through one test body is wrong even though it compiles and passes: each call builds its own
`TestScope` and scheduler, so the arrangement, the action and the assertions run in three unrelated
scopes with three separate virtual clocks, and nothing structurally ties them together.

```kotlin
// Wrong — three scopes in one test, each with its own clock.
@Test
fun `leaving removes the row`() {
    // Given
    runTest { repository.insert(id) }

    // When
    client.delete().uri("/things/$id").exchange().expectStatus().isNoContent

    // Then
    runTest { assertNull(repository.findById(id)) }
}

// Right — one scope, whole test. Suspend calls are made directly.
@Test
fun `leaving removes the row`() = runTest {
    // Given
    repository.insert(id)

    // When
    client.delete().uri("/things/$id").exchange().expectStatus().isNoContent

    // Then
    assertNull(repository.findById(id))
}
```

A blocking HTTP/test-client call sitting inside that scope is fine — there is no `delay` for the
virtual clock to skip.

The one legitimately separate builder is `@BeforeEach`, which is its own JUnit callback rather than
part of the test body:

```kotlin
@BeforeEach
fun clean() = runTest { repository.deleteAll() }
```

A test whose body suspends nowhere needs no builder at all; leave it a plain function rather than
wrapping it for symmetry.

## Related

- [[test-behavior-not-framework-mechanism]]
