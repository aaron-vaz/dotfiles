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

## Worktrees — Check Before Diffing

When asked to review/diff changes ("what did we change", "show me the diff", "fix the finals in our changes"):
1. Run `git worktree list` first
2. If worktrees exist, identify which one holds the feature work (branch name is the clue)
3. Diff/read from that worktree — NOT the main working tree

Diffing the main repo when feature work lives in a worktree returns wrong/empty results.

## Anti-Patterns

- **No `cd` chaining** — use `git -C <path>` or subshell `(cd path && git ...)`
- **No `git -C` in repo** — plain `git` cleaner
- **Always check status/diff before commit**
- **Never diff main repo without first checking `git worktree list`** — feature work is almost always in a worktree