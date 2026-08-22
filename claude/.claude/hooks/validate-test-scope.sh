#!/bin/bash
set +e

# Tool input arrives as JSON on stdin — see validate-git-usage.sh for the
# contract note. CLAUDE_BASH_COMMAND kept only as a fallback.
CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null)"
CMD="${CMD:-${CLAUDE_BASH_COMMAND:-}}"

# Check for test commands
if echo "$CMD" | grep -qE '(mvn|./gradlew).*test'; then
  echo ""
  echo "⚠️  Test Execution Checklist"
  echo ""
  echo "Before running tests, verify:"
  echo "  ✓ Running from correct module scope (not root if multi-module)"
  echo "  ✓ Using exact enum casing from production code"
  echo "  ✓ Field types match (string vs int for IDs)"
  echo "  ✓ Loading expected data from JSON fixtures (not calculating)"
  echo ""
  echo "Reference: ~/.claude/rules/testing.md (auto-loaded)"
  echo ""
fi

exit 0
