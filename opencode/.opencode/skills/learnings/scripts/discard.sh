#!/bin/bash
# discard.sh - Discard a learning
# Usage: discard <id>

set -e

LEARNINGS_FILE="$HOME/.config/opencode/learnings/learnings.json"
ID="$1"

if [ -z "$ID" ]; then
  echo "Usage: discard <id>"
  echo ""
  echo "Marks a learning as discarded (not worth promoting to AGENTS.md)"
  exit 1
fi

TEMP_FILE=$(mktemp)

  jq --arg id "$ID" '
  def update_entry:
    if .id == $id then
      .status = "discarded"
    else
      .
    end;

  to_entries | map(
    .value.entries |= map(update_entry)
  ) | from_entries
' "$LEARNINGS_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$LEARNINGS_FILE"

echo "Discarded $ID"