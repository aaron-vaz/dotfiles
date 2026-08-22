#!/usr/bin/env bash
# search-kb.sh — Search the Claude Code knowledge base
# Usage: search-kb.sh [--tag TAG] [--type TYPE] [--project NAME] [--status STATUS]
#                     [--brief|--medium|--full] [--no-private|--only-private] [QUERY]
# TYPE is the frontmatter `type:` field — one of: user, preference, feedback, project, reference, knowledge.
# See ~/.claude/kb/TEMPLATE-feedback.md for the feedback/user/reference entry shape.
#
# Two entry stores:
#   entries/   public  — safe to track in the (public) dotfiles repo
#   private/   private — never tracked, never symlinked into a repo. Anything
#                        naming an employer, a private product, internal hosts,
#                        or a private repo's internals lives here.
#
# Private entries are INCLUDED BY DEFAULT and marked with a `*` in brief/medium
# output. Excluding them by default would recreate the failure this split was
# made to prevent: knowledge existing where search cannot see it, so advice gets
# given in ignorance of decisions already recorded. Use --no-private when the
# output is headed somewhere public (a PR comment, an issue, a shared doc).

set -euo pipefail

KB_ROOT="$(cd "$(dirname "$0")" && pwd)"
PUBLIC_DIR="$KB_ROOT/entries"
PRIVATE_DIR="${KB_PRIVATE_DIR:-$KB_ROOT/private}"
INDEX="$KB_ROOT/index.tsv"

# Defaults
TAG=""
TYPE=""
PROJECT=""
STATUS="active"
MODE="brief"  # brief | medium | full
VISIBILITY=""  # "" = both | public | private
REBUILD=false
LIST_TAGS=false
LIST_PROJECTS=false
QUERY=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tag)           TAG="$2"; shift 2 ;;
    --type)          TYPE="$2"; shift 2 ;;
    --project)       PROJECT="$2"; shift 2 ;;
    --status)        STATUS="$2"; shift 2 ;;
    --all)           STATUS=""; shift ;;
    --full)          MODE="full"; shift ;;
    --medium)        MODE="medium"; shift ;;
    --brief)         MODE="brief"; shift ;;
    --no-private)    VISIBILITY="public"; shift ;;
    --only-private)  VISIBILITY="private"; shift ;;
    --rebuild-index) REBUILD=true; shift ;;
    --list-tags)     LIST_TAGS=true; shift ;;
    --list-projects) LIST_PROJECTS=true; shift ;;
    --)              shift; QUERY="$*"; break ;;
    -*)              echo "Unknown option: $1" >&2; exit 1 ;;
    *)               QUERY="${QUERY:+$QUERY }$1"; shift ;;
  esac
done

# Resolve an entry's directory from its visibility column.
dir_for_visibility() {
  case "$1" in
    private) echo "$PRIVATE_DIR" ;;
    *)       echo "$PUBLIC_DIR" ;;
  esac
}

# Build TSV index from YAML frontmatter.
# Column 8 stays a BASENAME (the full-text fallback greps the index by basename,
# and display strips .md for the slug); column 9 carries visibility, which is
# what resolves the basename back to a directory.
build_index() {
  local tmpfile
  tmpfile=$(mktemp)
  printf 'date\tstatus\tproject\ttags\tname\ttype\tdescription\tfile\tvisibility\n' > "$tmpfile"
  local dir visibility
  for dir in "$PUBLIC_DIR" "$PRIVATE_DIR"; do
    [[ -d "$dir" ]] || continue
    visibility="public"
    [[ "$dir" == "$PRIVATE_DIR" ]] && visibility="private"
    # No nullglob here: a dir with no .md files yields the literal glob, which
    # the -f guard below drops.
    for f in "$dir"/*.md; do
      [[ -f "$f" ]] || continue
      [[ "$(basename "$f")" == ".gitkeep" ]] && continue
      local frontmatter date status project tags name type description
      frontmatter=$(awk '/^---$/{found++; next} found==1{print}' "$f")
      date=$(echo        "$frontmatter" | grep '^date:'        | sed 's/date: *//'        || true)
      status=$(echo      "$frontmatter" | grep '^status:'      | sed 's/status: *//'       || true)
      project=$(echo     "$frontmatter" | grep '^project:'     | sed 's/project: *//'      || true)
      tags=$(echo        "$frontmatter" | grep '^tags:'        | sed 's/tags: *\[//;s/\]//' || true)
      name=$(echo        "$frontmatter" | grep '^name:'        | sed 's/name: *"*//;s/"$//' || true)
      type=$(echo        "$frontmatter" | grep '^type:'        | sed 's/type: *//'          || true)
      description=$(echo "$frontmatter" | grep '^description:' | sed 's/description: *"*//;s/"$//' || true)
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$date" "$status" "$project" "$tags" "$name" "$type" "$description" \
        "$(basename "$f")" "$visibility"
    done
  done >> "$tmpfile"
  mv "$tmpfile" "$INDEX"
}

# Rebuild if requested, missing, stale in EITHER store, or schema changed.
# The column-count floor must track the schema: it was 8 before visibility was
# added, and a stale 8-column index against a 9-column schema would pass an
# `-lt 8` test and silently misalign every field.
# `find -L` is required, not cosmetic: entries/ is a symlink into the dotfiles
# repo, and plain `find` does not follow a symlinked start point — it returned
# zero matches, so no public entry could ever trigger a rebuild.
newer_entries=""
file_count=0
for dir in "$PUBLIC_DIR" "$PRIVATE_DIR"; do
  [[ -d "$dir" ]] || continue
  newer_entries+="$(find -L "$dir" -name '*.md' -newer "$INDEX" 2>/dev/null)"
  file_count=$(( file_count + $(find -L "$dir" -name '*.md' 2>/dev/null | wc -l) ))
