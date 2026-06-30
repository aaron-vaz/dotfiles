#!/usr/bin/env bash
# Save session summary events for end-session-agent context
#
# NOTE: $CLAUDE_TOOL_NAME, $CLAUDE_FILE_PATH, and $CLAUDE_BASH_COMMAND are not
# populated in PostToolUse hooks as of 2026-03. The case statement below will
# always fall through (empty $CLAUDE_TOOL_NAME), resulting in empty summary files
# with only the header. This hook is intentionally kept for future compatibility
# if Claude Code exposes these env vars in PostToolUse hooks.

set -euo pipefail

SUMMARY_FILE="$HOME/.claude/sessions/$(date +%Y-%m-%d)-summary.md"
TIMESTAMP=$(date +%H:%M)

# Initialize summary file if doesn't exist
if [[ ! -f "$SUMMARY_FILE" ]]; then
  cat > "$SUMMARY_FILE" << EOF
# Session Summary $(date +%Y-%m-%d)

## Events

EOF
fi

# Capture significant events based on tool usage
case "$CLAUDE_TOOL_NAME" in
  "Agent")
    echo "- ${TIMESTAMP}: Spawned agent: ${CLAUDE_DESCRIPTION:-unknown}" >> "$SUMMARY_FILE"
    ;;
  "Write"|"Edit")
    # Only log if not in .claude directory (skip infrastructure edits)
    if [[ ! "$CLAUDE_FILE_PATH" =~ \.claude ]]; then
      echo "- ${TIMESTAMP}: Modified: $(basename ${CLAUDE_FILE_PATH:-unknown})" >> "$SUMMARY_FILE"
    fi
    ;;
  "Bash")
    # Log commits and significant commands
    if [[ "$CLAUDE_BASH_COMMAND" =~ "git commit" ]]; then
      echo "- ${TIMESTAMP}: Git commit" >> "$SUMMARY_FILE"
    elif [[ "$CLAUDE_BASH_COMMAND" =~ "mvn test"|"gradlew test" ]]; then
      echo "- ${TIMESTAMP}: Ran tests" >> "$SUMMARY_FILE"
    fi
    ;;
esac

# Keep summary file under 5KB (trim if larger)
if [[ -f "$SUMMARY_FILE" ]]; then
  SIZE=$(stat -f%z "$SUMMARY_FILE" 2>/dev/null || stat -c%s "$SUMMARY_FILE" 2>/dev/null || echo 0)
  if [[ $SIZE -gt 5000 ]]; then
    # Keep last 100 lines
    tail -100 "$SUMMARY_FILE" > "${SUMMARY_FILE}.tmp"
    mv "${SUMMARY_FILE}.tmp" "$SUMMARY_FILE"
  fi
fi

exit 0
