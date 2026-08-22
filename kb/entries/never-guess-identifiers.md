---
name: never-guess-identifiers
description: Always look up identifiers from source, never invent them
type: feedback
tags: [domain-rules, identifiers, naming]
status: active
---

Never guess domain identifiers (metric IDs, entity types, templates, terminology, API names, config keys). Look them up from source.

**Why:** Invented identifiers cause silent failures, wrong API calls, broken configs. Agent training data is stale — identifiers change, get renamed, deprecated. Guessing wastes debugging time when the invented name doesn't exist.

**How to apply:**
- About to reference a domain-specific name → search codebase, docs, or KB first
- Uncertain about exact spelling/casing → grep or ask, don't assume
- Error message mentions identifier → copy exact string, don't paraphrase
- If lookup fails → say "couldn't find X", don't substitute plausible-sounding alternative

## Related

- [[never-assume-library-versions]]
