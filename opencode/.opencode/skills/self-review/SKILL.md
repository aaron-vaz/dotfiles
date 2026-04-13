---
name: self-review
description: Use after committing/pushing your own code - acts as staff/principal engineer reviewing your work with direct feedback
model: glm-5
last_reviewed: 2026-04-13
---

# Self-Review Workflow

**IMPORTANT: This skill requires using glm-5 model for staff engineer-level architectural judgment.**

## When to Use
- After committing and pushing code to feature branch
- Before creating PR or requesting team review
- Want staff/principal engineer perspective on your code

## When NOT to Use
- Reviewing team PRs → use `skill(name="pr-reviews")` instead
- Pre-commit checks → just run test suite
- Quick sanity check → just run test suite

## Persona

This review uses your personal persona (blunt, direct, peer-level). Output is for YOU, not the team.

## Review Philosophy

Act as staff/principal engineer on your team:
- Challenge design decisions, not just implementation
- Focus on architecture, maintainability, patterns
- Call out edge cases and technical debt
- Assume competence, challenge choices
- Direct feedback: "This will break when..." not "Consider that this might..."

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

**Read AGENTS.md** for project patterns and conventions.

**Understand intent:**
- What's being built/fixed?
- Why these changes?
- What's the blast radius?

### 3. Run Domain-Specific Skills

Based on the code being reviewed, load relevant skills:

**Language-specific:**
- `kotlin-review` - If Kotlin files changed
- `react-best-practices` - If React/Next.js files changed

**Other useful skills:**
- `jvm-test-quality` - If test files or coverage analysis needed

**Launch skill analysis:**
```
skill(name="kotlin-review")  # or appropriate skill
```

### 4. Manual Architecture Review

While running analysis, manually review for:

#### Architecture & Design Patterns
- Does this fit the existing architecture?
- Are abstractions at the right level?
- Any premature optimization or over-engineering?
- Missing separation of concerns?
- Coupling issues?

#### Edge Cases & Error Handling
- What happens with null/empty/invalid input?
- Race conditions or concurrency issues?
- What breaks under load?
- Missing error boundaries?
- Silent failures hiding problems?

#### Performance & Scalability
- O(n²) hiding in loops?
- Unnecessary database queries?
- Memory leaks (listeners, subscriptions)?
- Blocking I/O on main thread?
- Caching opportunities missed?

#### Maintainability & Tech Debt
- Will this be obvious in 6 months?
- Adding to existing patterns or inventing new ones?
- Tests cover the important behavior?
- Magic numbers or constants need names?
- Comments explain why, not what?

#### Security
- Input validation at boundaries?
- SQL injection, XSS, command injection risks?
- Secrets in code or logs?
- Authorization checks present?
- Sensitive data in error messages?

### 5. Synthesize Findings

Wait for all analysis to complete. Then:

**Combine skill findings + manual review:**
- Group by severity: Blocking → Important → Suggestions
- Remove false positives (analysis can be wrong)
- Add context: explain WHY something matters
- Reference file:line for all issues

**Format:**

```markdown
# Self-Review: [branch-name]

## Scope
[Commits reviewed or "full branch"]

## Critical Issues (Must Fix)
- **[Category]** `file.kt:123` - [Direct description of problem]
  - Why it matters: [Impact/risk]
  - Fix: [Specific recommendation]

## Important Issues (Should Fix)
- **[Category]** `file.kt:456` - [Description]
  - Why: [Reasoning]
  - Alternative: [Suggestion]

## Suggestions (Consider)
- **[Category]** `file.kt:789` - [Description]
  - Tradeoff: [What you gain/lose]

## Strengths
- What's well done (brief, no fluff)

## Architecture Notes
- Design decisions that stood out (good or concerning)
- Patterns that need discussion
- Long-term maintainability concerns

## Next Steps
1. Fix critical issues
2. Address important issues or justify keeping them
3. [If recent commits] Offer: "Want full branch review before PR?"
```

### 6. Present Review

**Use direct, peer-level tone:**
- ✅ "This breaks when X happens"
- ✅ "Why not use Y pattern here?"
- ✅ "This will be unmaintainable in 6 months"
- ❌ "Consider that this might..."
- ❌ "It would be better if..."
- ❌ "Great work on..."

**After presenting:**

If reviewed recent commits:
```
Want full branch review before creating PR?
```

If reviewed full branch:
```
Ready to address issues, or want to discuss any?
```

## Model Selection

**Use glm-5** for this workflow:
- Staff engineer judgment requires deep reasoning
- Architecture decisions need careful analysis
- Tradeoff evaluation is nuanced
- Worth the cost to catch serious issues

## Common Mistakes

**Skipping analysis because "I know my code"**
- Problem: You have blindspots
- Fix: Run skills, every time

**Being too nice (forgetting persona)**
- Problem: Softening feedback defeats the purpose
- Fix: Direct, blunt feedback. Act like a peer who's challenging your decisions.

**Focusing only on skill findings**
- Problem: Skills catch mechanics, miss architecture
- Fix: Manual review is required, not optional

**Not explaining WHY**
- Problem: "Fix this" without reasoning isn't helpful
- Fix: Every issue needs "Why it matters" and impact

**Reviewing too much at once**
- Problem: 50 commits = review fatigue, miss issues
- Fix: Review in chunks (recent commits), then full branch at end

**False positives from analysis**
- Problem: Automated analysis doesn't understand Kotlin operators, extension properties, etc.
- Fix: Verify findings against actual code before including

## Re-read Triggers

- Project conventions: Read `AGENTS.md`
- Kotlin patterns: Load `skill(name="kotlin-review")`
- React patterns: Load `skill(name="react-best-practices")`
- Test patterns: Check project testing conventions

## Example: Recent Commits Review

```bash
# Show last 10 commits
git log --oneline -10

# User selects: "Review last 3 commits"
git diff HEAD~3

# Load relevant skills and run analysis
# Manual review of architecture
# Synthesize and present with direct feedback

# Offer: "Want full branch review before PR?"
```

## Example: Full Branch Review

```bash
# Show all commits on branch
git log --oneline main..HEAD

# Show diff stats
git diff --stat main...HEAD

# Full diff
git diff main...HEAD

# Run skill analysis
# Deep architecture review
# Present findings with next steps
```
