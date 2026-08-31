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

**Recent commits:**
```bash
git log --oneline -10  # Show last 10 for context
# Ask: "How many commits back to review?"
git diff HEAD~N
```

**Full branch:**
```bash
git diff main...HEAD
```

### 2. Gather Context

**Branch info:**
```bash
git branch --show-current
git log --oneline main..HEAD  # All commits on branch
git diff --stat main...HEAD    # Files changed
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

### 4a. AI Slop / Commentary Comment Removal

Scope: **lines the diff adds** (`+` lines), not comments merely sitting inside a changed hunk — a pre-existing comment that just moved or sits near an edit is not fair game. Get the exact list mechanically rather than skimming:

```bash
git diff <range> -U0 | grep -nE '^\+.*(//|#|/\*|\*|<!--)'
```

Process every line that command returns. Before touching anything, skip these — they are exempt regardless of how they read:

- **Machine-read comments**: `// ktlint-disable`, `@Suppress(...)` justifications, `# noqa`, `// NOSONAR`, `// language=SQL`, `// noinspection`, `<!-- prettier-ignore -->`, license/copyright headers. Deleting these breaks tooling or legal requirements, not just style.
- **`TODO`/`FIXME` carrying a ticket/issue reference** (`// TODO(PROJ-1234): ...`) — many style guides mandate exactly this form; it looks like criterion 2 below but isn't.
- **Mandated doc-comments**: KDoc/Javadoc/docstrings a linter or doc generator requires on public API (`UndocumentedPublicClass`-style rules, Dokka/Sphinx-published surfaces). These get a lighter pass under criterion 3, never outright deletion.
- **Generated or vendored files** (proto stubs, OpenAPI output, lockfiles) — comments there regenerate on the next build; editing them is wasted or gets silently reverted.

For everything else, sort into two bands:

**Auto-fix now** (high-precision, safe to edit directly, no build/lint breakage possible):
- **Narrates the change** rather than stating a fact about the code as it now stands: `// Added X`, `// Now uses Y instead of Z`, `// Changed to support the new flow`, `// Removed the old check`. If a comment only makes sense to someone who watched the diff happen, delete it.
- **Narrates history or a rejected alternative**: `// used to do X`, `// tried Y first but it broke Z`, `// discovered while debugging #123`. That belongs in the commit message or PR description, not permanent source. Delete it.

**Report into step 6 findings, fix after synthesis** (judgment calls, false-positive-prone, or requiring evidence you don't have from the diff alone):
- **Cites a ticket, task number, PR, or a design-doc section that will rot** (`// per task 4.2`, `// see PROJ-1234`, `// as decided in design.md section 8a`), and isn't the mandated-`TODO` form above. Before flagging, check whether ticket references are already common elsewhere in this codebase (`git grep` a sample) — if they are, that's the project's real convention even if AGENTS.md never wrote it down, and this isn't a finding. Where it does apply and the reasoning is genuinely load-bearing, the fix is to inline the reasoning itself, not just delete the pointer.
- **Restates what a well-named identifier already says.** Exempt if it's a mandated doc-comment (see above); otherwise flag for removal.
- **Repeats the same rationale verbatim in more than one file or call site.** Needs a repo-wide check (not just the diff) to find every copy; keep the one closest to the constraint it documents, point the others at it or delete them.
- **Uses LLM hedge/filler phrasing**: "Note that...", "It's worth noting...", "This ensures that...", "Make sure to...", "Let's...". **Rewrite only — never delete**; the sentence underneath is often a real invariant, just phrased badly.

Keep a comment only when it states something a future reader could not get by re-reading the code: a hidden constraint, a non-obvious invariant, a specific library/framework gotcha, a genuine "why," not a "what" or a "when did this change." If the project's own AGENTS.md/CLAUDE.md defines a comment policy, that policy is authoritative over the generic criteria above where the two disagree — check it explicitly, don't assume silence means agreement.

Auto-fixed edits and reported findings both get a line in step 6's synthesis (file:line, what changed or what's proposed) — this is the one step performing edits on prose rather than logic, so the user's only chance to catch a wrong call is seeing it listed.

### 5. Manual Architecture Review

Review for architecture, edge cases, performance, maintainability, and security beyond what tooling caught.

### 6. Synthesize Findings

**Combine /code-review findings + rule-compliance findings + comment-removal edits/findings (4a) + manual review:**
- Group by severity: Blocking → Important → Suggestions
- List 4a's auto-fixed comments separately (already applied, shown for visibility/veto) from its reported-but-not-yet-applied findings
- Remove false positives — verify against actual code before including
- Add context: explain WHY something matters
- Reference file:line for all issues

## Model Selection

**Use Opus** for this workflow (steps 4-6 need staff-level judgment). `/code-review` picks its own model internally.
