---
name: follow-documented-flow-dont-ask
description: When a documented workflow already covers the next step (commit and push to a feature branch, stop a server you started, self-review), do it. Do not stop to ask permission for steps the flow authorises.
type: feedback
tags: [workflow, git, commits, autonomy, permissions]
status: active
---

When the work is verified and the next steps are ones a documented flow already authorises, carry them out instead of ending the turn with "should I commit? should I stop the server?". Examples are committing and pushing to a feature branch (per the global permissions section), running the documented commit and review workflow, and cleaning up a server you started.

**Why:** The user corrected this after a verified change ended with a question about committing and stopping the local server: "you have a documented flow do you need to ask me?". Asking about steps that are already written down as allowed costs a round trip and signals the flow was not read.

**How to apply:**
- First find the flow. Search the knowledge base for feedback entries at the start of a feature, not after. A project-specific process entry outranks the generic global permissions line and fixes the order.
- Then run its steps without asking, in its order. Where no project flow exists, the generic default is: commit with a conventional message, self-review, then push the feature branch. Where the project flow says "do not push before live test and self-review", that order binds.
- Still ask for what the flow reserves to the user: opening a PR, anything on main or shared branches, external posts, destructive or irreversible actions, spending money (billed calls), and touching a shared stack another session may be using.
- A project-level "never commit without explicit ask" line does not override this once the user has said to follow the flow. The explicit correction wins.

## Related

- [[never-commit-to-main]]
- [[surface-review-gaps-before-merge]]
