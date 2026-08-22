#!/usr/bin/env bash
# Suggests code review before committing substantial changes

set -euo pipefail

# Tool input arrives as JSON on stdin — see validate-git-usage.sh for the
# contract note. `|| true` on the jq line matters under set -e: malformed or
# empty stdin makes jq exit non-zero, and an unguarded `CMD=$(...)` failure
# kills the script right here (this is exactly how this hook used to crash).
CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null || true)"
CMD="${CMD:-${CLAUDE_BASH_COMMAND:-}}"

# Only run if git commit command detected
if ! echo "$CMD" | grep -q "git commit"; then
  exit 0
fi

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  exit 0
fi

# Check for staged changes
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | wc -l | tr -d ' ')

if [[ "$STAGED_FILES" -eq 0 ]]; then
  # No staged changes, nothing to review
  exit 0
fi

# Count lines changed
LINES_CHANGED=$(git diff --cached --numstat 2>/dev/null | awk '{sum += $1 + $2} END {print sum}')

# Threshold for suggesting review
MIN_LINES=50

if [[ "$LINES_CHANGED" -gt "$MIN_LINES" ]]; then
  cat << EOF

⚠️  SUBSTANTIAL CHANGES DETECTED
────────────────────────────────
Files staged: $STAGED_FILES
Lines changed: $LINES_CHANGED

💡 RECOMMENDATION: Review before committing

  1. /code-review high
  2. self-review skill (staff-engineer pass over your own diff)

To skip review and commit anyway:
  - Continue with commit (review can happen later)

EOF

  # Non-blocking advisory (don't prevent commit)
  exit 0
fi

# Below threshold, allow commit silently
exit 0
