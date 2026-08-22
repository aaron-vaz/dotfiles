#!/bin/bash
set +e

# Tool input arrives as JSON on stdin. CLAUDE_BASH_COMMAND is a stale contract
# from an older Claude Code version and is no longer set — verified 2026-08-22 by
# dumping the live hook environment: only CLAUDE_PROJECT_DIR, CLAUDE_PID,
# CLAUDE_CODE_SESSION_ID, CLAUDE_EFFORT and friends exist. Kept as a fallback in
# case that ever changes back. See tests/hook-stdin-contract-mechanical.sh.
CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null)"
CMD="${CMD:-${CLAUDE_BASH_COMMAND:-}}"

# Check for cd && git pattern
if echo "$CMD" | grep -qE 'cd [^;]+(;|&&)[^;]*git'; then
  echo ""
  echo "⚠️  Git Usage Pattern Detected"
  echo ""
  echo "Found: cd <path> && git <command>"
  echo "Better: git -C <path> <command>"
  echo ""
  echo "Benefits: No shell state changes, more composable, cleaner for sequential operations"
  echo "Reference: ~/.claude/rules/git.md (auto-loaded)"
  echo ""
fi

exit 0
