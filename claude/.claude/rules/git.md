# Git Rules

## Plain `git` vs `git -C`

- **CWD is repo** → use plain `git status`, `git add`, `git commit`
- **CWD elsewhere** → use `git -C <path> status`, `git -C <path> add`
- **Never** use `git -C` when already in target repo — unnecessary noise

## Commit Format

```bash
git commit -m "$(cat <<'EOF'
feat: add new feature

Description of changes.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

## Worktrees — Check Whenever a Branch Is Mentioned

Trigger: any mention of a branch name, "our branch", "the feature branch", diff/review requests ("what did we change", "show me the diff"), or "continue work on X" — not diff-review alone.

1. Run `git worktree list` first
2. If worktrees exist, identify which one holds the named/feature branch (branch name is the clue)
3. Operate (diff/read/edit/commit) from that worktree — NOT the main working tree

Reason: most worktree workflows exist precisely because the branch isn't checked out in the main tree — operating on the main repo when the branch lives in a worktree returns wrong/empty results or edits the wrong checkout.

## Anti-Patterns

- **No `cd` chaining** — use `git -C <path>` or subshell `(cd path && git ...)`
- **No `git -C` in repo** — plain `git` cleaner
- **Always check status/diff before commit**
- **Never act on a branch without first checking `git worktree list`** — feature work is almost always in a worktree