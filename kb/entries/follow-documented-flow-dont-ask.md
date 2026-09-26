---
name: follow-documented-flow-dont-ask
description: When a documented workflow already covers the next step (commit/push to a feature branch, stopping a server I started, self-review), do it — don't stop to ask permission for steps the flow authorises.
type: feedback
tags: [workflow, git, commits, autonomy, permissions]
status: active
date: 2026-09-25
---

When the work is verified and the next steps are ones a documented flow already authorises —
committing and pushing to a feature branch (global AGENTS.md Permissions), the conventional-commits
and self-review skills, cleaning up a server I started — carry them out instead of ending the turn
with "should I commit? should I stop the server?".

**Why:** User (2026-09-25), after I finished a verified change and asked whether to commit and stop
the local server: "you have a documented flow do you need to ask me?". Asking for steps that are
already written down as allowed costs a round trip and signals I didn't read the flow.

**How to apply:**
- First find the flow: `search-kb.sh --type feedback` at the start of a feature, not after. A
  project-specific process entry outranks the
  generic global Permissions line and fixes the order.
- Then run its steps without asking, in its order. Generic default where no project flow exists:
  commit (conventional-commits skill), self-review, then push the feature branch. Where the project
  flow says "don't push before live test and self-review", that order binds.
- Still ask for what the flow reserves to the user: opening a PR, anything on main/shared branches,
  external posts, destructive/irreversible actions, spending money (billed calls), touching a shared
  stack another session may be using.
- A project-level "never commit without explicit ask" line doesn't override this once the user has
  said to follow the flow; the explicit correction wins.

## Related

- [[never-commit-to-main]]
- [[surface-review-gaps-before-merge]]
