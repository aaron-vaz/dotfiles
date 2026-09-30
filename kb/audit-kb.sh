#!/usr/bin/env bash
# audit-kb.sh — Audit knowledge base for stale entries and promotion candidates
# Usage: audit-kb.sh [--dry-run|--apply] [--report]

set -euo pipefail

KB_ROOT="$(cd "$(dirname "$0")" && pwd)"
PUBLIC_DIR="$KB_ROOT/entries"
PRIVATE_DIR="${KB_PRIVATE_DIR:-$KB_ROOT/private}"
LOG="$KB_ROOT/audit-log.txt"
DRY_RUN=true
REPORT=false
VISIBILITY=""  # "" = both | public | private

while [[ $# -gt 0 ]]; do
  case $1 in
    --apply)        DRY_RUN=false; shift ;;
    --dry-run)      DRY_RUN=true;  shift ;;
    --report)       REPORT=true;   shift ;;
    --no-private)   VISIBILITY="public";  shift ;;
    --only-private) VISIBILITY="private"; shift ;;
    *)              shift ;;
  esac
done

TODAY=$(date +%Y-%m-%d)
stale_count=0
review_count=0
untagged_count=0
nested_count=0
missing_count=0
long_desc_count=0
MAX_DESC_CHARS=300

echo "=== Knowledge Base Audit: $TODAY ==="
echo ""

# Both entry stores — auditing only entries/ after the public/private split would
# silently skip half the KB and report a clean bill of health for the other half.
SCAN_DIRS=()
for d in "$PUBLIC_DIR" "$PRIVATE_DIR"; do
  [[ -d "$d" ]] || continue
  v="public"; [[ "$d" == "$PRIVATE_DIR" ]] && v="private"
  [[ -n "$VISIBILITY" ]] && [[ "$VISIBILITY" != "$v" ]] && continue
  SCAN_DIRS+=("$d")
done

