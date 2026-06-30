#!/bin/bash
set +e

# Check for cd && git pattern
if echo "$CLAUDE_BASH_COMMAND" | grep -qE 'cd [^;]+(;|&&)[^;]*git'; then
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
