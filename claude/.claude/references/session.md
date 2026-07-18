# Session Tracking Reference

## Session Context — KB Entry Per Feature (not a global session file)

Previously used a single global `~/.claude/sessions/current.md` for handoff between interactions.
**Dropped** — a single shared file collides across parallel sessions/worktrees (two
features in flight at once overwrite each other's notes). KB entries are dated + named,
so they're collision-free by construction. One file per feature now serves as both the
working log and the permanent record — no separate handoff file, no duplication to keep in sync.

### How It Works
- **Create immediately** — draft KB entry (`~/.claude/kb/entries/<date>-<slug>.md`)
  as soon as a feature/investigation starts (per AGENTS.md Workflow Checkpoints)
- **Update incrementally** — append findings, decisions, dead ends as they happen, not just
  at the end (guards against losing work to context compaction mid-session)
- **Resuming work** — `~/.claude/kb/search-kb.sh <keyword>` or `--tag <project>`, not a
  session file
- **No rotation needed** — the KB entry already IS the permanent record; nothing to archive

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

### When to Update the KB Entry
- Completing major architectural decisions
- Discovering production limitations or quirks
- Receiving code review feedback (especially corrections)
- Identifying recurring problems
- Completing a phase (for handoff)

### End-of-Session Cleanup
Use `end-session` skill to:
1. Review changes against original task
2. Run code quality checks (`self-review` skill)
3. Finalize the feature's KB entry (outcome, lessons learned) — no separate archive step needed

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
- Required environment state (dependencies, versions)
- Expected tools/skills to use
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

1. **Check for active work**: `~/.claude/kb/search-kb.sh --tag <project>` or by keyword
2. **If resuming mid-phase**: Search KB for the feature, restore context from entry
3. **If fresh start**:
   - Review project MEMORY.md (if exists)
   - Check `.planning/` for incomplete phases
   - Decide: continue existing work or start new task
4. **Record initial state**: Branch, goal, blockers in the feature's KB entry
