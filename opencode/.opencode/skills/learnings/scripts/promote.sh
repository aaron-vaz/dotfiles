#!/bin/bash
# promote.sh - Promote a learning to AGENTS.md
# Usage: promote <id> [target_file:line]

set -e

LEARNINGS_FILE="$HOME/.config/opencode/learnings/learnings.json"
ID="$1"
TARGET="${2:-AGENTS.md}"

if [ -z "$ID" ]; then
  echo "Usage: promote <id> [target_file:line]"
  echo ""
  echo "Promotes a learning to AGENTS.md (or specified target)"
  exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required for this operation"
  exit 1
fi

# Find and update the entry
TEMP_FILE=$(mktemp)

# Use jq to update the entry status and promotedTo
  jq --arg id "$ID" --arg target "$TARGET" '
  def update_entry:
    if .id == $id then
      .status = "promoted" | .promotedTo = $target
    else
      .
    end;

  to_entries | map(
    .value.entries |= map(update_entry)
  ) | from_entries
' "$LEARNINGS_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$LEARNINGS_FILE"

echo "Promoted $ID to $TARGET"