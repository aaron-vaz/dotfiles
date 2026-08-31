---
name: test-behavior-not-framework-mechanism
description: A test must assert on product-observable behavior, not on whether a framework mechanism (cache hit/miss counts, key generation) agrees with itself — if the test environment disables what you need (e.g. caching off in ITs), override it selectively for one isolated test rather than downgrading to a lower-level test of the mechanism
type: feedback
tags: [testing, spring, caching]
status: active
---

A regression test must assert on the actual product-observable behavior the bug report described,
not on internals of the framework mechanism that happens to be involved. If the right level to
observe that behavior is disabled by default in the test environment, turn it on selectively for
one isolated test — don't retreat to testing the mechanism in isolation instead.

**Why:** Fixed a real bug in social-sync-api: `UserTrackClient`'s cache wasn't evicted correctly on
a track change, so `GET /blocks` kept listing a track-inappropriate block as already-completed.
First test attempt (`UserTrackCacheKeyMatchingTest`) wired the real `UserTrackClient` bean into a
Spring context and asserted on the mock gRPC stub's *call count* (1 load, cache hit, evict, 1 more
load) — still fundamentally testing "does Spring's key generator agree with itself," not "does the
reported bug stay fixed." User pushed back three times, each one sharper: first "isn't that just
testing Spring," then after wiring the real bean, "again you are just testing Spring cache through
the bean, is there a point," then the reframe that broke it open: "caches should be turned off in
tests anyway, its a spring abstraction why should we test that?" That last point was empirically
true here — every module IT in this codebase runs with `spring.cache.type=none`
(`IsolatedContextProperties`), so a cache-staleness bug categorically cannot reproduce in the
default IT setup; the mechanism-level unit test could never have been replaced by "just do it at IT
level" without first fixing that. The actual fix: a **new, isolated IT class** overriding
`@IntegrationTest(properties = ["spring.cache.type=caffeine"])` (the codebase's own documented,
context-cache-safe override mechanism — see `QuestionnaireLocaleIT`'s KDoc), asserting only on the
real `GET /blocks` response body (does the stale block disappear), never on cache internals.
Verified it actually catches the regression by temporarily reverting the fix and confirming the
test failed at the expected line, then restoring the fix and confirming green.

**How to apply:** Before writing a regression test, ask: "does this assertion match what the bug
report actually said was wrong?" If the assertion is about a framework's internal consistency
(cache keys matching, a proxy being invoked, a bean being wired) rather than the user-observable
symptom, that's a sign to go up a level, not stay at the mechanism. If the environment disables the
mechanism you need (check for something like `spring.cache.type=none` set globally in test
fixtures), the fix is a scoped override for one dedicated test class — most frameworks that disable
a mechanism by default in tests also provide a documented, safe way to re-enable it narrowly; look
for that before assuming the behavior is untestable or downgrading to a lower-level test. Always
verify a new regression test actually catches the regression: temporarily revert the fix, confirm
the test fails at the expected place, then restore the fix and confirm it passes again — a test that
was never seen to fail is not proven to test anything.

## Related

- [[default-runtest-over-runblocking-in-new-coroutine-tests]]
