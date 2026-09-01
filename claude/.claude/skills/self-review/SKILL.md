---
name: self-review
description: Use after committing/pushing your own code - acts as staff/principal engineer reviewing your work with direct feedback
---

# Self-Review Workflow

**IMPORTANT: This skill requires using Opus model for staff engineer-level architectural judgment.**

Act as staff engineer: challenge design, not just implementation.

## Workflow

### 1. Determine Scope

Ask user:
```
Reviewing recent commits or full branch?
- Recent: Last N commits (faster, incremental review)
- Full: Entire branch diff vs main (comprehensive)
```

First, so that later steps can see files **created** during the review — `git diff` ignores untracked files, and steps 3 and 5 both add new ones:

```bash
git add -N src/ services/ libs/   # or whatever source roots this repo has; stages nothing
```

Scope it to source roots rather than `git add -N .`. Ignored paths are skipped either way, but untracked-and-unignored scratch files would otherwise join every later `git diff`, `/code-review` included. `git reset` clears the intent-to-add when the review is done.

Then resolve the base branch:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main
```

`origin/`-qualified deliberately: a stale local `main` puts the merge base behind the real fork point, and other people's commits then show up as *your* additions — in the band that auto-edits. (`refs/remotes/origin/HEAD` is set by `git clone` but not by `git remote add` + fetch, and goes stale across a default-branch rename; `git remote set-head origin -a` repairs it. The fallback covers the unset case, so most repos land on `origin/main` regardless.)

Commands below are written against `origin/main`. **Substitute whatever the command above actually resolved, literally, into each one — never carry it in a shell variable.** Each Bash call is a fresh shell, so a `BASE=...` set in one block is empty in the next, and `git log $BASE..HEAD` then degrades silently to `git log ..HEAD` instead of failing.

**Recent commits:**
```bash
git log --oneline -10  # Show last 10 for context
# Ask: "How many commits back to review?"
git diff HEAD~N
```

**Full branch:**
```bash
git diff --merge-base origin/main HEAD
```

**Two-dot, not `git diff origin/main...HEAD`.** Three-dot resolves to `merge-base..HEAD`, which is **committed-only** — it cannot see the working tree. Steps 3 and 5 both write code into the working tree, so a three-dot range means every step after them reviews a snapshot that predates their edits. `git diff HEAD~N` is already two-dot and needs no change.

Whichever scope the user picked, that is the range for the whole review. Later steps refer to it as **the review range**; none of them silently widen it.

### 2. Gather Context

**Branch info:**
```bash
git branch --show-current
git log --oneline origin/main..HEAD              # All commits on branch
git diff --stat --merge-base origin/main HEAD    # Files changed
```

**Read CLAUDE.md** for project patterns and conventions.

**Understand intent:**
- What's being built/fixed?
- Why these changes?
- What's the blast radius?

### 3. Run /code-review

Invoke:
```
Skill(code-review, "high --fix")
```
Effort `high` = broad coverage, may include uncertain findings. `--fix` applies findings to working tree after review completes.

### 4. Rule-Compliance Pass (manual, don't skip — /code-review doesn't know project-local rules)

/code-review hunts correctness/simplification/efficiency bugs generically. It does NOT enforce project-specific style rules unless they happen to be visible in the code it read. After it finishes, manually diff changed files against:

- Project `AGENTS.md`/`CLAUDE.md` (Code Style, Conventions, Anti-Patterns sections)
- `~/.claude/rules/code-style.md`, `~/.claude/rules/testing.md` (global — Given/When/Then labels, guard clauses, `final` usage, boolean naming, file-naming conventions, PR description style)
- Language rule file matching changed file types (`~/.claude/rules/python.md`, etc.)

Watch for what generic review tends to miss: Given/When/Then test labels present and never empty, no `is` prefix on booleans, `Real*`/concern-named files not `*Extensions.kt`, `assertEquals` not `assertTrue(x==y)`, FQN imports over aliases, comments always on their own line. Flag violations same as any other finding.

### 5. Manual Architecture Review

Review for architecture, edge cases, performance, maintainability, and security beyond what tooling caught.

### 6. AI Slop / Commentary Comment Removal

**Runs last, after every other step's edits have landed.** Not a preference — steps 3 and 5 both write code, and code they write carries comments. `/code-review --fix` applies its findings to the working tree and step 5's manual fixes land there too, so a slop pass running before either scans a snapshot that predates the comments most likely to be sloppy. Step 1's range already covers the working tree; this step just has to run after the writes.

**Pass A — comments this review added.** These are in scope for auto-fix. Get the list mechanically rather than skimming:

```bash
git diff <review range> -U0 -- '*.kt' '*.kts' '*.java' '*.py' '*.ts' '*.tsx' '*.go' '*.rs' '*.sql' '*.sh' \
  | grep -E '^(\+\+\+ |@@|\+[[:space:]]*(//|#|/\*|\*)|\+.*(//|#|<!--))'
