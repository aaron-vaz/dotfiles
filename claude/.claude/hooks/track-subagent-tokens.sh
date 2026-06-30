#!/bin/bash
# Track subagent tokens from Workflow/Agent tool completions.
# Accumulates into ~/.claude/costs/subagent-YYYY-MM.json so statusline.js
# can add estimated subagent cost to the session total.
set +e

HOOK_DATA=$(cat)

# Debug log: capture full stdin for the first 30 lines total so we can
# verify the exact JSON path where subagent_tokens lives.
DEBUG_LOG="$HOME/.claude/logs/subagent-hook-debug.log"
touch "$DEBUG_LOG" 2>/dev/null || true
DEBUG_LINES=$(wc -l < "$DEBUG_LOG" 2>/dev/null || echo 0)
if [[ "$DEBUG_LINES" -lt 30 ]]; then
    printf "\n=== %s ===\n" "$(date -u)" >> "$DEBUG_LOG"
    echo "$HOOK_DATA" | jq '.' 2>/dev/null >> "$DEBUG_LOG" || echo "$HOOK_DATA" | head -50 >> "$DEBUG_LOG"
fi

SESSION_ID=$(echo "$HOOK_DATA" | jq -r '.session_id // empty' 2>/dev/null)
[[ -z "$SESSION_ID" ]] && exit 0

# Try every known path — we'll narrow this once the debug log confirms structure.
SUBAGENT_TOKENS=$(echo "$HOOK_DATA" | jq -r '
  .usage.subagent_tokens //
  .usage.subagentTokens //
  .tool_response.usage.subagent_tokens //
  .tool_response.usage.subagentTokens //
  .tool_response.subagent_tokens //
  .tool_response.subagentTokens //
  0' 2>/dev/null)

[[ -z "$SUBAGENT_TOKENS" || "$SUBAGENT_TOKENS" == "0" || "$SUBAGENT_TOKENS" == "null" ]] && exit 0

# Accumulate into monthly file
COSTS_DIR="$HOME/.claude/costs"
mkdir -p "$COSTS_DIR"

MONTH=$(date -u +%Y-%m)
ACCUM_FILE="$COSTS_DIR/subagent-${MONTH}.json"

EXISTING=$(cat "$ACCUM_FILE" 2>/dev/null || echo '{"sessions":{}}')
CURRENT_TOKENS=$(echo "$EXISTING" | jq -r ".sessions[\"$SESSION_ID\"].tokens // 0" 2>/dev/null || echo 0)
NEW_TOKENS=$(( CURRENT_TOKENS + SUBAGENT_TOKENS ))

echo "$EXISTING" | jq ".sessions[\"$SESSION_ID\"].tokens = $NEW_TOKENS" > "$ACCUM_FILE"

exit 0
