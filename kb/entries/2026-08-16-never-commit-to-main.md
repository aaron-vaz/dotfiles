---
name: never-commit-to-main
description: Never commit directly to main/master in project repos — move to a branch/worktree without asking. Personal single-author repos are exempt — config (dotfiles) and homelab infrastructure both commit straight to the default branch.
type: feedback
tags: [domain-rules, git, branches, main, dotfiles, homelab]
status: active
---

Never commit directly to main/master in a **project repo**, including when a session started already checked out on main and the user didn't flag it. Move work to a feature branch (or worktree, per standing convention) proactively — don't ask "should I move this to a branch?" first.

**Exception — personal single-author repos.** The dotfiles repo
(`aaron-vaz/dotfiles`) commits straight to `master`, and the homelab
infrastructure repo commits straight to `main`. There is no review flow, no other
contributor, and no CI gate for a branch to protect; branching there is pure
ceremony. Corrected by the user 2026-08-22 when a branch was created out of habit
mid-task: "not for this repo", and again 2026-09-12 for homelab: "Homeland
changes can go to main". The rule is about protecting shared history under
review, not about branch hygiene as an end in itself — so apply it where a second
person could be affected, and skip it in a repo only you commit to.

The exemption turns on who commits, not on what the repo holds: it covers config
*and* infrastructure-as-code, and it does **not** extend to a product repo just
because you happen to be its only committer this week.

**Why:** During a long session I committed 3 times straight to `main` while investigating a metrics change, because the session started on `main` and I never redirected to a branch. When I flagged it and asked whether to move the commits, the user said: "Yes it should never be on main that's a given, you don't have to ask." The rule is absolute, not situational — starting on main isn't implicit permission to stay there, and asking about an obvious violation is itself unnecessary friction.

**How to apply:** Before the first commit in any session, check the current branch. If on main/master in a project repo, create and switch to a feature branch before committing — do this silently, as expected behavior, not as a question. If a violation already happened (commits landed on main), fix it immediately without waiting for confirmation: `git branch <name> HEAD`, `git checkout main && git reset --hard origin/main`, `git checkout <name>`. Only surface it after the fact as a one-line statement of what was done, not a question.

In a personal repo you are the sole committer of (dotfiles, homelab and the
like), commit to the default branch directly and don't raise it.

**When a global rule and a repo-specific note disagree, ask — don't act on the
looser one.** A session committed homelab work straight to main on the strength
of a line in a project entry saying "no branch needed for this repo", against
this rule as written at the time. The call turned out to be right, but it was a
guess; the question then sat unanswered across two sessions because it was never
put plainly. Surface the conflict in one sentence and get a ruling.

## Related

- [[never-force-push-shared-branches]]
