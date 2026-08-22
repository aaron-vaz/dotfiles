#!/usr/bin/env bash
# Soft nag: if commits happened today but no KB entry was touched today, remind
# before the session wraps up. Never blocks.
set -euo pipefail

# Overridable for tests; default to the real files in normal use.
COMMAND_LOG="${COMMAND_LOG:-$HOME/.claude/command-log.txt}"
KB_ENTRIES_DIR="${KB_ENTRIES_DIR:-$HOME/.claude/kb/entries}"

# command-log.txt lines look like: "2026-07-18T14:42:31Z: <command>" (ISO,
# from the PostToolUse/Bash hook's `date -u +%Y-%m-%dT%H:%M:%SZ`) — anchor to
# line start on that format.
TODAY=$(date -u +"%Y-%m-%d")

COMMITTED_TODAY=false
if grep -q "^${TODAY}.*git commit" "$COMMAND_LOG" 2>/dev/null; then
  COMMITTED_TODAY=true
fi

[[ "$COMMITTED_TODAY" == "false" ]] && exit 0

if ! find "$KB_ENTRIES_DIR" -name "*.md" -mtime -1 2>/dev/null | grep -q .; then
  echo "⚠️  Commits made today but no KB entry created/updated in the last 24h (~/.claude/kb/entries/). If this session had lasting decisions or context, capture them before closing out."
fi
exit 0
