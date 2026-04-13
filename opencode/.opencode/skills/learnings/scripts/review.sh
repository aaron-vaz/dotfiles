#!/bin/bash
# review.sh - List pending_review learnings for end-of-session review
# Usage: review [--all]

set -e

LEARNINGS_FILE="$HOME/.config/opencode/learnings/learnings.json"
SHOW_ALL="${1:-}"

if [ ! -f "$LEARNINGS_FILE" ]; then
  echo "No learnings file found at $LEARNINGS_FILE"
  exit 1
fi

echo "=== LEARNINGS REVIEW ==="
echo ""

if [ "$SHOW_ALL" = "--all" ]; then
  echo "Showing ALL entries (status: pending_review | promoted | discarded)"
  echo ""
  jq -r '
    to_entries[] | 
    "[\(.key)] \(.value.description)\n" +
    (.value.entries | map(
      "\n  [\(.id)] status=\(.status)\n" +
      "    Context: \(.context)\n" +
      "    Wrong: \(.whatIGotWrong[0:80])...\n" +
      "    Fix: \(.correction[0:80])..."
    ) | join("\n"))
  ' "$LEARNINGS_FILE"
else
  echo "Showing PENDING REVIEW entries only"
  echo ""
  jq -r '
    to_entries[] | 
    "[\(.key)] \(.value.description)\n" +
    (.value.entries | map(
      select(.status == "pending_review") |
      "\n  [\(.id)]\n" +
      "    Context: \(.context)\n" +
      "    Wrong: \(.whatIGotWrong[0:100])...\n" +
      "    Fix: \(.correction[0:100])...\n" +
      "    Tags: \(.tags | join(", "))"
    ) | join("\n"))
  ' "$LEARNINGS_FILE"
fi

echo ""
echo "=== ACTIONS ==="
echo "@learnings promote <id>  - Move to AGENTS.md"
echo "@learnings discard <id> - Mark as not worth promoting"
echo "@learnings review --all - Show all entries"