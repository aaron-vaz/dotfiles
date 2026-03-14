---
title: "Memory & Archive System Audit and Fix"
date: 2026-03-06
project: claude-misc
tags: ["memory-system", "claude-config", "knowledge-base", "maintenance", "wiremock", "ers"]
status: active
promoted_to: ""
outcome: "Comprehensive audit of ~/.claude knowledge system — 10 issues found and fixed via 4 parallel agents"
expires: 2026-06-04
---

## Context

A full audit was requested of the Claude Code memory and archive system: whether content is accurate, whether files are actually loaded into context, and whether the system would genuinely be used.

## Key Decisions

- **4 parallel agents** dispatched for independent fix domains (reference files, skills index, sessions infrastructure, file relocation) — clean separation, no conflicts
- **Session summary hook documented as broken** rather than removed: env vars `$CLAUDE_TOOL_NAME`/`$CLAUDE_FILE_PATH` not populated in PostToolUse hooks as of 2026-03. Hook kept for future compatibility.
- **egtnl-ui-guidelines.md relocated** to project-specific memory (`~/.claude/projects/-Users-avaz-workspaces-abacus-ui/memory/`) rather than deleted — preserves content, removes from global context overhead
- **Decided NOT to auto-load `current.md`** this session — identified as a gap, proposed two-tier automation (current.md + ARCHIVE_INDEX.md) for future implementation

## Solution / Outcome

**Fixed:**
1. `references/git.md` — resolved conflict with CLAUDE.md on `git -C` usage (plain `git` in repo CWD)
2. `references/shell.md` — added Java 25 / temurin@25.x + project-to-JDK mapping table
3. `references/testing.md` — added "Common CI Pitfalls" section (Gradle cache, WireMock staleness, Spotless constraints)
4. `references/skills-index.md` — added 6 missing skills (end-session-agent, session-archiver, jvm-test-quality, refactor, claude-md-updater, find-skills)
5. `skills/jvm/SKILL.md` — added Java 25 with egtnl-readout-api example
6. `projects/egtnl-readout-api/memory/MEMORY.md` — pruned stale PR #265 block and Legacy Test Fix block
7. `sessions/archive/` — created directory (was documented but never existed)
8. `references/session.md` — removed broken `gsd:pause-work` skill reference
9. `hooks/save-session-summary.sh` — documented broken env vars
10. `references/egtnl-ui-guidelines.md` — relocated to abacus-ui project memory (521 lines removed from global context)
11. `CLAUDE.md` — added archive location reference

## Commands

```bash
# Parallel agent dispatch pattern used
Agent 1: references/git.md, shell.md, testing.md
Agent 2: skills-index.md, jvm/SKILL.md
Agent 3: MEMORY.md, sessions/archive/, session.md, hook documentation
Agent 4: egtnl-ui-guidelines.md relocation
```

## Lessons Learned

- **Skills index gap is a silent failure**: 18 skills existed but weren't indexed — they would never be invoked because Claude can't discover them. Always update skills-index.md when adding a skill.
- **Session summary hooks can't use PostToolUse env vars**: `$CLAUDE_TOOL_NAME` etc. are not populated. Don't rely on them for hook logic.
- **"Documented but never created" is a common drift pattern**: `sessions/archive/`, documented in two reference files, never existed. Reference documentation and actual filesystem can diverge silently.
- **Global references should stay project-agnostic**: 521-line project-specific file in global references added overhead for every session, not just the relevant project.
- **MEMORY.md at 39 lines is healthy**: stale entries were only ~15 lines. The 200-line limit is working as intended.

## Proposed Next Step: Archive Automation

Two-tier system proposed but not yet built:
```
SessionStart hook
├── auto-load ~/.claude/sessions/current.md
└── auto-load ~/.claude/sessions/ARCHIVE_INDEX.md (curated cross-session decisions)

End-session workflow
├── rotate current.md → archive/YYYY-MM-DD-topic.md
├── extract key decisions → append to ARCHIVE_INDEX.md (2-4 bullets)
└── update MEMORY.md with project-specific learnings
```

## Related

- Updated: `~/.claude/references/git.md`, `shell.md`, `testing.md`, `skills-index.md`, `session.md`
- Updated: `~/.claude/skills/jvm/SKILL.md`
- Updated: `~/.claude/projects/-Users-avaz-workspaces-egtnl-readout-api/memory/MEMORY.md`
- Created: `~/.claude/sessions/archive/README.md`
- Relocated: `~/.claude/references/egtnl-ui-guidelines.md` → `~/.claude/projects/-Users-avaz-workspaces-abacus-ui/memory/`
