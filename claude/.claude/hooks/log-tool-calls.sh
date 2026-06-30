#!/bin/bash
# Logs all tool calls to ~/.claude/tool-audit.log for periodic permission auditing.
# Runs as a PostToolUse hook. Uses CLAUDE_TOOL_INPUT (JSON) to extract Bash commands.
set +e

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
AUDIT_LOG="$HOME/.claude/tool-audit.log"

[[ -z "$TOOL_NAME" ]] && exit 0

if [[ "$TOOL_NAME" == "Bash" ]] && command -v jq &>/dev/null; then
    CMD=$(echo "${CLAUDE_TOOL_INPUT:-{}}" | jq -r '.command // empty' 2>/dev/null)
    [[ -z "$CMD" ]] && exit 0
    printf '%s\tBash\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$CMD" >> "$AUDIT_LOG" 2>/dev/null
else
    printf '%s\tTool\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TOOL_NAME" >> "$AUDIT_LOG" 2>/dev/null
fi

exit 0
