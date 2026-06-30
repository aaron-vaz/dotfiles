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

### 3. Run Review Agents (Parallel)

Run ALL relevant agents. No shortcuts.

**Always run:**
- `pr-review-toolkit:code-reviewer` - General code quality, CLAUDE.md compliance
- `pr-review-toolkit:silent-failure-hunter` - Error handling, silent failures

**Conditional (based on changes):**
- `pr-review-toolkit:pr-test-analyzer` - If test files changed
- `pr-review-toolkit:comment-analyzer` - If significant comments/docs added
- `pr-review-toolkit:type-design-analyzer` - If new types added (TypeScript/Kotlin)
- `pr-review-toolkit:code-simplifier` - If complex logic (after other reviews pass)

**Language-specific:**
- `kotlin-review` - If Kotlin files changed
- `web-design-guidelines` - If React/Next.js files changed

**Launch agents in parallel:**
```
Use the Task tool with multiple agent invocations in a single message
```

### 4. Manual Architecture Review

While agents run, manually review for architecture, edge cases, performance, maintainability, and security.

### 5. Synthesize Findings

Wait for all agents to complete. Then:

**Combine agent findings + manual review:**
- Group by severity: Blocking → Important → Suggestions
- Remove false positives (agents can be wrong — especially for Kotlin operators and extension properties; verify agent findings against actual code before including)
- Add context: explain WHY something matters
- Reference file:line for all issues

## Model Selection

**Use Opus** for this workflow.

**Agents can use their own models:**
- code-reviewer: sonnet (pattern matching)
- silent-failure-hunter: sonnet (error flow analysis)
- Test-analyzer: sonnet (behavioral coverage)
