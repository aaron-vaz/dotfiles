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
if [[ "$DRY_RUN" == true ]] && [[ $stale_count -gt 0 ]]; then
  echo ""
  echo "  Run with --apply to mark stale entries."
fi
echo ""
echo "  Promotion note: Review stale entries. If content is fully captured"
echo "  in a skill or reference, update status: promoted and promoted_to: <path>."
