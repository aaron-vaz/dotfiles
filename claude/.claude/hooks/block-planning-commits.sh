#!/bin/bash
set +e

# Tool input arrives as JSON on stdin — see validate-git-usage.sh for the
# contract note. CLAUDE_BASH_COMMAND kept only as a fallback.
PAYLOAD="$(cat 2>/dev/null)"
CMD="$(echo "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null)"
CMD="${CMD:-${CLAUDE_BASH_COMMAND:-}}"

# Check if command contains git commit
if ! echo "$CMD" | grep -q "git commit"; then
  exit 0
fi

# Work out which repo the commit targets. Hooks run in the *session's* cwd, which
# is not necessarily where the command runs — `cd X && git commit` and `git -C X
# commit` both retarget it, and a bare `.` would read the wrong index and silently
# find nothing (verified 2026-08-22). Precedence: git -C, then cd, then the
# payload's own cwd, then $PWD.
PAYLOAD_CWD="$(echo "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)"
REPO_PATH="${PAYLOAD_CWD:-$PWD}"
if echo "$CMD" | grep -q "git -C"; then
  REPO_PATH=$(echo "$CMD" | sed -n 's/.*git -C \([^ ]*\).*/\1/p')
elif echo "$CMD" | grep -qE '(^|;|&&)[[:space:]]*cd[[:space:]]'; then
  REPO_PATH=$(echo "$CMD" | sed -n 's/.*[[:space:]]*cd[[:space:]]\{1,\}\([^ ;&|]*\).*/\1/p' | head -1)
fi
REPO_PATH="${REPO_PATH/#\~/$HOME}"
[[ -d "$REPO_PATH" ]] || REPO_PATH="${PAYLOAD_CWD:-$PWD}"

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
