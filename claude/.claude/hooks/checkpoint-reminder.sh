#!/usr/bin/env bash
# PreCompact: compaction summarizes context, it doesn't preserve it verbatim —
# in-progress decisions/next-steps can get lossy or dropped. Nudge to
# /checkpoint first, unless one was already written recently (avoid nagging
# on back-to-back compactions).
set -uo pipefail

KB_PRIVATE_DIR="${KB_PRIVATE_DIR:-$HOME/.agents/kb/private}"
KB_ENTRIES_DIR="${KB_ENTRIES_DIR:-$HOME/.agents/kb/entries}"

cat >/dev/null 2>&1 || true  # drain stdin JSON payload; not needed here

recent=false
for dir in "$KB_PRIVATE_DIR" "$KB_ENTRIES_DIR"; do
  [[ -d "$dir" ]] || continue
  if find "$dir" -name "checkpoint-*.md" -mmin -15 2>/dev/null | grep -q .; then
    recent=true
  fi
done

[[ "$recent" == "true" ]] && exit 0

echo "Compaction about to run — task state (decisions, next steps, blockers) may not survive verbatim. Run /checkpoint first if this session has state worth resuming exactly."
exit 0