```

Three details that are each load-bearing, not incidental:
- `^\+[[:space:]]*\*` is what catches **block-comment interiors**. A pattern matching only `/*` openers sees the first line of a KDoc/Javadoc block and none of its prose — which in a doc-comment-heavy repo is most of the comment text in the diff.
- `\+\+\+ ` and `@@` are kept so the output carries **file and line attribution**. Filtering to `+` lines alone yields anonymous comment text, and step 7 requires `file:line` on every finding.
- The pathspec keeps Markdown and YAML out. Without it, `#` matches every added Markdown heading and YAML comment, and any repo whose convention is "update the docs in the same PR" floods this list. **Both passes therefore treat prose files as out of scope** — a sloppy comment added to `AGENTS.md` or an OpenAPI spec is step 4's business, not this step's. Deliberate: this step's criteria are about comments explaining code, and in a prose file every line is prose.

One known false positive: `+val url = "https://..."` matches on the `//` inside the string. Cheaper to eyeball than to exclude.

**Pass B — rotting citations already in the files this review touched.** Narrow on purpose. A comment the branch didn't add is still a comment in a file the branch now owns the state of, and `+`-line scoping is exactly how a violation survives review after review — the branch that finally touches the file never adds the offending line. But sweeping pre-existing comments against *every* criterion below means re-auditing thousands of lines of somebody else's prose, which is how this step gets skipped. So Pass B checks **one** criterion — the rotting-citation one — because it is the only one that is both mechanically detectable and a stated project policy in the repos that ban it:

```bash
git diff --name-only --diff-filter=d <review range> \
  | grep -E '\.(kt|kts|java|py|ts|tsx|go|rs|sql|sh)$' \
  | xargs grep -nE '(//|#|\*)([^/]*[^A-Za-z0-9/])?((design|tasks)\.md|[Tt]ask[[:space:]]+[0-9]|[Dd]ecision[[:space:]]+[0-9]|[Ss]ection[[:space:]]+[0-9]|[A-Z]{2,}-[0-9]+|[0-9]+\.[0-9]+[[:space:]]*[-—:]|\([0-9]+\.[0-9]+[,)])' \
  | grep -vE '(TODO|FIXME)\('
```

`--diff-filter=d` drops deleted paths, which would otherwise fail the `grep`. The final `grep -v` preserves the `TODO(PROJ-1234)` exemption below. The alternation is deliberately wider than a keyword scan — see the naked-ordinal note under that criterion for why, and expect `// 2.5s timeout`-style decimals to slip through as noise.

**Pass B findings are report-only. Never edit a line Pass B found** — not during this step, not after synthesis, not to "just fix the obvious one." They touch code this review did not write, so applying them widens the diff, and that is the user's call. They go into step 7 as their own list. Whole-file scope, never repo-wide: a file the review range never touched is somebody else's PR.

Process every line these commands return. Before touching anything, skip these — they are exempt regardless of how they read:

- **Machine-read comments**: `// ktlint-disable`, `@Suppress(...)` justifications, `# noqa`, `// NOSONAR`, `// language=SQL`, `// noinspection`, `<!-- prettier-ignore -->`, license/copyright headers. Deleting these breaks tooling or legal requirements, not just style.
- **`TODO`/`FIXME` carrying a ticket/issue reference** (`// TODO(PROJ-1234): ...`) — many style guides mandate exactly this form; it looks like the *rotting citation* criterion below but isn't. Exception: if the project's own comment policy bans ticket references outright rather than merely regulating them, the policy wins here too — see the closing paragraph.
- **Mandated doc-comments**: KDoc/Javadoc/docstrings a linter or doc generator requires on public API (`UndocumentedPublicClass`-style rules, Dokka/Sphinx-published surfaces). These get a lighter pass under the *restates the identifier* criterion, never outright deletion.
- **Generated or vendored files** (proto stubs, OpenAPI output, lockfiles) — comments there regenerate on the next build; editing them is wasted or gets silently reverted.

For everything else, sort into two bands:

**Auto-fix now** — Pass A only (high-precision, safe to edit directly, no build/lint breakage possible):
- **Narrates the change** rather than stating a fact about the code as it now stands: `// Added X`, `// Now uses Y instead of Z`, `// Changed to support the new flow`, `// Removed the old check`. If a comment only makes sense to someone who watched the diff happen, delete it.
- **Narrates history or a rejected alternative**: `// used to do X`, `// tried Y first but it broke Z`, `// discovered while debugging #123`. That belongs in the commit message or PR description, not permanent source. Delete it.

**Report into step 7 findings** (judgment calls, false-positive-prone, or requiring evidence you don't have from the diff alone). A Pass A hit here may be fixed once the user has seen the synthesis; a **Pass B hit is never fixed by you** at any point — report it and stop:
- **Cites a ticket, task number, PR, or a design-doc section that will rot** (`// per task 4.2`, `// see PROJ-1234`, `// as decided in design.md section 8a`), and isn't the mandated-`TODO` form above.

  **The form that actually survives review is the naked ordinal** — a bare number with no `task`/`per`/`see`/`ref` lead-in for a keyword scan to catch: `// 11.6 — a failure here must never roll back the write it describes`, `// 10.7 — the unconditional path is deliberate`. It reads as prose, so skimming misses it and a keyword grep misses it. Pass B's command is what finds these; four things about its shape matter if you ever edit it:

  - **No `^` anchor.** Anchoring to line start makes every trailing comment (`val x = retry(3) // 11.6 — ...`) invisible, which recreates the original miss one column to the right.
  - **An optional prose gap between the comment marker and the citation**, ending in any non-alphanumeric, so lead-in forms (`// per task 4.2`, `// as decided in design.md section 8a`) match alongside naked ones. Requiring that gap to end in **whitespace** is the obvious version and it is wrong: it cannot cross a bracket, so `(task 2.3)` and `(design.md ...)` — a citation parenthesised mid-sentence, which is how most of them are actually written — are invisible. That mistake hid four real citations across one repo.
  - **A required `—`/`:`/`-` after a bare `N.N`**, which is what keeps `// 2.5s timeout` and `# 1.5x speedup` out. Numbered doc headings (` * 1.2 Overview`) still slip through; they land in this report band, so they cost a glance rather than an edit.
  - **A separate `\(N.N[,)]` branch for parenthesised ordinals**, which carry no separator to key on: `Setup (10.2), the guard (10.3, via 7.9's claim), teardown (10.6)`. This form is common in a class-level doc that cites several tasks in one sentence, and the separator-based branch misses all of it. Its cost is one false-positive class — a standalone decimal in parens, ` (0.0)` — which no pattern separates from a citation, because they are structurally identical.

  **One form is knowingly undetectable: a bare ordinal followed by a word.** `/** 10.5 expiry sweep entry point` is a citation; `// 3.5 hours wide` and `// 0.9 of the total` are measurements. They are the same shape, and a branch matching the first flags every decimal in prose — tested, and it produced three false positives on a fixture of twenty-four lines. So the pattern deliberately does not try, and this form is found only by reading.

  **Treat the output as a net, not a proof, and treat a green fixture as even less.** An earlier version of this grep passed a fourteen-form fixture and then missed two real citations on the very next branch it ran against — one of them the bare-ordinal form above, the other hidden behind a parenthesis the prefix could not cross. The fixture had been built from forms already seen, so it confirmed the pattern against its own training set. When Pass B returns nothing, that is evidence the mechanical forms are gone and nothing more; say that, rather than "no citations found".

  Before flagging, check whether ticket references are already common elsewhere in this codebase (`git grep` a sample) — if they are, that's the project's real convention even if AGENTS.md never wrote it down, and this isn't a finding. **That hatch is void when the project's AGENTS.md/CLAUDE.md bans the form explicitly**: a written policy outranks the prevailing practice, and prevalence is then evidence of accumulated debt rather than of convention. Read the policy before running the prevalence check, not after. Where the criterion does apply and the reasoning is genuinely load-bearing, the fix is to inline the reasoning itself and drop only the pointer — keep the sentence, delete the citation prefix.
- **Restates what a well-named identifier already says.** Exempt if it's a mandated doc-comment (see above); otherwise flag for removal.
- **Repeats the same rationale verbatim in more than one file or call site.** *Search* repo-wide to find every copy — that is not in tension with Pass B's whole-file scope, which bounds what you may *report and change*, not what you may look at. Keep the one closest to the constraint it documents; only copies inside the review range are yours to point at it or delete.
- **Uses LLM hedge/filler phrasing**: "Note that...", "It's worth noting...", "This ensures that...", "Make sure to...", "Let's...". **Rewrite only — never delete**; the sentence underneath is often a real invariant, just phrased badly.

Keep a comment only when it states something a future reader could not get by re-reading the code: a hidden constraint, a non-obvious invariant, a specific library/framework gotcha, a genuine "why," not a "what" or a "when did this change." If the project's own AGENTS.md/CLAUDE.md defines a comment policy, that policy is authoritative over the generic criteria above where the two disagree — check it explicitly, don't assume silence means agreement.

Auto-fixed edits and reported findings both get a line in step 7's synthesis (file:line, what changed or what's proposed) — this is the one step performing edits on prose rather than logic, so the user's only chance to catch a wrong call is seeing it listed.

### 7. Synthesize Findings

**Combine /code-review findings + rule-compliance findings + manual review + comment-removal edits/findings (step 6):**
- Group by severity: Blocking → Important → Suggestions
- Three separate lists from step 6, never merged: Pass A auto-fixed (already applied, shown for visibility/veto), Pass A reported-but-not-yet-applied, and Pass B — the last touches lines this review never wrote, so acting on it widens the diff and is the user's call, not yours
- Remove false positives — verify against actual code before including
- Add context: explain WHY something matters
- Reference file:line for all issues

## Model Selection

**Use Opus** for this workflow (steps 4-7 need staff-level judgment). `/code-review` picks its own model internally.
