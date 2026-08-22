---
name: never-force-push-shared-branches
description: Never use git push --force on shared branches (main, master, release/*) — only on feature branches
type: feedback
tags: [domain-rules, git, force-push, shared-branches]
status: active
---

Never run `git push --force` on shared branches (main, master, release/*). Only force-push to your own feature branches.

**Why:** Force-pushing to shared branches rewrites history that other developers have based work on. Causes merge conflicts, lost commits, team-wide rebase nightmares. Incident occurred where force-push to shared branch caused widespread disruption.

**How to apply:**
- About to run `git push --force` **or `--force-with-lease`** → check branch name first
- If branch is `main`, `master`, `release/*`, `develop`, or any branch carrying other contributors' commits → **STOP**, use regular `git push` or rebase interactively instead
- If branch is your own feature branch (e.g., `feature/my-feature`, `fix/bug-123`, personal WIP) → force-push allowed after interactive rebase
- When uncertain whether a branch is shared → ask before forcing

## Related

- [[never-guess-identifiers]]
- [[never-commit-to-main]]

<!--
Consolidated 2026-08-22: absorbed the near-duplicate `no-force-push-shared-branches`,
which stated the same rule under a different slug. Unique content taken from it:
`--force-with-lease` is covered too, and "any branch with other contributors'
commits" as the shared-branch test. Its Related: links pointed at
[[git-worktree-feature-work]] and [[conventional-commits]], neither of which
exists as an entry — dropped rather than carried over as dangling.
-->

