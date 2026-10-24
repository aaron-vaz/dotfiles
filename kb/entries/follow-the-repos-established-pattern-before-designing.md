---
name: "follow-the-repos-established-pattern-before-designing"
description: "Before designing anything new in a repo (shared utility, test setup, config, base class), find how the repo already solves the same kind of problem and use that shape; do not generalise from the immediate call sites. Name the pattern in the proposal and in worker briefs."
type: feedback
tags: [design, conventions, repo-patterns, delegation, review]
status: active
---

For anything new, first find the repo's established way of doing that kind of thing and follow it. Designing from the call sites in front of you produces something that works but does not look like the rest of the codebase.

**Why:** Aaron (2026-10-24) asked why a shared test helper was proposed as a bare function when the repo already expressed the same need as annotations backed by extensions, several times over. The function was a generalisation of the code being replaced, not a design from the codebase's own conventions, and the worker brief repeated the framing ("add one helper"), so it was built that way. The same shape of mistake covers config, base classes, naming and error handling.

**How to apply:**
- Before proposing a design or briefing a worker for new shared code, find 2-3 existing instances of the same kind of thing (sibling modules, the repo's own AGENTS.md catalogues and annotation or component tables, the nearest existing implementation) and read one end to end.
- State in the proposal which pattern is being followed and where it lives; put the pattern's name and a reference file in every worker brief, never just the outcome ("add a helper").
- Deviate only for a reason that holds in this case, say it up front, and let Aaron decide. A repo's own conventions outrank a tidier general design.

## Related

- [[repo-test-style-beats-global-testing-rules]]
- [[kotlin-fqn-precedent-is-not-a-reason]]
