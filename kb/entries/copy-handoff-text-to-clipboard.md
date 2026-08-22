---
name: copy-handoff-text-to-clipboard
description: When user asks for a prompt/handoff text (e.g. "create me a prompt for X"), pbcopy it in addition to writing/showing it — don't wait to be asked
type: feedback
tags: [workflow, clipboard, handoff]
status: active
---

When the user asks for standalone text meant to be pasted elsewhere — a handoff prompt for a new context, a message draft, anything of that shape — always copy it to the clipboard (`pbcopy` on macOS) as part of delivering it, not just write it to a file or print it in chat.

**Why:** User corrected this after asking for an investigation handoff prompt and getting only a file path back — the whole point of that kind of text is to paste it somewhere immediately.

**How to apply:** Any time a request is for "a prompt for X", "text I can paste", "a message for Y" — after producing the content, pipe it to `pbcopy` (or write to a temp file and `cat file | pbcopy`) without being asked. Still fine to also save it to a file/KB entry if it's worth persisting. Not for content that's clearly staying in-repo (commit messages go through the normal git flow) or for anything the user explicitly asks to only display.
