#!/bin/bash
# Unified terminal-notifier wrapper with osascript fallback.
# Usage: notify.sh <title> <subtitle> <message> [url] [group] [sound]
#   url   - opened on click (optional)
#   group - replaces older notification with same group key (optional)
#   sound - Tink|Purr|Glass|default (optional, default=silent)

set -euo pipefail

# No-op in container environments (no terminal-notifier or osascript)
if [ "${NOTIFY_SKIP:-}" = "true" ]; then
  exit 0
fi

title="${1:-Claude Code}"
subtitle="${2:-}"
message="${3:-}"
url="${4:-}"
group="${5:-}"
sound="${6:-}"

if command -v terminal-notifier >/dev/null 2>&1; then
  args=(-title "$title" -message "$message")
  [ -n "$subtitle" ] && args+=(-subtitle "$subtitle")
  [ -n "$url" ] && args+=(-open "$url")
  [ -n "$group" ] && args+=(-group "$group")
  [ -n "$sound" ] && args+=(-sound "$sound")
  terminal-notifier "${args[@]}" >/dev/null 2>&1
else
  msg="$message"
  [ -n "$subtitle" ] && msg="$subtitle: $message"
  osascript -e "display notification \"${msg//\"/\\\"}\" with title \"${title//\"/\\\"}\"" >/dev/null 2>&1
fi
