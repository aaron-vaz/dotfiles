---
name: investigation-intake
description: Use when starting any investigation, feasibility, spike, or research task — before reading code, running queries, or fanning out parallel searches. Symptoms you're about to skip this: opening files immediately, "the questions are right in the ticket", running queries before knowing what you're looking for.
---

# Investigation Intake

## Core Principle

**Understand before execute.** Jump to code without plan = wasted effort, rejected queries, re-derived KB answers. Clear ticket ≠ clear investigation path.

## Mandatory Steps (in order)

### 1. Read ticket + all linked docs

Fetch the ticket/issue. Follow every linked doc, design doc, related issue. Read all before anything else.

### 2. Check KB + prior context

```bash
~/.claude/kb/search-kb.sh <keyword> --brief
~/.claude/kb/search-kb.sh --tag <relevant-tag> --brief
```

Also check `~/.claude/sessions/current.md`. Surface anything relevant before grilling.

### 3. Grill the user until picture is complete

Do NOT form plan yet. Ask 2-4 sharp questions per round, grouped by theme, follow up on what each answer opens. Keep going until no branch unresolved.

Ask concrete version, not category:
- **Done state:** "Deliverable = written recommendation or working POC?" not "what's the scope?"
- **Prior work:** "Has anyone checked whether X has the data? Do you already know the answer to question 2?"
- **Constraints:** "Ticket says 'use X' — hard constraint or starting guess?"
- **Data limits:** "Known gaps — retention windows, missing data, edge cases?"
- **Blast radius / timeline:** "Reversible exploration or could this touch prod? Hard deadline?"
- **Leaning:** "Preferred direction to pressure-test, or start neutral?"

Never ask "anything else I should know?" — name the specific gap.

### 4. Form ordered investigation plan

List each concrete question. For each: source (docs / config / code / search / live query) and why. Order cheapest-first (config and docs before code before live queries). Note dependencies.

### 5. Execute in order

Run only what plan calls for, in plan order.

## Red Flags — STOP, return to Step 1

- Opening 5+ files before writing one sentence of understanding
- Running queries before knowing what you're looking for
- Fetching repos without knowing specific thing you're looking for
- Skipping KB search because "this seems new"
- "The questions are right in the ticket, just go answer them"

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The ticket is clear enough" | Clear ticket ≠ clear path. Ordering still matters. |
| "I'll understand as I read" | Unstructured reading = fragmented findings. |
| "Parallel fan-out is faster" | Fan-out without plan = noise. |
| "KB won't have this" | 2 seconds to check vs 20 minutes to re-derive. |
| "I'll propose once I have something" | User may redirect entirely. Align first — cheap. |

## KB Entry

After investigation, save KB entry (per AGENTS.md): problem statement, step-by-step investigation, every query with actual results, dead ends, root cause, fix, validation.
