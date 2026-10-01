---
name: kotlin-fqn-precedent-is-not-a-reason
description: Kotlin — an inline FQN already in the file (e.g. java.time.LocalDateTime) is drift, not precedent; new code imports the type, and the file's existing FQNs get converted when you touch it.
type: feedback
tags: [kotlin, code-style, imports, review]
status: active
date: 2026-09-23
---

Inline fully-qualified names are only for real name collisions. When the file being edited already
writes `java.time.LocalDateTime.now()` inline with no colliding import, do not copy that: import the
type, and convert the file's existing FQNs in the same change.

**Why:** Asked "why is local date time FQN imported?" after I added `java.time.LocalDateTime.now()`
to a test that already used the FQN form throughout. Matching surrounding code is the default, but
not when the surrounding code breaks a standing rule (`rules/code-style.md` → Kotlin Import Style).
Copying drift spreads it and survives review because it "looks consistent".

**How to apply:** Before writing an inline FQN, grep the file's imports for a same-named type. None →
add the import and replace every inline occurrence in that file (spotless will not rejoin chains the
long FQN forced to wrap; collapse them by hand). A real collision (e.g. `kotlinx.datetime.LocalDateTime`
imported alongside) is the only reason to keep one.

## Related

- [[2026-07-19-kotlin-rest-grpc-conventions]]
