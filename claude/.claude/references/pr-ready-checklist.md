# PR Ready Checklist

Use before marking any PR ready for team review.

## Checklist

Work through these in order. Don't mark ready until all are green.

1. **Build passes** — run full build (`mvn verify` / `./gradlew build`), not just tests. CI runs linting and formatting too.

2. **Code review done** — either `self-review` skill or reviewer agent. Fix all Critical and Important findings before proceeding.

3. **Inline diff comments posted** — add review comments on non-obvious design decisions, tradeoffs, or anything a reviewer would question. Key targets: opt-in flags, env-specific behavior, schema assumptions, known limitations.

4. **PR description accurate** — reflects current branch state, not an earlier iteration. Includes: what changed, why, key design decisions, how to verify.

5. **Perf/staging verified** — depends on the repo:
   - Repos with good integration tests: CI green is sufficient, ask if unsure
   - Repos requiring manual verification (e.g. batch/data pipelines): run in a pre-production environment, check output against production, spot-check key instances — CI does not cover this
   - **Don't assume CI covers it** — confirm with the user which category the repo falls into

6. **Follow-up items noted** — anything out of scope goes in a separate ticket/issue, not as a TODO in the code. Note them in the PR description or a comment.

7. **Mark ready** — `gh pr ready <number> --repo <repo>`

## When to invoke

Before marking any PR out of draft or requesting team review.

## Notes

- Never add this checklist to the PR description — it's author-only
- For inline comments (#3): comment where a reviewer would ask "why?" — not what the code does, but why it does it that way. One sentence is enough. Don't comment on obvious code.
