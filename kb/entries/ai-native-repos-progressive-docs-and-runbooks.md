---
name: "ai-native-repos-progressive-docs-and-runbooks"
description: "Global: every project is AI-native: progressive-disclosure docs and runbooks so an agent can do anything in the repo with minimal human interaction."
type: feedback
tags: [global, docs, runbooks, agents, ai-native, progressive-disclosure, standing-rule]
status: active
---

Aaron's standing rule (2026-11-09, stated as global): all projects should be AI-native. Docs and runbooks use progressive disclosure so an agent has all the knowledge, and the steps to do everything in the repo, with minimal human interaction.

**Why:** he wants agents to run a repo end to end (build, test, change, release, operate, recover) without being walked through it, and without reading everything up front.

**How to apply:**
- Every repo has a short root `AGENTS.md` (commands, hard rules, a routing table "task -> read first") and nothing more; detail lives one hop away: nested `AGENTS.md` per area (owns, invariants, how to test, common changes), architecture overview, decision records (why), and runbooks (how).
- Every repeatable procedure is a runbook with the same template (goal, when to use, preconditions, steps, verify, failure modes and rollback) and a row in the routing table: add a feature of each kind, run the live test, deploy, upgrade, roll back, back up and restore, rotate a secret, diagnose each known failure.
- Docs are true to the code: tests check links resolve, routing rows point at real files, `make` targets named in docs exist, and every package/area is documented. A change that alters behaviour updates its docs in the same commit.
- Decisions and scope live in the repo (decision records), not in private notes. Private notes are for cross-project rules and personal preferences only.
- When starting or touching a repo that lacks this, say what is missing; for a new project scaffold it from the start. `pricewatch` is the reference example.
- Agents must be able to do the work with the repo alone: prefer scripts and make targets over prose-only steps, and name what cannot be automated (needs the owner's secret, phone, or hardware).

