---
name: "delegate-simple-work-to-sonnet-subagents"
description: "Always dispatch Sonnet subagents (Agent tool, model: sonnet) for simple non-reasoning work — file edits, mechanical renames, format tweaks. Main thread keeps reasoning, design and verification."
type: feedback
tags: [subagents, delegation, models, workflow, cost]
status: active
---

Always dispatch Sonnet subagents for simpler work that needs no reasoning: file edits, mechanical
renames, applying an already-decided change, format-preserving tweaks, boilerplate.

**Why:** User instruction (2026-09-28). Keeps expensive main-thread model on reasoning, and main
context smaller — edits happen out of context.

**How to apply:**
- Once the change is decided (what file, what edit), hand it to `Agent` with `model: "sonnet"`
  (or a Sonnet-backed agent type such as `caveman:cavecrew-builder` for 1-2 file edits). Give it the
  exact edit spec: path, old/new text or precise description, constraints.
- Independent edits → parallel subagents in one message.
- Keep in main thread: investigation needing judgement, design decisions, debugging, reviewing the
  subagent's result, running builds/tests to verify.

## Related

- [[fetch-before-reading-another-repo]]
