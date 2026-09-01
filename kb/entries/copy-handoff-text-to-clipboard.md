---
name: copy-handoff-text-to-clipboard
description: Any text the user will paste elsewhere gets pbcopy'd as part of delivering it — including a commit message, whenever the user is the one who will run the commit
type: feedback
tags: [workflow, clipboard, handoff, commits]
status: active
---

When the user asks for standalone text meant to be pasted elsewhere — a handoff prompt for a new context, a message draft, a commit message they will run themselves — always copy it to the clipboard (`pbcopy` on macOS) as part of delivering it, not just write it to a file or print it in chat.

**Why:** User corrected this after asking for an investigation handoff prompt and getting only a file path back — the whole point of that kind of text is to paste it somewhere immediately. Corrected a second time over a commit message: *"why i say give me something that i will evenually copy lets cut the middle man and put it in my clipboard"*. The test is **who executes**, not what kind of content it is. A commit message is in-repo content, but the moment the user is the one running `git commit`, it is handoff text and printing it for them to select is a step invented for nothing.

**How to apply:** Any time the deliverable is text the user will move somewhere by hand — "a prompt for X", "text I can paste", "a message for Y", or a commit message in any situation where you cannot run the commit yourself (worktree isolation, permissions, an explicit "I'll do it manually") — pipe it to `pbcopy` without being asked. Say what landed in the clipboard and roughly how long it is. Still fine to also save it to a file if it's worth persisting.

Exempt only when you will run the command yourself in the same turn, or when the user explicitly asks to only display it.

Two mechanics worth not re-deriving:

- **`git commit -m "$(pbpaste)"` is safe** for a message containing backticks, `$`, or quotes — command-substitution output is not re-scanned for expansions. Don't route the user through an editor buffer to dodge a quoting hazard that isn't there.
- `pbpaste | git commit -F -` also works; `-F -` reads stdin.

## Related

- [[2026-08-16-never-commit-to-main]]
- [[no-session-urls-in-external-content]]
