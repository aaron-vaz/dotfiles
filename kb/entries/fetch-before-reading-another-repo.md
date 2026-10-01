---
name: fetch-before-reading-another-repo
description: Before reading or delegating a read of any repo other than the one being worked in, `git fetch` it and compare against origin — never analyse a local checkout as-is; read origin's default branch (detached worktree if the checkout is behind).
type: feedback
tags: [git, investigation, subagents, multi-repo, stale-checkout]
status: active
date: 2026-09-25
---

Before reading another repo (or sending a subagent to read it), run `git -C <repo> fetch origin` and
`git -C <repo> log --oneline HEAD..origin/<default>`. If the checkout is behind, read origin's state —
e.g. `git worktree add --detach <scratchpad>/<name> origin/<default>` — and point agents at that path
explicitly, telling them not to read the stale checkout.

**Why:** Aaron, 2026-09-25 ("did you pull latest?" / "dont just read a repo check if there are updates").
I sent an agent to walk a mobile app's proposal flow on the local `main`; it was 7 PRs behind origin
and reported the whole flow as unbuilt when it had shipped. A stale checkout produces confident, wrong
conclusions, and the user has to catch it.

**How to apply:** Any cross-repo read — app walkthroughs, shared-client checks, "how does X do it" —
starts with fetch + behind-count. State the commit read in the report. Don't pull/reset the user's
checkout to do this (it may have local work); use a detached worktree in the scratchpad and remove it
afterwards.
