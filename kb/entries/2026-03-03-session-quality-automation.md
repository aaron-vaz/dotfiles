---
title: "Session Quality Automation System"
date: 2026-03-03
project: claude-misc
tags: ["architecture", "automation", "quality-system", "agents", "session-management"]
status: active
promoted_to: ""
outcome: "Built team-based autonomous quality check system with correct code review timing"
expires: 2026-06-04
---

## Context

Extended session management from manual end-session workflow to automatic retrospective quality checks using Claude Code's team/agent system. Also corrected a design flaw where code review was placed in retrospective (too late).

## Key Decisions

### Decision 1: Team-based Agent on Startup
**Rationale:** Background tasks can't interact with users; team agents can message and wait for responses.

**Approach:**
- Startup hook instructs Claude to spawn end-session-agent teammate
- Agent loads previous session data + conversation summary
- Agent scans for uncommitted changes, evaluates checks needed
- Agent messages user with findings (interactive)
- User approves/skips, agent executes and shuts down

**Tradeoffs:**
- (+) Interactive, full context, non-blocking, autonomous
- (-) ~5-10s startup overhead, uses tokens every session

### Decision 2: Code Review Timing Fix
**Problem:** Original design had code review in retrospective agent (next session) - too late if already committed.

**Corrected timing:**
- **During session (before commit):** Pre-commit hook warns on substantial changes (>50 lines), suggests code-reviewer agent
- **On-demand (anytime):** Manual code-reviewer invocation
- **NOT next session:** Retrospective agent only handles archival/learning

### Decision 3: Conversation Summary Capture
**Approach:** PostToolUse hook appends significant events to daily summary file.
**Purpose:** Gives end-session-agent context about what happened in previous session.

## Knowledge Flow Architecture

```
Session work -> Sessions/current.md
              | (on startup)
Session-archiver scans -> Archives to conversations/
              |
Learning-analyzer scans -> Updates skills/CLAUDE.md
              |
Memory system captures -> Project-specific patterns
              |
Cross-project detection -> Promotes to global CLAUDE.md
```

## Files Created/Modified

- ~/.claude/skills/end-session-agent/SKILL.md (new)
- ~/.claude/skills/session-archiver/SKILL.md (new)
- ~/.claude/scripts/search-memories.sh (new)
- ~/.claude/session-init.sh (modified - background task instructions)
- ~/.claude/skills/end-session/SKILL.md (modified - git repo check)
- ~/.claude/references/shell.md (modified - Python/pyenv, macOS commands)

## Related
- Session: ~/.claude/sessions/2026-03-03.md
- Related archive: 2026-03-03-tagged-memory-system.md (same session, memory system design)
- Auto-archived by end-session-agent
