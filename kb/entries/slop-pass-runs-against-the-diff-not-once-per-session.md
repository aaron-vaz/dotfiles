---
name: slop-pass-runs-against-the-diff-not-once-per-session
description: A comment/prose cleanup pass covers everything written since the last pass — running it once and then writing more leaves the new writing unchecked
type: feedback
tags: [writing, deslop, self-review, process, comments]
status: active
---

The unit a cleanup pass covers is **the diff since the last pass**, not the session. Running it once
and then continuing to write leaves everything after it unexamined.

**Why:** This failed for real. `/self-review` step 6 was run against one subagent's edits, then
roughly a hundred more comment lines were written in a later batch and the pass never re-ran. The
user spotted the result before any check did. The criteria were never the missing piece — they were
already written down in the skill and in the repo's own AGENTS.md — so adding more rules would not
have helped. What was missing was re-running.

A related trap: a cleanup that removes *verbatim* duplicates and leaves paraphrased ones makes the
problem undetectable rather than fixing it. The eight-word-shingle grep then returns clean while four
reworded copies remain. Judge by reading, and count copies of the *idea*, not the wording.

**How to apply:** After any batch of writing — code comments, KDoc, docs, spec text — re-run the
cleanup against `git diff` before committing, however recently the last pass ran. Treat "I already
did the slop pass this session" as evidence of nothing.

A classifier skill cannot enforce this; it has to be attached to a fixed point in the workflow
(a pre-commit hook) or to a mechanical check (a grep task wired into the build's `check`, alongside
whatever similar greps that project already runs). Prefer the mechanical one — it does not forget,
and it covers humans and other agents rather than only the one who wrote the rule.

## Related

- [[deslop-essay-rules-are-prose-only]]