for dir in "${SCAN_DIRS[@]}"; do
vis="public"; [[ "$dir" == "$PRIVATE_DIR" ]] && vis="private"
for f in "$dir"/*.md; do
  [[ -f "$f" ]] || continue
  [[ "$(basename "$f")" == ".gitkeep" ]] && continue

  frontmatter=$(awk '/^---$/{found++; next} found==1{print}' "$f")
  status=$(echo  "$frontmatter" | grep '^status:'  | sed 's/status: *//' || true)
  expires=$(echo "$frontmatter" | grep '^expires:' | sed 's/expires: *//' || true)
  title=$(echo   "$frontmatter" | grep '^name:'    | sed 's/name: *"*//;s/"$//' || true)
  type=$(echo    "$frontmatter" | grep '^type:'    | sed 's/type: *//' || true)
  tags=$(echo    "$frontmatter" | grep '^tags:'    | sed 's/tags: *\[//;s/\]//' || true)
  fname=$(basename "$f")
  [[ "$vis" == "private" ]] && fname="$fname [private]"

  # search-kb.sh --brief shows the description as the only routing text, --type
  # filters on type, and name is the slug. An entry missing any of them is
  # effectively unroutable, so this is the one check that fails the audit. Empty
  # means empty after stripping quotes/whitespace (`name: ""` counts). Runs before
  # the evergreen `continue` below so every entry type is covered.
  desc=$(echo "$frontmatter" | grep '^description:' | sed 's/description: *"*//;s/"$//' || true)
  missing=""
  [[ -z "$(printf '%s' "$title" | tr -d "[:space:]\"'")" ]] && missing="$missing name"
  [[ -z "$(printf '%s' "$type"  | tr -d "[:space:]\"'")" ]] && missing="$missing type"
  [[ -z "$(printf '%s' "$desc"  | tr -d "[:space:]\"'")" ]] && missing="$missing description"
  if [[ -n "$missing" ]]; then
    echo "  MISSING METADATA: $fname"
    echo "         Missing or empty:${missing}"
    echo "         Unroutable — search-kb.sh needs name (slug), type (--type) and description (--brief)."
    echo ""
    missing_count=$((missing_count + 1))
  fi

  # Long descriptions bloat every --brief result row, which is the routing text
  # loaded into context. Warn only. Count characters, not bytes: descriptions
  # carry em-dashes and BSD awk `length` counts bytes.
  desc_len=$(printf '%s' "$desc" | LC_ALL=en_US.UTF-8 wc -m | tr -d ' ')
  if [[ "$desc_len" -gt "$MAX_DESC_CHARS" ]]; then
    echo "  LONG DESCRIPTION: $fname"
    echo "         ${desc_len} chars (max ${MAX_DESC_CHARS}) — sharpen to the load-bearing point."
    echo ""
    long_desc_count=$((long_desc_count + 1))
  fi

  # An entry carrying `metadata:\n  type: X` instead of a top-level `type: X` is
  # invisible to search-kb.sh's --type/--tag filters AND to this audit's own
  # checks below, which both read the flat key. That schema comes from Claude
  # Code's built-in auto-memory format; entries written or migrated from it slip
  # through with a real rule nobody can retrieve. never-commit-to-main sat like
  # that and never surfaced under the `--type feedback` lookup AGENTS.md marks MUST.
  if [[ -z "$type" ]] && echo "$frontmatter" | grep -qE '^[[:space:]]+type:'; then
    nested=$(echo "$frontmatter" | grep -E '^[[:space:]]+type:' | sed 's/.*type: *//' | head -1)
    echo "  NESTED SCHEMA: $fname"
    echo "         \"$title\""
    echo "         type is nested under metadata: (found '$nested') — invisible to --type/--tag lookups."
    echo "         Fix: move it to a top-level 'type: $nested' key."
    echo ""
    nested_count=$((nested_count + 1))
  fi

  # A type:feedback/user/reference/preference entry with no tags is invisible to
  # the --type + --tag trigger patterns in AGENTS.md (e.g. "--type feedback --tag
  # slack") — it only surfaces via --type alone, which nothing in AGENTS.md queries
  # bare. Flag it regardless of staleness rules below.
  case "$type" in
    feedback|user|reference|preference)
      if [[ -z "$(echo "$tags" | tr -d '[:space:]')" ]]; then
        echo "  UNTAGGED $type: $fname"
        echo "         \"$title\""
        echo "         No tags — invisible to --type + --tag trigger lookups"
        echo ""
        untagged_count=$((untagged_count + 1))
      fi
      ;;
  esac

  # feedback/user/reference entries are durable facts, not session logs — they
  # don't decay on a 90-day clock, so skip staleness aging regardless of expires.
  case "$type" in feedback|user|reference|preference) continue ;; esac

  # Check active entries past expiry
  if [[ "$status" == "active" ]] && [[ -n "$expires" ]] && [[ "$expires" < "$TODAY" ]]; then
    echo "  STALE: $fname"
    echo "         \"$title\""
    echo "         Expired: $expires"
    echo ""
    stale_count=$((stale_count + 1))
    if [[ "$DRY_RUN" == false ]]; then
      sed -i '' "s/^status: active/status: stale/" "$f"
      echo "$(date +%Y-%m-%d) | STALE | $fname | Expired $expires" >> "$LOG"
    fi
  fi

  # Check stale entries past 90 extra days (candidates for pruning)
  if [[ "$status" == "stale" ]] && [[ -n "$expires" ]]; then
    prune_date=$(date -v+90d -j -f "%Y-%m-%d" "$expires" +%Y-%m-%d 2>/dev/null || \
      date -d "$expires + 90 days" +%Y-%m-%d 2>/dev/null || echo "")
    if [[ -n "$prune_date" ]] && [[ "$prune_date" < "$TODAY" ]]; then
      echo "  PRUNE CANDIDATE: $fname"
      echo "         \"$title\""
      echo "         Stale since: $expires"
      echo ""
      review_count=$((review_count + 1))
    fi
  fi
done
done

echo "=== Summary ==="
echo "  Scanned: $(for d in "${SCAN_DIRS[@]}"; do basename "$d"; done | tr '\n' ' ')"
echo "  Stale entries marked: $stale_count"
echo "  Prune candidates:     $review_count"
echo "  Untagged evergreen entries (invisible to trigger lookups): $untagged_count"
echo "  Nested-schema entries (type: under metadata:, invisible to --type):  $nested_count"
echo "  Missing metadata (name/type/description absent or empty, FAILS audit): $missing_count"
echo "  Long descriptions (> $MAX_DESC_CHARS chars, warning only): $long_desc_count"
if [[ "$DRY_RUN" == true ]] && [[ $stale_count -gt 0 ]]; then
  echo ""
  echo "  Run with --apply to mark stale entries."
fi
echo ""
echo "  Promotion note: Review stale entries. If content is fully captured"
echo "  in a skill or reference, update status: promoted and promoted_to: <path>."

# Only missing metadata fails the audit; every other check is informational.
[[ $missing_count -eq 0 ]] || exit 1
