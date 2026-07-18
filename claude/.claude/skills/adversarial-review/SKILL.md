---
name: adversarial-review
description: Cross-model adversarial review at 3 gates — investigation, plan, architecture. Delegates to a different model to find blind spots. Advisory only — presents findings, never blocks autonomously.
---

# Adversarial Review

## Purpose

Uses a different model than the one doing the work to find blind spots before committing to implementation. Different models have different failure modes — a second perspective catches what the primary model misses.

## Gates

| Gate | Artifact | When |
|------|----------|------|
| 1 — Investigation | Root cause + fix proposal | Before writing fix |
| 2 — Plan | Implementation plan | Before first code |
| 3 — Architecture | Design doc / tech discovery | Before implementation |

**Default:** Gate 2 runs automatically after every non-trivial plan (multi-file changes, new abstractions, data migrations). Skip for trivial single-file edits. Gates 1 and 3 are on-demand.

## How to Invoke

### Step 1 — Build content string

**Gate 1:**
```
PROBLEM: <what broke and observed symptoms>
ROOT CAUSE: <concluded root cause>
EVIDENCE: <queries run, logs seen, code inspected>
FIX: <proposed fix>
```

**Gate 2:**
```
GOAL: <one sentence on what this change accomplishes>
KEY DECISIONS: <significant choices made and why>
STEPS: <ordered implementation steps>
FILES CHANGED: <files/modules affected>
RISKS NOTED: <risks already identified>
```

**Gate 3:**
```
PROBLEM: <what this design is solving>
SOLUTION: <proposed approach>
KEY DECISIONS: <choices made and why alternatives rejected>
FILES CHANGED: <what's being touched>
RISKS NOTED: <risks already identified>
OPEN QUESTIONS: <still unsure about>
```

### Step 2 — Delegate to a different model

Use the Agent tool with a different model than the one doing the primary work:

```
Agent(
  description: "Adversarial review — Gate N",
  prompt: "You are an adversarial reviewer. Your job is to find what's wrong with this artifact. Be specific, be harsh, be constructive.

  <artifact>
  [content string from Step 1]
  </artifact>

  Find:
  1. Assumptions that might be wrong
  2. Edge cases not handled
  3. Missing considerations
  4. Risks not identified
  5. Simpler alternatives that were overlooked

  For each finding, rate confidence (high/medium/low) and explain your reasoning.",
  model: <different model than primary>
)
```

**Model selection guidance:**
- If primary work is on `qwen3.7-plus` (sonnet) → use `deepseek-v4-pro` (opus) or `kimi-k2.7-code` (fable) for review — different architecture catches different blind spots
- If primary work is on `kimi-k2.7-code` (fable) → use `deepseek-v4-pro` (opus) for review — different reasoning style
- If primary work is on `deepseek-v4-pro` (opus) → use `kimi-k2.7-code` (fable) for review — coding-specialized perspective
- If primary work is on `mimo-v2.5` (haiku) → use `qwen3.7-plus` (sonnet) or `kimi-k2.7-code` (fable) for deeper analysis
- The key is **different model**, not necessarily bigger model — different architectures have different failure modes

### Step 3 — Independent assessment first, then compare

**Before reading adversarial findings**, write out your own assessment:
- What are the main risks?
- What assumptions might be wrong?
- What's missing?

Lock this assessment, then read the adversarial findings. For each finding, label it:
- **Accepted**: finding is valid, you agree
- **Rejected**: finding is incorrect or already addressed — explain why
- **Uncertain**: can't verify without more context — flag for user

Present both your independent assessment and the categorised adversarial findings to the user. Never adopt adversarial findings wholesale without evaluating them first.

Advisory only — never halt work autonomously. Present findings and let the user decide.

### Step 4 — Fail-open

| Outcome | Action |
|---------|--------|
| Review succeeds, findings present | Present findings |
| Review succeeds, findings empty | Note "Gate N passed — no issues found" |
| Review errors / model unavailable | Note "Gate N skipped — model unavailable", continue |

## Integration with Existing Skills

| Skill | Invoke after | Gate |
|-------|--------------|------|
| `investigation-intake` | Root cause confirmed | Gate 1 |
| Plan writing | Plan reviewed by user | Gate 2 |
| `tech-discovery` | Discovery doc drafted | Gate 3 |
