---
name: deslop-essay-rules-are-prose-only
description: Essay style rules (em dashes, absolutes, adverbs, bold bullets, three-item lists) destroy meaning in code comments and reference docs — never apply them there
type: feedback
tags: [writing, deslop, code-style, comments, documentation]
status: active
---

Prose-craft rules optimise for voice. Code comments and reference docs optimise for precision under
skim. Do not apply the first set to the second.

Specifically, these are correct in a KDoc, a schema comment or an AGENTS.md entry even though an
essay checklist bans them:

- **never / always / every** — in prose, lazy hedging. In a comment, an **invariant**, which is a
  universal claim by definition. "Never zero, so an empty body is refused" is the precise wording;
  making it "specific" makes it weaker.
- **Adverbs, banned as a class** — `silently` and `deliberately` name a failure mode and an intent.
  "Anything placed on it silently no-ops in production" has no content without the adverb. Cut the
  *empty* ones (really, just, simply, actually, genuinely); keep the load-bearing ones.
- **Wh- sentence openers** — "When X, Y" is the standard form for a precondition.
- **Bold-first bullets** — correct for scannable reference docs, which is what an AGENTS.md is.
- **Three-item lists** — sometimes there are three things.
- **Scoring on rhythm / authenticity** — meaningless for a commit body or a KDoc block.

**Why:** A style rule imported from a different register looks like an improvement and is a
regression. The failure is invisible, because each individual edit reads fine — the loss only shows
up later, when a comment no longer states the guarantee it was written to state.

**How to apply:** When applying any writing checklist, first ask what register it was written for.
Adopt the rules that are register-independent — filler, jargon, vague claims, repeated rationale —
and explicitly omit the rest, in writing, so the next reader does not re-import them. Where a repo's
own AGENTS.md states a style, that wins over any general checklist.

Do not vendor a third-party rules file wholesale out of fidelity to the source. Take what applies and
link the original.

Corollary, learned the hard way in the same session: before writing a rule down anywhere, check
whether `~/.claude/rules/*` already says it. A style rule that is always loaded does not also need a
KB entry, and a second copy is the very duplication this entry warns about.

## Related

- [[slop-pass-runs-against-the-diff-not-once-per-session]]
