#!/bin/bash
# SubagentStart hook: record agent_id -> agent_type so the subagent status line
# can show which custom agent a row is (the status-line payload carries none).
# Observational only — never blocks. State: ~/.claude/state/subagents/<agent_id>.
set +e
command -v jq &>/dev/null || exit 0

PAYLOAD="$(cat 2>/dev/null)"
AGENT_ID="$(echo "$PAYLOAD" | jq -r '.agent_id // empty' 2>/dev/null)"
AGENT_TYPE="$(echo "$PAYLOAD" | jq -r '.agent_type // empty' 2>/dev/null)"
[[ -z "$AGENT_ID" || -z "$AGENT_TYPE" ]] && exit 0
[[ "$AGENT_ID" =~ ^[A-Za-z0-9_-]+$ ]] || exit 0

STATE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/state/subagents"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
printf '%s' "$AGENT_TYPE" > "$STATE_DIR/$AGENT_ID" 2>/dev/null

# Drop entries from long-finished sessions so the dir doesn't grow forever.
find "$STATE_DIR" -type f -mtime +2 -delete 2>/dev/null

exit 0
