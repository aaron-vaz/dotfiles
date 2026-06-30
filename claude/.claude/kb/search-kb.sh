#!/usr/bin/env bash
# search-kb.sh — Search the Claude Code knowledge base
# Usage: search-kb.sh [--tag TAG] [--project NAME] [--status STATUS] [--brief|--medium|--full] [QUERY]

set -euo pipefail

KB_DIR="$(cd "$(dirname "$0")/entries" && pwd)"
INDEX="$(dirname "$0")/index.tsv"

# Defaults
TAG=""
PROJECT=""
STATUS="active"
MODE="brief"  # brief | medium | full
REBUILD=false
LIST_TAGS=false
LIST_PROJECTS=false
QUERY=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tag)           TAG="$2"; shift 2 ;;
    --project)       PROJECT="$2"; shift 2 ;;
    --status)        STATUS="$2"; shift 2 ;;
    --all)           STATUS=""; shift ;;
    --full)          MODE="full"; shift ;;
    --medium)        MODE="medium"; shift ;;
    --brief)         MODE="brief"; shift ;;
    --rebuild-index) REBUILD=true; shift ;;
    --list-tags)     LIST_TAGS=true; shift ;;
    --list-projects) LIST_PROJECTS=true; shift ;;
    --)              shift; QUERY="$*"; break ;;
    -*)              echo "Unknown option: $1" >&2; exit 1 ;;
    *)               QUERY="${QUERY:+$QUERY }$1"; shift ;;
  esac
done

# Build TSV index from YAML frontmatter
build_index() {
  local tmpfile
  tmpfile=$(mktemp)
  printf 'date\tstatus\tproject\ttags\ttitle\toutcome\tsummary\tfile\n' > "$tmpfile"
  for f in "$KB_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    [[ "$(basename "$f")" == ".gitkeep" ]] && continue
    local frontmatter date status project tags title outcome summary
    frontmatter=$(awk '/^---$/{found++; next} found==1{print}' "$f")
    date=$(echo     "$frontmatter" | grep '^date:'    | sed 's/date: *//'    || true)
    status=$(echo   "$frontmatter" | grep '^status:'  | sed 's/status: *//' || true)
    project=$(echo  "$frontmatter" | grep '^project:' | sed 's/project: *//' || true)
    tags=$(echo     "$frontmatter" | grep '^tags:'    | sed 's/tags: *\[//;s/\]//' || true)
    title=$(echo    "$frontmatter" | grep '^title:'   | sed 's/title: *"*//;s/"$//' || true)
    outcome=$(echo  "$frontmatter" | grep '^outcome:' | sed 's/outcome: *"*//;s/"$//' || true)
    summary=$(echo  "$frontmatter" | grep '^summary:' | sed 's/summary: *"*//;s/"$//' || true)
    # Fall back to outcome if no summary field present
    [[ -z "$summary" ]] && summary="$outcome"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$date" "$status" "$project" "$tags" "$title" "$outcome" "$summary" "$(basename "$f")"
  done >> "$tmpfile"
  mv "$tmpfile" "$INDEX"
}

# Rebuild index if requested, missing, stale, or schema changed (column count)
if [[ "$REBUILD" == true ]] || \
   [[ ! -f "$INDEX" ]] || \
   [[ -n "$(find "$KB_DIR" -name '*.md' -newer "$INDEX" 2>/dev/null)" ]] || \
   [[ "$(head -1 "$INDEX" 2>/dev/null | awk -F'\t' '{print NF}')" -lt 8 ]]; then
  build_index
fi

# Handle list modes
if [[ "$LIST_TAGS" == true ]]; then
  tail -n +2 "$INDEX" | cut -f4 | tr ',' '\n' | sed 's/^ *//;s/ *$//' | \
    grep -v '^$' | sort | uniq -c | sort -rn
  exit 0
fi

if [[ "$LIST_PROJECTS" == true ]]; then
  tail -n +2 "$INDEX" | cut -f3 | grep -v '^$' | sort | uniq -c | sort -rn
  exit 0
fi

# Search: filter index
results=$(tail -n +2 "$INDEX")
[[ -n "$STATUS" ]]  && results=$(echo "$results" | awk -F'\t' -v s="$STATUS" '$2 == s')
[[ -n "$TAG" ]]     && results=$(echo "$results" | awk -F'\t' -v t="$TAG"    'index($4, t) > 0')
[[ -n "$PROJECT" ]] && results=$(echo "$results" | awk -F'\t' -v p="$PROJECT" \
  'tolower($3) ~ tolower(p) || tolower($5) ~ tolower(p) || tolower($6) ~ tolower(p)')
[[ -n "$QUERY" ]]   && results=$(echo "$results" | grep -i "$QUERY")

# Full-text fallback: if QUERY produced no TSV hits, grep raw entry files
if [[ -n "$QUERY" ]] && [[ -z "$results" ]]; then
  matching_files=$(grep -ril "$QUERY" "$KB_DIR"/*.md 2>/dev/null | xargs -I{} basename {} || true)
  for fname in $matching_files; do
    row=$(grep -F "$fname" "$INDEX" || true)
    [[ -z "$row" ]] && continue
    # Apply status filter to full-text results too
    if [[ -n "$STATUS" ]]; then
      echo "$row" | awk -F'\t' -v s="$STATUS" '$2 == s' || true
    else
      echo "$row"
    fi
  done | sort -u || true
  exit 0
fi

[[ -z "$results" ]] && exit 0

# Output
if [[ "$MODE" == "full" ]]; then
  while IFS=$'\t' read -r _date _status _project _tags _title _outcome _summary file; do
    cat "$KB_DIR/$file"
    echo ""
  done <<< "$results"
elif [[ "$MODE" == "medium" ]]; then
  # Medium: date | slug | [tags] | summary (multi-sentence, falls back to outcome)
  while IFS=$'\t' read -r date _status _project tags _title _outcome summary file; do
    slug="${file%.md}"
    printf '%s | %s | [%s]\n  %s\n' "$date" "$slug" "$tags" "$summary"
  done <<< "$results"
else
  # Brief: date | slug | [tags] | outcome
  while IFS=$'\t' read -r date _status _project tags _title outcome _summary file; do
    slug="${file%.md}"
    printf '%s | %s | [%s] | %s\n' "$date" "$slug" "$tags" "$outcome"
  done <<< "$results"
fi
