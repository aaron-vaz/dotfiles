#!/bin/bash
# Logs all tool calls to ~/.claude/tool-audit.log for periodic permission auditing.
# Runs as a PostToolUse hook.
set +e

# Tool metadata arrives as JSON on stdin. CLAUDE_TOOL_NAME / CLAUDE_TOOL_INPUT
# are a stale contract and are never set (verified 2026-08-22) — reading them
# made this hook a silent no-op. See validate-git-usage.sh for the full note.
command -v jq &>/dev/null || exit 0

PAYLOAD="$(cat 2>/dev/null)"
TOOL_NAME="$(echo "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)"
[[ -z "$TOOL_NAME" ]] && exit 0

AUDIT_LOG="$HOME/.claude/tool-audit.log"

if [[ "$TOOL_NAME" == "Bash" ]]; then
    CMD="$(echo "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    [[ -z "$CMD" ]] && exit 0
    printf '%s\tBash\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$CMD" >> "$AUDIT_LOG" 2>/dev/null
else
    printf '%s\tTool\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TOOL_NAME" >> "$AUDIT_LOG" 2>/dev/null
fi

exit 0
