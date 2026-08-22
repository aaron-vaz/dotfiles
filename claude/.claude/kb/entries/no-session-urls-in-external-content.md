---
name: no-session-urls-in-external-content
description: Never include claude.ai/code/session_* remote-control URLs in commit messages, PR descriptions, issues, or any other externally-visible content
type: feedback
tags: [git, github, security, external-communications]
status: active
---

Never post claude.ai/code/session_* (or any remote-control/session) URL in commit messages, PR descriptions, PR/issue comments, or any other medium that gets pushed or shared externally.

**Why:** User explicitly corrected this after a PR description was drafted with a session URL appended (matching the boilerplate in the git/PR instructions template). A session URL is effectively a remote-control link back into the agent's session — posting it anywhere externally visible is a real exposure, not a cosmetic issue.

**How to apply:** When drafting commit messages or `gh pr create --body`, drop any trailing session-link line even if a template or prior example includes one. Applies to all external-communication surfaces (commits, PRs, issues, Slack drafts) — same spirit as [[external-comms-require-draft-approval]] if that entry exists: treat anything leaving the local repo/session as needing a stricter filter than internal chat output.

**Repeat incident (2026-07-28):** violated again on the same PR — both the commit trailer and the `gh pr create --body` carried `Claude-Session:`/bare session URL, because the harness's own git-commit and PR instructions embed a `Claude-Session: <url>` line in their example templates and I copied it verbatim without cross-checking this rule first. Fix applied: `git commit --amend` + `git push --force-with-lease` on the feature branch, plus `gh pr edit --body` to strip the URL. **Concrete action going forward:** before running any `git commit -m` or `gh pr create --body`/`gh pr edit --body`, grep the drafted text for `claude.ai/code/session_` and strip the line if present — do not trust the harness's own commit-message template to already be correct on this point.

**Repeat incident (2026-08-20):** violated a third time, in the `gh pr create --body-file` payload. Commits were clean (`Co-Authored-By:` only); the session URL rode in on the PR body's footer block copied from the harness's PR-body instructions. The grep step prescribed above was never run — the failure is not knowing the rule, it's that the check is prescribed as a habit rather than executed as a step. **Hardened action:** the grep is part of the command itself, not a preceding intention — write the body to a file, then `grep -c 'claude.ai/code/session' <file>` and require `0` before the `gh` call, or pipe through `grep -v 'claude.ai/code/session'`. Same for `git commit`. Keep the `🤖 Generated with [Claude Code](https://claude.com/claude-code)` attribution line — that is wanted; only the bare session URL beneath it is not.

## Related

- [[git-conventions]]
