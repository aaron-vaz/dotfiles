---
name: delete-completed-plans
description: Do not keep implementation plans in the repo once the work is done and merged. Delete them in a follow-up cleanup; git history keeps them.
type: feedback
tags: [plans, repo-hygiene, docs]
status: active
---

Implementation plan files (for example `docs/plans/*.md`) are scaffolding. Remove each one once its work is finished and merged.

**Why:** The user does not want completed plans kept. A finished plan goes stale against the code. The repo's lasting records are the code, the decisions (`docs/decisions`) and the runbooks. Git history still has the plan if anyone needs it.

**How to apply:**
- When a plan's last task is merged, delete that plan file in a small `chore(docs)` PR. Do not wait to be asked.
- Do not write a plan file that will outlive its work. If one is needed during execution, delete it in the PR that completes the work.
- Specs and decision records are not plans. Keep them unless the user says otherwise.
- Scratch scripts, briefs and logs in the session scratchpad are cleaned up at the end of the work.