done

# `-newer` only ever detects additions and edits. A deleted or moved entry
# leaves its row behind forever — which is exactly what happened when an entry
# was deduped and six were promoted from private to public: search kept
# returning a file that no longer existed. Compare counts as well as mtimes.
index_rows=0
[[ -f "$INDEX" ]] && index_rows=$(( $(wc -l < "$INDEX") - 1 ))

if [[ "$REBUILD" == true ]] || \
   [[ ! -f "$INDEX" ]] || \
   [[ -n "$newer_entries" ]] || \
   [[ "$index_rows" -ne "$file_count" ]] || \
   [[ "$(head -1 "$INDEX" 2>/dev/null | awk -F'\t' '{print NF}')" -lt 9 ]]; then
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
[[ -n "$VISIBILITY" ]] && results=$(echo "$results" | awk -F'\t' -v v="$VISIBILITY" '$9 == v')
[[ -n "$STATUS" ]]  && results=$(echo "$results" | awk -F'\t' -v s="$STATUS" '$2 == s')
[[ -n "$TAG" ]]     && results=$(echo "$results" | awk -F'\t' -v t="$TAG"    'index($4, t) > 0')
[[ -n "$TYPE" ]]    && results=$(echo "$results" | awk -F'\t' -v ty="$TYPE" '$6 == ty')
[[ -n "$PROJECT" ]] && results=$(echo "$results" | awk -F'\t' -v p="$PROJECT" \
  'tolower($3) ~ tolower(p) || tolower($5) ~ tolower(p) || tolower($7) ~ tolower(p)')
# `|| true` is load-bearing: grep exits 1 on no match, and under `set -e` that
# killed the whole script right here — which is precisely the case the full-text
# fallback below exists to handle, so the fallback had never once run.
[[ -n "$QUERY" ]]   && results=$(echo "$results" | grep -i "$QUERY" || true)

# Latest first — filenames are date-prefixed but index build order (filesystem glob)
# is not guaranteed sorted, so sort explicitly on the date column.
[[ -n "$results" ]] && results=$(echo "$results" | sort -t$'\t' -k1,1 -r)

# Full-text fallback: if QUERY produced no TSV hits, grep raw entry files.
# Matches the index row on basename AND visibility — basename alone can hit the
# wrong row once the same filename exists in both stores.
if [[ -n "$QUERY" ]] && [[ -z "$results" ]]; then
  results=$(
    for dir in "$PUBLIC_DIR" "$PRIVATE_DIR"; do
      if [[ ! -d "$dir" ]]; then continue; fi
      vis="public"
      if [[ "$dir" == "$PRIVATE_DIR" ]]; then vis="private"; fi
      if [[ -n "$VISIBILITY" && "$VISIBILITY" != "$vis" ]]; then continue; fi
      matching_files=$(grep -ril "$QUERY" "$dir"/*.md 2>/dev/null | xargs -I{} basename {} || true)
      for fname in $matching_files; do
        # Match on basename AND visibility — basename alone can hit the wrong
        # row once the same filename exists in both stores.
        row=$(awk -F'\t' -v f="$fname" -v v="$vis" '$8 == f && $9 == v' "$INDEX" || true)
        if [[ -z "$row" ]]; then continue; fi
        if [[ -n "$STATUS" ]]; then
          echo "$row" | awk -F'\t' -v s="$STATUS" '$2 == s' || true
        else
          echo "$row"
        fi
      done
    done | sort -u || true
  )
  # Fall through to the shared formatter rather than dumping raw TSV — this path
  # was unreachable until the `|| true` fix above, so its output had never been
  # compared against the normal one.
fi

[[ -z "$results" ]] && exit 0

# Output
# NOTE: use awk, not `read` with IFS=tab — bash's `read` collapses consecutive
# IFS-whitespace delimiters (tab counts as whitespace), which silently shifts
# columns whenever two adjacent fields (e.g. empty project + empty tags) are
# both empty. awk -F'\t' does not have this problem.
if [[ "$MODE" == "full" ]]; then
  # awk resolves the path and prefixes a one-char visibility marker. Deliberately
  # NOT `read -r ... file visibility` with IFS=tab — see the NOTE above; bash's
  # read collapses adjacent tabs and would shift the columns.
  echo "$results" | awk -F'\t' -v pub="$PUBLIC_DIR" -v priv="$PRIVATE_DIR" '{
    d = ($9 == "private") ? priv : pub
    printf "%s%s/%s\n", ($9 == "private" ? "P" : "-"), d, $8
  }' | while IFS= read -r line; do
    marker="${line:0:1}"
    path="${line:1}"
    [[ -f "$path" ]] || continue
    [[ "$marker" == "P" ]] && echo "<!-- PRIVATE KB ENTRY — do not paste into public or external content -->"
    cat "$path"
    echo ""
  done
elif [[ "$MODE" == "medium" ]]; then
  # Medium: date | slug | [tags] | description   ("*" prefix marks private)
  echo "$results" | awk -F'\t' '{
    slug=$8; sub(/\.md$/, "", slug)
    mark=($9 == "private") ? "*" : " "
    printf "%s%s | %s | [%s]\n  %s\n", mark, $1, slug, $4, $7
  }'
else
  # Brief: date | slug | [tags] | description   ("*" prefix marks private)
  echo "$results" | awk -F'\t' '{
    slug=$8; sub(/\.md$/, "", slug)
    mark=($9 == "private") ? "*" : " "
    printf "%s%s | %s | [%s] | %s\n", mark, $1, slug, $4, $7
  }'
fi
