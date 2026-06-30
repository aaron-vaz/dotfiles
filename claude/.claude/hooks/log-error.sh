#!/bin/bash
set +e  # Don't fail on errors

# Ensure learnings directory exists
LEARNINGS_DIR="$HOME/.claude/learnings"
mkdir -p "$LEARNINGS_DIR" 2>/dev/null

# Clean up old learning logs (older than 90 days)
find "$LEARNINGS_DIR" -name "*.log" -type f -mtime +90 -delete 2>/dev/null || true

# Log file for today
LOG="$LEARNINGS_DIR/$(date +%Y-%m-%d).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# PostToolUseFailure hooks receive JSON via stdin with tool context
HOOK_DATA=$(cat)

# Parse JSON using jq if available, otherwise use basic parsing
if command -v jq &> /dev/null; then
  TOOL_NAME=$(echo "$HOOK_DATA" | jq -r '.tool_name // "unknown"')
  TOOL_ERROR=$(echo "$HOOK_DATA" | jq -r '.error // "no error message"')
  TOOL_PARAMS=$(echo "$HOOK_DATA" | jq -c '.tool_input // empty' 2>/dev/null | head -c 300)
else
  # Fallback to grep/sed parsing
  TOOL_NAME=$(echo "$HOOK_DATA" | grep -o '"tool_name":"[^"]*"' | head -1 | sed 's/"tool_name":"//;s/"//')
  TOOL_ERROR=$(echo "$HOOK_DATA" | grep -o '"error":\s*"[^"]*"' | head -1 | sed 's/"error":\s*"//;s/"//')
  TOOL_PARAMS=""
fi

# Fallback to unknown if parsing failed
TOOL_NAME="${TOOL_NAME:-unknown}"
TOOL_ERROR="${TOOL_ERROR:-no error message}"

# Log with context
{
  echo "[$TIMESTAMP] ERROR"
  echo "Tool: $TOOL_NAME"

  # Show parameters if available (helps identify what was attempted)
  if [[ -n "$TOOL_PARAMS" ]]; then
    echo "Parameters: $TOOL_PARAMS"
  fi

  # Capture error message (truncate if too long)
  if [[ ${#TOOL_ERROR} -gt 500 ]]; then
    echo "Error: ${TOOL_ERROR:0:500}... (truncated)"
  else
    echo "Error: $TOOL_ERROR"
  fi

  echo "---"
} >> "$LOG" 2>/dev/null

# Always exit successfully
exit 0
