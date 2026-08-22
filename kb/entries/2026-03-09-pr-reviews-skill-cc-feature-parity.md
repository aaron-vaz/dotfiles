---
title: "PR Reviews Skill: CC Code Review Feature Parity"
date: 2026-03-09
project: claude-misc
tags: [pr-review, skills, github, graphql, automation, bedrock]
status: active
promoted_to: ""
outcome: "Updated pr-reviews skill with REVIEW.md checks, GraphQL thread resolution, and pre-existing severity to match CC Code Review managed service"
expires: 2026-06-07
---

## Context
CC Code Review managed service is unavailable on Bedrock. Researched what it does and
replicated its key features into the manual pr-reviews skill.

## Key Decisions

- **Step 3.5 — repo guidance files:** Check REVIEW.md + .github/copilot-instructions.md + CLAUDE.md
  from cloned repo before reviewing. `.github/copilot-instructions.md` often has richest standards.
- **Step 6.4 — resolve addressed threads:** Use GraphQL `resolveReviewThread` mutation on re-reviews.
  REST API cannot resolve threads. Filter to only AI threads (body contains "AI-generated review comment").
- **🟣 pre-existing severity:** Bugs not introduced by the PR — worth noting, non-blocking.
  Avoids false blame, changes conversation from "you broke it" to "worth fixing sometime."

## Outcome
All three features committed to `~/.claude/skills/pr-reviews/`. Skill now matches CC Code Review
behavior for Bedrock users.

## Lessons Learned
- GraphQL-only for thread resolution (REST is stateless, thread resolution has cascading UI effects)
- CC Code Review uses 🔴/🟡/🟣 severity — different from skill's 🔴/🟡/💡 (no conflict since
  CC Code Review unavailable on Bedrock)
- `gh webhook forward` handles registration + tunneling for local webhook servers (no ngrok needed)

## Related
- `~/.claude/skills/pr-reviews/SKILL.md`
- `~/.claude/ideas/2026-03-09-local-pr-review-webhook-server.md`
