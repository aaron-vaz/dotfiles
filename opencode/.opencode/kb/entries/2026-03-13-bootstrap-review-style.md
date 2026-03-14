---
date: 2026-03-13
slug: 2026-03-13-bootstrap-review-style
title: Bootstrap Review Style — Reviewer Pattern Analysis
tags: [pr-review, review-style, kotlin, react, domain, architecture, testing, baseline]
summary: One-shot analysis of 576 review comments across 147 PRs to seed pr-reviews/SKILL.md with personal review patterns
---

# Bootstrap Review Style — 2026-03-13

## Scope

- **github.expedia.biz (avaz):** 86 PRs, 228 inline + 24 summary comments, 20 repos
- **github.com (avaz_expedia):** 61 PRs, 301 inline + 23 summary comments, 10 repos
- **Total:** 147 PRs, 576 comments, 30 repos
- **Raw data:** `/tmp/avaz_reviews/results.txt` (GHES), `/tmp/review_comments_output.txt` (GHEC) — temp files, no longer available

## Top Repos by Review Volume

| Repo | Total PRs |
|------|-----------|
| abacus-ui | 25 |
| egtnl-api-orchestrator | 25 |
| egtnl-experiment-metadata-api | 16 |
| experiment-readout-service | 10 |
| egtnl-readout-api | 8 |
| egtnl-experiment-api-server | 7 |

## 13 Patterns Identified and Applied

All 13 patterns were added to `~/.claude/skills/pr-reviews/SKILL.md` under `## Reviewer Patterns`:

1. Hand-rolling logic the framework already provides (Spring/Kotlin stdlib)
2. Domain metric ID and terminology enforcement (EGTnL-specific)
3. Proper layer boundaries and code placement
4. Error logging with sufficient context (stack trace, source)
5. Kotlin idioms: top-level, delegation, coroutines, named params, value classes
6. Test through public API; use JUnit assertions; test constraints
7. Scope containment for temporary/backfill code
8. Avoid duplicate API calls in React (lift to context)
9. Use correct types for domain data (LocalDate, protobuf has, java.time)
10. Spring DI instead of manual creation
11. Data precision belongs in ETL/UI, not source API
12. Defensive locale and timezone handling
13. Questioning scope and necessity (blast radius awareness)

## Files Updated

- `~/.claude/skills/pr-reviews/SKILL.md` — Added `## Reviewer Patterns` section
- `~/.claude/skills/kotlin-review/SKILL.md` — Added 6 new anti-patterns
- `~/workspaces/egtnl-experiment-metadata-api/REVIEW.md` — Created (metric IDs, types, backfill isolation)
- `~/workspaces/egtnl-api-orchestrator/REVIEW.md` — Created (domain terms, Kotlin idioms, protobuf)
- `~/workspaces/abacus-ui/REVIEW.md` — Created (ESLint gate, duplicate calls, declared types)

## Reviewer Profile

avaz reviews at two levels simultaneously: framework (knows what Spring/Kotlin already provides) and domain
(EGTnL metric IDs, data flow ownership, statistical terminology). Style: 1-3 sentence comments, pragmatic
("minor stuff" summaries), approves with comments. Teaches through reviews with architectural reasoning.

Self-taught, 13 years — production scar tissue visible in Node version awareness, locale formatting flags,
and duplicate API call detection.

## Maintenance

`pr-review-learnings` skill handles incremental updates from here. This bootstrap is a one-time baseline.
Next run of bootstrap-review-style is only needed if review activity expands to new repos.
