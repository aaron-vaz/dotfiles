#!/bin/bash
set +e

# Check if command contains git commit
if ! echo "$CLAUDE_BASH_COMMAND" | grep -q "git commit"; then
  exit 0
fi

# Extract files from git staging area
REPO_PATH="."
if echo "$CLAUDE_BASH_COMMAND" | grep -q "git -C"; then
  REPO_PATH=$(echo "$CLAUDE_BASH_COMMAND" | sed -n 's/.*git -C \([^ ]*\).*/\1/p')
fi

# Check staged files for planning artifacts
STAGED=$(git -C "$REPO_PATH" diff --cached --name-only 2>/dev/null)

if echo "$STAGED" | grep -qE '(\.claude/|\.planning/|projects/|PLAN\.md|TODO\.md)'; then
  echo ""
  echo "⚠️  WARNING: Planning files detected in commit"
  echo ""
  echo "Staged planning artifacts:"
  echo "$STAGED" | grep -E '(\.claude/|\.planning/|projects/|PLAN\.md|TODO\.md)' | sed 's/^/  - /'
  echo ""
  echo "Planning files should stay local unless explicitly requested by user."
  echo "To proceed anyway, user must explicitly confirm."
  echo ""
fi

exit 0
