# Skill Authoring Patterns

**Source:** Analysis of 109 skills, hundreds of production migrations.

---

## The 15 Universal Patterns

### Execution Efficiency

| Pattern | What it means | How to implement in a skill |
|---------|--------------|---------------------------|
| **proactive-error-capture** | Capture ALL errors at once, fix in parallel — not one-by-one iteratively | Collect all issues first, then report/fix in one pass. Add `AGENT MISTAKE: Fixing errors one at a time` |
| **parallel-execution** | Identify concurrent operations, run simultaneously | Call out which steps are independent. "Steps A and B can run in parallel." |
| **proactive-fixes** | Apply known failure patterns BEFORE they occur | Document known pitfalls with explicit "apply this fix preemptively" instructions |
| **proactive-validation** | Run validation locally BEFORE pushing or proceeding | Always have a Step 0 that validates environment, tools, and preconditions |

### Knowledge Management

| Pattern | What it means | How to implement in a skill |
|---------|--------------|---------------------------|
| **evidence-based-references** | Cache verified knowledge in reference files | Extract known-good mappings, patterns, and fixes into separate `.md` files; reference from SKILL.md |
| **code-first-analysis** | Read actual code/config — never assume structure | Add: "Do NOT assume the integration follows standard patterns — read the actual file" |
| **prerequisites-first** | Validate blockers before starting work | Always have a Prerequisites or Step 0 section that stops if requirements aren't met |
| **explicit-validation** | Provide testable "done" checklist | End the skill with a completion checklist |

### Workflow Optimization

| Pattern | What it means | How to implement in a skill |
|---------|--------------|---------------------------|
| **tier-confirmation** | Confirm the target BEFORE expensive context gathering | Add: "Before proceeding, confirm [target/ticket/PR] with the user" |
| **smart-routing** | Auto-detect user intent from natural language | Add conditional branching: "If X, follow section Y; if Z, follow section W" |
| **session-management** | Support multi-day workflows with persistent state | Use a tracker file (gitignored) that records step completion — skill resumes from last done step |
| **dry-run-mode** | Preview changes before execution | "Show a draft and wait for explicit approval before posting/submitting" |

### Meta-Level

| Pattern | What it means | How to implement in a skill |
|---------|--------------|---------------------------|
| **agent-error-guidance** | Document systematic agent mistakes explicitly | Add `AGENT MISTAKE:` sections for each predictable failure mode |
| **exhaustive-scanning** | Scan until saturation — check ALL instances, not just the first | Add: "Check ALL call sites, not just the one in the PR" |
| **exhaustive-mining** | Mine ALL → validate → filter → report | Don't just check examples; fetch the full set, validate each, then filter to what matters |

---

## Most Commonly Missing Patterns

1. **parallel-execution** — Steps that are independent are presented sequentially.
2. **agent-error-guidance** — Skills document *domain pitfalls* but not *agent mistakes*. These are different.
3. **explicit-validation** — No skill has a testable "done" checklist at the end.
4. **tier-confirmation** — Skills jump into work without confirming the correct target.

---

## Agent Error Guidance Format

The most impactful pattern. Agents make the same predictable mistakes unless explicitly told not to.

```markdown
## Agent Mistakes to Avoid

AGENT MISTAKE: Do NOT fix issues one at a time. Collect ALL issues first,
then report them in a single comment.

AGENT MISTAKE: Do NOT skip step X because the ticket says it's done. Always verify independently.

AGENT MISTAKE: Do NOT assume [X]. Always read [file/PR/config] first.
```

---

## Completion Checklist Pattern

Every skill should end with a testable checklist:

```markdown
## Completion Checklist

- [ ] All required steps are `done` or `n/a` in the tracker
- [ ] [Specific deliverable 1] is confirmed
- [ ] [Specific deliverable 2] is linked
- [ ] Status updated appropriately
```

---

## Token Efficiency

- SKILL.md body: **keep under 500 lines**
- Description field: **"Use when..."** — triggers only, no workflow summary
- Heavy reference: **separate files**, linked one level deep from SKILL.md
- Don't explain what the model already knows

## Description Field Rules

```yaml
# BAD — leads with workflow summary
description: End-to-end workflow for X. Covers steps A, B, C.

# GOOD — leads with trigger
description: Use when [specific situation]. Covers [what, not how].
```
