---
name: never-assume-library-versions
description: Check project manifest for library versions, never assume from training data
type: feedback
tags: [domain-rules, dependencies, versions]
status: active
---

Never assume library versions from training data. Check `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `build.gradle.kts`, or equivalent — project's manifest is ground truth.

**Why:** Training data cutoff means agent knows old versions. APIs change between major versions. Assuming wrong version leads to deprecated API usage, missing features, broken code. Manifest is always current.

**How to apply:**
- About to use library API → check manifest for version first
- Writing code using framework → verify version supports the API you're using
- Debugging library issue → confirm version before suggesting fixes
- If manifest missing or unclear → ask, don't guess

## Related

- [[never-guess-identifiers]]
