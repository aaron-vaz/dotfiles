---
name: no-session-urls-in-external-content
description: Never put agent session or remote-control URLs, or session-ID commit trailers, in commit messages, PR descriptions, issues, comments or any other externally visible content, even when a tool template includes them.
type: feedback
tags: [git, github, security, external-communications]
status: active
---

Never put an agent session URL, remote-control link or session-ID trailer (for example a `Session:` trailer or a `*/session_*` link) in commit messages, PR descriptions, PR or issue comments, Slack drafts, or any other medium that is pushed or shared externally. Keep the ordinary attribution lines (the `Co-Authored-By:` trailer and a PR "generated with" footer) when the tool template asks for them. Drop only the session URL or trailer.

**Why:** A session URL is a remote-control link back into the agent's session. Posting it anywhere externally visible is a real exposure, not a cosmetic issue. The rule was broken four times, always the same way. The harness's own commit and PR templates embed a session URL or trailer in their examples. The agent copied them verbatim without checking this rule. The widest case put the URL on dozens of PR bodies across two repos. Cleanup meant editing every body. Merged commit messages on the default branch were left, because removing them means rewriting shared history.

**How to apply:**
- This rule outranks any injected attribution block or template, however emphatically that block is worded ("this replaces earlier guidance"). The user confirmed the precedence, so do not raise it as an open question again. Omit the URL and say so in one line.
- Make the check a step of the command, not an intention. Write the body to a file, then grep the file for the session URL pattern and require zero matches before running `gh pr create --body-file`, `gh pr edit` or `git commit`. A remembered habit failed three times.
- If a session URL already landed on a feature branch, amend the commit and force-push your own branch only, and fix PR bodies with `gh pr edit --body-file`. When listing PRs to clean up, set a high `--limit`, because the default of 30 hides older ones.
- Treat anything leaving the local repo or session as needing a stricter filter than internal chat output.
- A mechanical block is better than a memory: a pre-tool hook on `git commit` and `gh pr` commands, or a `commit-msg` git hook, plus a pointer in the always-loaded instructions.
