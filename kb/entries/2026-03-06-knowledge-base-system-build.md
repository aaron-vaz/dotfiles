---
title: "Knowledge Base System Design and Build"
date: 2026-03-06
project: claude-misc
tags: [architecture, knowledge-base, knowledge-management, search, shell-scripts, subagent-driven-development]
status: active
promoted_to: ""
outcome: "Replaced passive conversations/ archive with curated kb/ system: YAML frontmatter, TSV index, search-kb.sh, audit-kb.sh, SessionStart hook, 90-day lifecycle"
expires: 2026-06-04
---

## Context

The conversations/ archive was passive storage — files went in and were never read. The user wanted an active knowledge base with search, lifecycle management, and zero context overhead unless relevant content found.

## Key Decisions

- **Flat entries/ dir over topic subdirs**: Tags handle categorization; forcing a single category on cross-cutting entries creates friction.
- **TSV index over full YAML parse on every search**: Index rebuilds automatically when any entry is newer than it. Fast grep over TSV vs parsing 50+ YAML files.
- **Shell scripts only**: No external dependencies. Works within Claude Code hook system.
- **SessionStart hook pattern**: `search-kb.sh --project $(basename $PWD)` + pipe to `{ read -r line && echo header && ...; } || true` — header only appears when matches exist, fully silent otherwise.
- **90-day expires default**: Forces periodic review. Foundational entries use `expires: 2099-01-01`.
- **Subagent-driven execution**: 8 tasks dispatched as independent subagents. Tasks 5/6 were blocked by cross-directory Bash permissions — had to commit manually in main session.

## Outcome

`~/.claude/kb/` with 8 migrated entries, search-kb.sh (tag/project/keyword/full-text), audit-kb.sh (--dry-run/--apply), SessionStart hook, end-session skill updated, docs updated in CLAUDE.md and memory-system.md. Old conversations/ removed.

## Lessons Learned

- Subagents dispatched from project CWD get blocked on `cd ~/.claude && git commit` — plan for manual commit step or use `git -C` cross-directory pattern.
- SessionStart hook output becomes a system reminder — keep it to 5 lines max.
- Migration scripts are one-time tools: write, run, delete in same PR/session.
- kb/index.tsv should be gitignored (auto-generated cache).

## Related

- KB entry: 2026-03-06-memory-archive-system-audit.md (the audit that led to this)
- Updated: ~/.claude/skills/end-session/SKILL.md, end-session-agent/SKILL.md, session-archiver/SKILL.md
- Updated: ~/.claude/references/memory-system.md, CLAUDE.md
