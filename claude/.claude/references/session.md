# Session Tracking Reference

## Session Context (`~/.claude/sessions/current.md`)

Tracks work within a session for handoff between interactions.

### How It Works
- **Auto-rotates** — After conversation ends, session file moved to archive
- **Auto-loaded** — New session starts with relevant context from `current.md`
- **Handoff mechanism** — When pausing work mid-phase, save context manually to `current.md` (include branch, goal, next steps, blockers)
- **Location** — `~/.claude/sessions/current.md` (active) → `archive/` (completed)

### What to Record

#### Design Decisions
```markdown
## Decision: Choose between X and Y

**Rationale:** Why we chose X
- Pros: (advantages for context)
- Cons: (trade-offs)
- Alternatives rejected:** (Y because...)
```

#### Constraints Discovered
```markdown
## Constraint: API Rate Limiting

Production API limited to 100 req/sec. Batch operations must respect this.
Workaround for tests: mock service in unit tests, use WireMock in integration tests.
```

#### Key File Locations
```markdown
## Important Files
- `/server/src/main/kotlin/REDACTED.kt` — Application entry point
- `/readout/src/main/kotlin/processors/` — Extensible processor pattern
```

#### Corrections Made by User
```markdown
## Correction: Git Command Usage

**User corrected:** Use `git <command>` when in repo CWD, NOT `git -C <path>`
**Why:** Cleaner, respects shell context
**Updated:** CLAUDE.md with this pattern
```

### When to Update Session File
- Completing major architectural decisions
- Discovering production limitations or quirks
- Receiving code review feedback (especially corrections)
- Identifying recurring problems
- Completing a phase (for handoff)

### End-of-Session Cleanup
Use `end-session` skill to:
1. Review changes against original task
2. Run code quality checks (`self-review` skill)
3. Offer to update CLAUDE.md with learnings
4. Archive session context for reference

## Plan Writing

Detailed multi-step plans are written to `.planning/{phase}/PLAN.md`.

### Structure
Plans follow 4-part format:

1. **Overview** — What problem are we solving
2. **Approach** — High-level strategy (3-5 steps)
3. **Task Breakdown** — Detailed per-task actions
4. **Verification** — How we know it's done (goal-backward check)

### Referencing Existing Plans
**Don't duplicate content.** Instead:
- Reference the plan file: "Implementing per PLAN.md steps 1-3"
- Assume reader has access to plan
- Focus response on execution status, not repeating plan details

### Environment Setup in Plans
Plans should document:
- Required environment state (Java version, dependencies)
- Expected tools/skills to use (GSD, debugging, etc.)
- Key assumptions about codebase structure
- Known constraints or workarounds

### Verification Strategy (Goal-Backward)
Before executing plan, verify it will achieve the goal:

1. **Goal:** What does success look like?
2. **Tasks:** What needs to happen?
3. **Verification:** How do we confirm each task succeeded?
4. **Integration:** Do completed tasks chain together end-to-end?

If verification can't confirm goal achievement, revise plan before executing.

## Creating a New Session (Start of Day)

1. **Check for active session**: `cat ~/.claude/sessions/current.md`
2. **If resuming mid-phase**: Use `gsd:resume-work` skill to restore context
3. **If fresh start**:
   - Review project MEMORY.md
   - Check `.planning/` for incomplete phases
   - Decide: continue existing work or start new task
4. **Record initial state**: Branch, goal, blockers in session file

## Session Rotation

- Active session: `~/.claude/sessions/current.md` (updated during conversation)
- Completed sessions: `~/.claude/sessions/archive/{date}-{topic}.md`
- Search archives: `grep -r "keyword" ~/.claude/sessions/archive/`
