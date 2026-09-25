---
name: dotfiles-repo-commit-straight-to-master
description: aaron-vaz/dotfiles (~/Code/shell/dotfiles) is exempt from no-commit-to-main; commit and push directly to master
type: feedback
tags: [git, dotfiles]
status: active
---

Commit and push directly to `master` in the dotfiles repo. No feature branch or PR needed.

**Why:** Personal single-user config repo; branch/PR overhead adds nothing. User said "that repo can go straight to main".

**How to apply:** In `~/Code/shell/dotfiles` only, skip the never-commit-to-main rule. Stage only files relevant to the task (repo often has unrelated dirty files), commit on `master`, push. Every other repo keeps the rule.

## Related

- [[2026-08-16-never-commit-to-main]]
