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

### 5. Manual Architecture Review

Review for architecture, edge cases, performance, maintainability, and security beyond what tooling caught.

### 6. Synthesize Findings

**Combine /code-review findings + rule-compliance findings + manual review:**
- Group by severity: Blocking → Important → Suggestions
- Remove false positives — verify against actual code before including
- Add context: explain WHY something matters
- Reference file:line for all issues

## Model Selection

**Use Opus** for this workflow (steps 4-6 need staff-level judgment). `/code-review` picks its own model internally.
