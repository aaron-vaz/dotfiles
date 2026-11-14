---
name: comments-state-reasons-not-the-obvious
description: Code comments (homelab scripts and anywhere "no comments" is a stated rule) — drop comments that restate the code; keep comments that give a reason, trap, constraint or unit. "No comments at all" is too aggressive.
type: feedback
tags: [code-style, comments, homelab, shell, slop]
status: active
---

Aaron, 2026-10-30, when asked whether the homelab "no comments unless requested" rule means
stripping every comment from the rig scripts: "comments stating the obvious is pointless but
maybe that statement is a bit too aggressive".

**Why:** The rule exists to stop slop comments that restate the code (`# loop over the apps`).
Applied literally it also deletes comments that record why a line exists, such as an
`export DOCKER_CONFIG=...` that bypasses a credential helper which fails over ssh. Without that
reason the line looks like a pointless override and gets deleted.

**How to apply:** Keep a comment only when the code cannot say it: a reason, a trap, a constraint,
a unit, or a pointer to the evidence. Delete comments that narrate what the next line does. Keep
shebangs, `shellcheck disable` directives, and usage banners that a script prints as its own help
(check how `--help` reads the file before touching a header). In prose style, write the reason
once; do not repeat it per call site. Plan or task references and agent-instruction-file
references still never belong in comments; see [[no-plan-referencing-code-comments]]
and [[no-agents-md-refs-in-code-or-docs]].

Related: [[deslop-essay-rules-are-prose-only]]
