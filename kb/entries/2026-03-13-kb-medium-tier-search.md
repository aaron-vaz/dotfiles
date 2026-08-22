---
title: "KB System: Medium-tier search, non-project hook, ad-hoc search rules"
date: 2026-03-13
project: claude-misc
tags: [knowledge-base, search, hooks, session-start, shell-scripts, openviking]
status: active
promoted_to: ""
outcome: "Added --medium mode to search-kb.sh, fixed SessionStart hook to search all KB entries (not project-scoped), added explicit KB search triggers to CLAUDE.md"
summary: "Investigated OpenViking context DB — useful L0/L1/L2 tiered loading concept, not directly usable (Python/Go/Rust stack, designed for custom agent frameworks). Copied the L1 idea: added summary frontmatter field + --medium output mode to search-kb.sh. Fixed SessionStart hook which was incorrectly scoped to --project basename(PWD) — now searches all active entries with head -20. Added Knowledge Base section to CLAUDE.md with explicit triggers for ad-hoc KB searches (how did we..., why did we..., technology debugging). Key bug: grep returning exit code 1 on empty input kills script under set -euo pipefail — fixed with || true on all frontmatter greps."
expires: 2026-06-11
---

## Context

SessionStart hook was filtering KB entries by `--project "$(basename $PWD)"`, so entries from
other repos (gRPC fix, PR reviews skill update) were invisible when starting a session in a
different directory. Also the hook used `head -5` — too few entries. KB search was documented
as a manual lookup but no explicit triggers existed to prompt ad-hoc searches.

Investigated OpenViking (volcengine) as a potential upgrade — decided against it (heavy stack,
wrong integration model for Claude Code hooks), but borrowed the L0/L1/L2 tiered loading idea.

## Key Decisions

- **Hook scope:** Removed `--project` filter from SessionStart hook — all active KB entries
  are cross-project knowledge; project field is for manual filtering only.
- **head -5 → head -20:** Medium mode output is 2 lines per entry, so 20 lines ≈ 10 entries.
- **L1 via summary field:** Added optional `summary` frontmatter field (2-4 sentences covering
  key decisions + gotchas). Falls back to `outcome` if absent, so old entries keep working.
- **--medium output format:** `date | slug | [tags]\n  summary` — two lines per entry,
  enough context without loading full files.
- **Schema migration:** Index rebuild triggers when column count < 8 (old index had 7 cols).
- **CLAUDE.md KB section:** Added explicit question-shape triggers — "how did we...", "why did
  we...", "what was the decision on..." → search KB before answering.

## Outcome

- `search-kb.sh` has brief/medium/full modes; medium is now the default for SessionStart
- All 13 active KB entries surface at session start across all projects
- Ad-hoc KB search is now a documented requirement in CLAUDE.md, not just an optional tool

## Lessons Learned

- `grep` returning exit code 1 (no match) on empty string input kills scripts under
  `set -euo pipefail` with zero stderr output. Always add `|| true` to grep in frontmatter
  parsers where fields may be absent.
- KB entries without YAML frontmatter (plain markdown headers) return empty string from awk
  frontmatter parser — downstream greps all fail silently under pipefail.
- OpenViking's L0/L1/L2 concept: L0 = always-loaded 1-liners, L1 = on-demand summaries,
  L2 = full content. Maps onto brief/medium/full in search-kb.sh.

## Related

- `~/.claude/kb/search-kb.sh` — updated script
- `~/.claude/settings.json` — SessionStart hook command
- `~/.claude/CLAUDE.md` — new Knowledge Base section
