#!/bin/bash
# capture.sh - Capture a new learning
# Usage: capture <topic> [category]

set -e

LEARNINGS_FILE="$HOME/.config/opencode/learnings/learnings.json"
TOPIC="$1"
CATEGORY="${2:-workflows}"

if [ -z "$TOPIC" ]; then
  echo "Usage: capture <topic> [category]"
  echo ""
  echo "Categories: misconceptions, preferences, config, commands, patterns, workflows"
  exit 1
fi

# Generate ID from topic (kebab-case)
ID=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

# Current timestamp
TIMESTAMP=$(date +%Y-%m-%d)

# Read current file to check if category exists
if ! jq -e ".categories.\"$CATEGORY\"" "$LEARNINGS_FILE" > /dev/null 2>&1; then
  echo "Error: Unknown category '$CATEGORY'"
  echo "Valid categories: misconceptions, preferences, config, commands, patterns, workflows"
  exit 1
fi

TEMP_FILE=$(mktemp)

# Add entry with pending_review status
jq --arg id "$ID" --arg timestamp "$TIMESTAMP" --arg category "$CATEGORY" '
  .categories[$category].entries += [{
    "id": $id,
    "timestamp": $timestamp,
    "status": "pending_review",
    "promotedTo": null,
    "context": "TODO: Fill in context",
    "whatIGotWrong": "TODO: Fill in what you got wrong",
    "correction": "TODO: Fill in correction",
    "details": {},
    "tags": [$category]
  }]
' "$LEARNINGS_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$LEARNINGS_FILE"

echo "Created learning: $ID"
echo ""
echo "Edit the entry with @learnings edit"
echo "Or use @learnings quick-add for interactive capture"