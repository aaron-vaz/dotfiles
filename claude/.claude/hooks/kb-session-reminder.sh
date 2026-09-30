#!/usr/bin/env bash
# Soft nag: if commits happened today but no KB entry was touched today, remind
# before the session wraps up. Never blocks.
set -euo pipefail

# Overridable for tests; default to the real files in normal use.
COMMAND_LOG="${COMMAND_LOG:-$HOME/.claude/command-log.txt}"
KB_ENTRIES_DIR="${KB_ENTRIES_DIR:-$HOME/.agents/kb/entries}"
KB_PRIVATE_DIR="${KB_PRIVATE_DIR:-$HOME/.agents/kb/private}"

# command-log.txt lines look like: "2026-07-18T14:42:31Z: <command>" (ISO,
# from the PostToolUse/Bash hook's `date -u +%Y-%m-%dT%H:%M:%SZ`) — anchor to
# line start on that format.
TODAY=$(date -u +"%Y-%m-%d")

COMMITTED_TODAY=false
if grep -q "^${TODAY}.*git commit" "$COMMAND_LOG" 2>/dev/null; then
  COMMITTED_TODAY=true
fi

[[ "$COMMITTED_TODAY" == "false" ]] && exit 0

# `find -L` is required, not cosmetic: entries/ is a symlink into the dotfiles
# repo, and plain `find` does not follow a symlinked start point — it returned
# zero matches, so this always warned. Capture the output and test non-empty
# rather than `| grep -q .`, which can SIGPIPE find under pipefail.
FRESH=""
for dir in "$KB_ENTRIES_DIR" "$KB_PRIVATE_DIR"; do
  [[ -d "$dir" ]] || continue
  FRESH+="$(find -L "$dir" -name '*.md' -mtime -1 2>/dev/null || true)"
done

if [[ -z "$FRESH" ]]; then
  echo "⚠️  Commits made today but no KB entry created/updated in the last 24h (~/.agents/kb/private/ or ~/.agents/kb/entries/). If this session had lasting decisions or context, capture them before closing out."
fi
exit 0
