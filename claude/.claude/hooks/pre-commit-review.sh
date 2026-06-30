#!/usr/bin/env bash
# Suggests code review before committing substantial changes

set -euo pipefail

# Only run if git commit command detected
if ! echo "$CLAUDE_BASH_COMMAND" | grep -q "git commit"; then
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

💡 RECOMMENDATION: Run code review before committing

To review:
  1. Use Agent tool with subagent_type: "pr-review-toolkit:code-reviewer"
  2. Or invoke: Read ~/.claude/skills/pre-commit-reviewer/SKILL.md

To skip review and commit anyway:
  - Continue with commit (review can happen later)

EOF

  # Non-blocking advisory (don't prevent commit)
  exit 0
fi

# Below threshold, allow commit silently
exit 0
