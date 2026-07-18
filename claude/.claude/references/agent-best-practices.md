# Agent Best Practices: 15 Universal Patterns

**Source:** Analysis of 109 agent skills across 100s of production migrations
**Evidence:** 83% time reduction, 90% fewer prompts when patterns applied

---

## The Patterns

### Execution Efficiency

#### 1. proactive-error-capture
**Rule:** Capture ALL errors at once, fix in parallel. Never iterate fix-compile-fix-compile.

**Anti-pattern:**
```
compile → 1 error → fix → compile → 1 error → fix → compile ... (20-30 cycles)
```

**Correct pattern:**
```
compile once → read ALL output → categorize all errors → fix all in one pass → verify once
```

#### 2. parallel-execution
**Rule:** Identify independent operations and run them simultaneously. Never sequence when parallel is possible.

**Anti-pattern:** Read file A → Read file B → Read file C (sequential reads)
**Correct:** Read files A, B, C in one parallel batch

#### 3. proactive-fixes
**Rule:** When fixing errors, fix BOTH main code and test code in the same pass. Apply known formatting fixes before pushing.

---

### Knowledge Management

#### 4. evidence-based-references
**Rule:** Cache verified knowledge in reference files. Don't make agents rediscover what someone already paid to learn.

**ROI:** 87x-174x time savings vs. re-discovering
**In this config:** `~/.claude/references/`, `~/.claude/kb/`

#### 5. code-first-analysis
**Rule:** Read actual code/config before forming conclusions. Never assume structure.

**In this config:** AGENTS.md "Never guess - always look up"

#### 6. exhaustive-scanning
**Rule:** Scan until saturation. After making changes, re-scan with original pattern to verify zero remaining occurrences.

#### 7. exhaustive-mining
**Rule:** Mine ALL candidates → validate → filter → report. Don't stop at the first few examples.

---

### Workflow Optimization

#### 8. prerequisites-first (Step 0)
**Rule:** Validate blockers before starting work. 30 seconds now prevents 30 minutes of wasted context.

**Checklist:**
- Right repo/branch/ticket?
- Environment correct?
- Git state clean?

#### 9. tier-confirmation
**Rule:** Confirm the target BEFORE expensive context gathering. Ask first, gather later.

#### 10. dry-run-mode
**Rule:** Preview what changes would be made before executing bulk operations.

#### 11. session-management
**Rule:** Support multi-day workflows with persistent state. Don't lose context between sessions.

**In this config:** `~/.claude/sessions/`, KB, memory system

#### 12. smart-routing
**Rule:** Auto-detect user intent from natural language and route to the right skill/workflow.

**In this config:** AGENTS.md skills table, Red Flags section

#### 13. explicit-validation
**Rule:** Provide a testable success criteria checklist. Don't claim "done" without checking all criteria.

---

### Meta

#### 14. agent-error-guidance
**Rule:** Document systematic agent mistakes INSIDE the skill. Tell agents what NOT to do explicitly.

#### 15. infrastructure-bootstrap
**Rule:** Skills bootstrap full context automatically. Don't make the user set up prerequisites manually.

---

## Pattern Compound Effect

| Patterns Applied | Speed Improvement |
|-----------------|-------------------|
| 1-2 patterns    | 2x faster         |
| 3 patterns      | 3x faster         |
| 8+ patterns     | 4-5x faster       |

---

## Quick Violation Detection

| Signal | Pattern Violated |
|--------|-----------------|
| Multiple build runs with single-file edits between them | proactive-error-capture |
| Sequential Read calls that could be parallel | parallel-execution |
| Test failures discovered after "fixing" compilation errors | proactive-fixes |
| Wrong repo/branch discovered mid-session | tier-confirmation / prerequisites-first |
| Refactor completed but old pattern still in codebase | exhaustive-scanning |
| 30+ minutes spent on context before confirming target | tier-confirmation |
| Bulk change without showing user what would change | dry-run-mode |
| Claiming done without running success criteria checklist | explicit-validation |
| Same mistake the skill explicitly warns against | agent-error-guidance |
