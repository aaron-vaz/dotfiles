---
name: deslop
description: Classifier for writing that wastes the reader - filler, jargon, vague claims, and the same rationale restated in more than one place. Use before committing code comments or KDoc, and when drafting a PR description, commit body, KB entry, AGENTS.md entry, spec text, Jira ticket or Slack message. Also use when asked to "deslop" something or told it reads as AI-generated.
---

# Deslop

Rules for writing that has to survive a skim: code comments, KDoc, commit bodies, PR descriptions,
KB and AGENTS.md entries, spec text, tickets.

Derived from [stephenturner/skill-deslop](https://github.com/stephenturner/skill-deslop), which
targets essays and blog posts. The essay-specific half is deliberately **not** carried over — see
*What this deliberately omits*.

This is a classifier. It tells you what to cut. It does not make you remember to look, so run it
against a diff at a fixed point (before commit), not "when finalising".

## The rule that does the damage

**State a rationale once, at the site that enforces it.** Everywhere else states the rule in a line
and points at that site.

A copied explanation looks thorough and is not: each copy ages independently, and when the rule
changes one of them starts lying. This is the one that survives review, because every individual copy
looks reasonable.

Detection: grep an eight-word phrase from a comment you just wrote; more than one file means you have
it. That only catches verbatim copies — **paraphrase defeats it**, so the check is ultimately reading,
not grepping. A cleanup that reduces six copies to four reworded ones has fixed nothing.

Exception: a test that pins an invariant is a legitimate second site. Stating the rule in the test
that would fail if it broke is not duplication.

## Cut on sight

- **Openers**: "Here's the thing", "Here's why", "It turns out", "The truth is", "Let me be clear"
- **Emphasis**: "Full stop.", "Period.", "Let that sink in.", "Make no mistake", "This matters because"
- **Hand-holding**: "Let's break this down", "Let's unpack", "Let's dive in", "Think of it as"
- **Hedges**: "It's worth noting", "It bears mentioning", "Notably", "At its core", "At the end of the
  day", "When it comes to", "The reality is"
- **Closers**: "In conclusion", "To sum up", "In summary", "As we've seen"
- **Empty adverbs**: really, just, literally, genuinely, honestly, simply, actually, truly

## Replace

"serves as" / "stands as" / "represents" (meaning *is*) → **is** · leverage, utilize → **use** ·
robust → **strong** · harness → **use** · streamline → **simplify** · deep dive → **analysis** ·
navigate (problems) → **handle** · delve → **examine** · nuanced → **specific**

Leave a term alone when it is the correct technical noun. "Framework" in a Spring codebase is a
framework.

## Be concrete

- **Vague declaratives**: "The implications are significant", "The stakes are high", "The reasons are
  structural" → say what the implication is.
- **Vague attribution**: "Experts argue", "Industry reports suggest" → name the source, or drop it.
- **Stakes inflation**: "fundamentally reshapes", "defines the next era" → scale to the actual stakes.
- **Invented labels**: "the supervision paradox" → describe it plainly.
- **Superficial participles**: "highlighting its enduring legacy", "reflecting broader trends" →
  make a specific claim or delete.
- **False agency**: "the culture shifts", "the data tells us" → name who. This does **not** apply to
  named code entities: "the sweep republishes", "the guard refuses" are correct.

## Code comments

A comment earns its place by stating something a reader could not get from re-reading the code: a
hidden constraint, a non-obvious invariant, a framework gotcha, a real *why*.

Delete:

- **Narrates the change**: "Added X", "Now uses Y instead of Z". If it only makes sense to someone who
  watched the diff, it is not a comment.
- **Narrates history or a rejected alternative**: "used to do X", "tried Y first". That is the commit
  message's job. Recording a rejected alternative is fine when the *reason* is the constraint —
  "an index rather than a table constraint, because Postgres has no ADD CONSTRAINT IF NOT EXISTS".
- **Restates a well-named identifier**: `// increment the counter` above `counter++`.
- **Rotting citations**: task numbers, ticket ids, design-doc sections, a vendored file's "fetched on"
  date with no commit SHA. Watch for the **naked ordinal** — `// 7.4 batch selection:` — which reads
  as prose and survives every keyword grep. Only reading finds it.

Where a repo's own AGENTS.md states a comment policy, that policy wins and this section defers to it.

## What this deliberately omits

Upstream bans these. They are essay-craft, and applied to technical writing they destroy meaning:

- **Em dashes, rhythm rules, "not every paragraph ends punchily"** — no meaning in a KDoc block.
- **never / always / every** — in prose, lazy hedging. In a comment, an **invariant**. "Never zero,
  so an empty body is refused" is the correct wording; making it "specific" makes it weaker.
- **Adverbs, as a blanket ban** — `silently` and `deliberately` name failure modes and intent.
  "Anything placed on it silently no-ops in production" loses its content without the adverb. Cut
  the empty ones listed above; keep the load-bearing ones.
- **Wh- sentence openers** — "When X, Y" is the standard form for a precondition.
- **Bold-first bullets** — correct for scannable reference docs, which is what AGENTS.md is.
- **Three-item lists** — sometimes there are three things.
- **Scoring prose 1-10 on rhythm and authenticity** — meaningless for a commit message.

If you are writing an actual essay, go read upstream.
