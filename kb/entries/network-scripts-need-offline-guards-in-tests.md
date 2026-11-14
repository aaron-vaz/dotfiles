---
name: network-scripts-need-offline-guards-in-tests
description: Tests (and mutation checks) of scripts that call a real third-party API must make every refusal row fail before any network call, so a broken guard cannot reach the real service.
type: feedback
tags: [testing, live-scripts, mutation-testing, safety]
status: active
---

When a script can call a real external service (a live API check), its tests, and any reviewer's mutation tests of its guards, must not be able to reach that service even if a guard is removed.

**Why:** in a 2026-11-09 review, a mutation that deleted two precondition guards in a live-API script let the test rows (fake keys, free port) go on to send real token requests to the production API. No real key was involved, but real requests left the machine. The tests only failed after the call was made.

**How to apply:**
- Give every refusal row in such a test a reason the script stops before the first network call, for example a port that is already busy, a stubbed HTTP proxy, or an unroutable base URL. Do not rely on the guard under test being the only barrier.
- When briefing a reviewer or implementer to mutation-test a network script, say explicitly: run mutants only with the network blocked (no proxy, or an unroutable host), and never run a mutant of a guard that sits before a real call.
- Keep fake credentials obviously fake, and never run a script copy against a live service.

## Related

- [[delete-completed-plans]]
