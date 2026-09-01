#!/usr/bin/env bash
# SessionStart: if this project has an active checkpoint, surface the exact
# /pickup command instead of making the user dig for it via search-kb.sh.
# Filters on status:active (pickup flips completed ones to status:done), not
# file age — an untouched-but-still-open checkpoint stays relevant.
set -uo pipefail

cat >/dev/null 2>&1 || true  # drain stdin JSON payload; not needed here

KB_PRIVATE_DIR="${KB_PRIVATE_DIR:-$HOME/.agents/kb/private}"
KB_ENTRIES_DIR="${KB_ENTRIES_DIR:-$HOME/.agents/kb/entries}"
REPO="$(basename "$PWD")"

found=""
for dir in "$KB_PRIVATE_DIR" "$KB_ENTRIES_DIR"; do
  [[ -d "$dir" ]] || continue
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    grep -q "^status: active" "$f" 2>/dev/null || continue
    grep -qE "^tags:.*checkpoint" "$f" 2>/dev/null || continue
    grep -qi "$REPO" "$f" 2>/dev/null || continue
    found="$found$(basename "$f" .md)"$'\n'
  done < <(find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null)
done

found="$(echo "$found" | grep -v '^$' || true)"
[[ -z "$found" ]] && exit 0

echo "## Active checkpoint(s) found — resume with:"
echo "$found" | sed 's/^/\/pickup /'
exit 0
