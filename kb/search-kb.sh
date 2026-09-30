#!/usr/bin/env bash
# search-kb.sh — Search the Claude Code knowledge base
# Usage: search-kb.sh [--tag TAG] [--type TYPE] [--project NAME] [--status STATUS]
#                     [--brief|--medium|--full] [--section HEADING]
#                     [--no-private|--only-private] [QUERY]
#        search-kb.sh --usage
# TYPE is the frontmatter `type:` field — one of: user, preference, feedback, project, reference, knowledge.
# See ~/.agents/kb/TEMPLATE-feedback.md for the feedback/user/reference entry shape.
#
# Disclosure layers (cheapest first — escalate only when the layer above is not enough):
#   --brief    one line per entry: date | slug | [tags] | description   (default)
#   --medium   the brief line, then the entry's `## ` headings (indented two
#              spaces), then its file size in KB
#   --section  only the section(s) whose `## ` heading contains HEADING
#              (case-insensitive substring), from the heading line up to the next
#              `## ` or `# ` heading or EOF. Sub-headings (`###`) stay inside the
#              section. Every matched entry that has such a section is printed,
#              each preceded by a `=== slug ===` header line (and the private
#              banner for private entries); entries with no matching section are
#              skipped, and if none has one a note goes to stderr (exit 0). An
#              entry with several matching headings prints all of them.
#   --full     the whole file
#
# QUERY is split on whitespace; EVERY term must match (AND, any order,
# case-insensitive, literal — not a regex). Terms are matched against the index
# row (date, status, project, tags, name, type, description, file, visibility);
# entry files whose BODY contains every term are unioned in and ranked last.
# Ranking: per term, 2 if it is in the name, slug or description, else 1; sum,
# highest first, then newest first. Listings without a QUERY are newest first.
#
# Usage log: --full and --section append `timestamp<TAB>slug<TAB>visibility` per
# entry printed to $KB_ROOT/usage.log (override: KB_USAGE_LOG). Logging can never
# fail or alter a search. --brief/--medium never write it.
# --usage prints open counts per slug (most opened first), then the active
# entries that have never been opened.
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
USAGE_LOG="${KB_USAGE_LOG:-$KB_ROOT/usage.log}"

# Defaults
TAG=""
TYPE=""
PROJECT=""
STATUS="active"
MODE="brief"  # brief | medium | full
SECTION=""  # non-empty = print only the matching section(s); wins over MODE
VISIBILITY=""  # "" = both | public | private
REBUILD=false
LIST_TAGS=false
LIST_PROJECTS=false
USAGE=false
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
    --section)       SECTION="$2"; shift 2 ;;
    --usage)         USAGE=true; shift ;;
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
  # `|| true`: with no index yet, find exits non-zero on the missing -newer
  # reference, and under `set -e` that killed a first run on a fresh KB silently.
  newer_entries+="$(find -L "$dir" -name '*.md' -newer "$INDEX" 2>/dev/null || true)"
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

# Index rows (stdin) that pass the VISIBILITY/TAG/TYPE/PROJECT filters and the
# status given as $1 ("" = any). One awk pass, same predicates as ever; row order
# is preserved.
filter_rows() {
  awk -F'\t' -v s="$1" -v v="$VISIBILITY" -v t="$TAG" -v ty="$TYPE" -v p="$PROJECT" '
    (v == "" || $9 == v) &&
    (s == "" || $2 == s) &&
    (t == "" || index($4, t) > 0) &&
    (ty == "" || $6 == ty) &&
    (p == "" || tolower($3) ~ tolower(p) || tolower($5) ~ tolower(p) || tolower($7) ~ tolower(p))'
}

# Usage log — one `timestamp<TAB>slug<TAB>visibility` line per entry opened.
# Must never fail or alter a search, so every error is swallowed; the braces put
# the stderr redirect in force before the log redirect is attempted.
log_open() {
  { printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" >> "$USAGE_LOG"; } 2>/dev/null || true
}

if [[ "$USAGE" == true ]]; then
  echo "Open counts (most opened first):"
  if [[ -s "$USAGE_LOG" ]]; then
    awk -F'\t' 'NF >= 3 { c[$2 "\t" $3]++ } END { for (k in c) printf "%d\t%s\n", c[k], k }' "$USAGE_LOG" | \
      sort -t$'\t' -k1,1nr -k2,2 | \
      awk -F'\t' '{ printf "  %d  %s  (%s)\n", $1, $2, $3 }'
  else
    echo "  (none)"
  fi
  echo ""
  echo "Active entries never opened:"
  # \037-joined "slug<TAB>visibility" keys of everything that was ever opened.
  opened=""
  [[ -s "$USAGE_LOG" ]] && opened=$(awk -F'\t' 'NF >= 3 { print $2 "\t" $3 }' "$USAGE_LOG" | sort -u | tr '\n' '\037')
  # `opened` goes in via the environment, not `-v`: BSD awk processes escape
  # sequences in -v values, so a backslash in a slug would be mangled.
  unopened=$(tail -n +2 "$INDEX" | filter_rows "active" | sort -t$'\t' -k1,1 -r | \
    KB_OPENED="$opened" awk -F'\t' '
      BEGIN { n = split(ENVIRON["KB_OPENED"], o, "\037"); for (i = 1; i <= n; i++) seen[o[i]] = 1 }
      { slug = $8; sub(/\.md$/, "", slug) }
      !((slug "\t" $9) in seen) { printf "  %s  %s  (%s)\n", $1, slug, $9 }')
  if [[ -z "$unopened" ]]; then
    echo "  (none)"
  else
    echo "$unopened"
  fi
  exit 0
fi

# Query terms: whitespace-split, all must match. `read -a` does not glob.
# Only expand TERMS after checking its length — an empty array under `set -u`
# is an unbound-variable error on the bash 3.2 that macOS ships.
TERMS=()
[[ -n "$QUERY" ]] && read -r -a TERMS <<< "$QUERY"
[[ ${#TERMS[@]} -eq 0 ]] && QUERY=""

# Keys ("visibility/basename", one per line) of entry files whose text contains
# EVERY term. Narrows the file list one term at a time with grep -F (literal).
body_hit_keys() {
  local dir vis files term
  for dir in "$PUBLIC_DIR" "$PRIVATE_DIR"; do
    [[ -d "$dir" ]] || continue
    vis="public"
    [[ "$dir" == "$PRIVATE_DIR" ]] && vis="private"
    if [[ -n "$VISIBILITY" && "$VISIBILITY" != "$vis" ]]; then continue; fi
    # An empty dir leaves the literal glob, which grep simply fails to open.
    files=$(printf '%s\n' "$dir"/*.md)
    for term in "${TERMS[@]}"; do
      if [[ -z "$files" ]]; then break; fi
      files=$(printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 grep -Fli -- "$term" 2>/dev/null || true)
    done
    if [[ -n "$files" ]]; then
      printf '%s\n' "$files" | awk -v v="$vis" '{ n = split($0, p, "/"); print v "/" p[n] }'
    fi
  done
}

# Search: filter index
results=$(tail -n +2 "$INDEX" | filter_rows "$STATUS")

if [[ -n "$QUERY" ]]; then
  # The full-text pass ALWAYS runs: a body-only hit (every term in the file, but
  # not all in the index row) is unioned in at the bottom of the ranking. It used
  # to run only when the index had zero hits, so a query with one weak index
  # match hid every entry whose body was the real answer.
  # Matched on visibility AND basename — basename alone can hit the wrong row
  # once the same filename exists in both stores.
  body_keys=$(body_hit_keys | tr '\n' '\037')
  terms_joined=$(printf '%s\037' "${TERMS[@]}")
  # Score: per term 2 if it is in name/slug/description, else 1 (tags or any other
  # column); body-only rows score 0, below every index hit. `score<TAB>row`.
  # The terms and keys reach awk through the environment (ENVIRON), NOT `-v`: BSD
  # awk processes escape sequences in -v values, so a term like `\d` became `d`
  # (matching every row via ".md") and `C:\temp` became `C:<TAB>emp`, while the
  # body pass (grep -F) used the raw term and the two disagreed.
  results=$(echo "$results" | KB_TERMS="$terms_joined" KB_KEYS="$body_keys" awk -F'\t' '
    BEGIN {
      n = split(tolower(ENVIRON["KB_TERMS"]), raw, "\037")
      for (i = 1; i <= n; i++) if (raw[i] != "") T[++nt] = raw[i]
      n = split(ENVIRON["KB_KEYS"], k, "\037")
      for (i = 1; i <= n; i++) if (k[i] != "") body[k[i]] = 1
    }
    {
      row = tolower($0)
      slug = tolower($8); sub(/\.md$/, "", slug)
      name = tolower($5); desc = tolower($7)
      score = 0; hit = 1
      for (i = 1; i <= nt; i++) {
        if (index(row, T[i]) == 0) { hit = 0; break }
        score += (index(name, T[i]) || index(slug, T[i]) || index(desc, T[i])) ? 2 : 1
      }
      if (!hit) score = 0
      if (hit || (($9 "/" $8) in body)) printf "%d\t%s\n", score, $0
    }' | sort -t$'\t' -k1,1nr -k2,2r | cut -f2-)
else
  # Latest first — filenames are date-prefixed but index build order (filesystem glob)
  # is not guaranteed sorted, so sort explicitly on the date column.
  [[ -n "$results" ]] && results=$(echo "$results" | sort -t$'\t' -k1,1 -r)
fi

[[ -z "$results" ]] && exit 0

# Output
# NOTE: use awk, not `read` with IFS=tab — bash's `read` collapses consecutive
# IFS-whitespace delimiters (tab counts as whitespace), which silently shifts
# columns whenever two adjacent fields (e.g. empty project + empty tags) are
# both empty. awk -F'\t' does not have this problem.

# The brief line for the row in $0: date | slug | [tags] | description, with a
# leading "*" for private entries. Shared so --medium can never drift from it.
BRIEF_FN='function brief_line(  slug, mark) {
  slug=$8; sub(/\.md$/, "", slug)
  mark=($9 == "private") ? "*" : " "
  return sprintf("%s%s | %s | [%s] | %s", mark, $1, slug, $4, $7)
}'

# Result rows -> "<P|-><path>" lines, one per entry. The one-char marker says
# whether the entry is private.
row_paths() {
  awk -F'\t' -v pub="$PUBLIC_DIR" -v priv="$PRIVATE_DIR" '{
    d = ($9 == "private") ? priv : pub
    printf "%s%s/%s\n", ($9 == "private" ? "P" : "-"), d, $8
  }'
}

# Walk one entry body: frontmatter skipped, ``` fences respected so a `# comment`
# inside a code block is not taken for a heading.
#   $1=headings  print each `## ` heading line, indented two spaces
#   $1=section   print every `## ` section whose heading contains $2
#                (case-insensitive) up to the next `## `/`# ` heading or EOF
walk_entry() {
  # The heading arrives via ENVIRON, not `-v` (see the ranking awk above).
  KB_WANT="$2" awk -v mode="$1" '
    BEGIN { want = tolower(ENVIRON["KB_WANT"]) }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm == 1 { if ($0 == "---") fm = 0; next }
    /^```/ { fence = !fence }
    {
      if (mode == "headings") {
        if (!fence && $0 ~ /^## /) print "  " $0
        next
      }
      if (!fence && $0 ~ /^##? /) printing = ($0 ~ /^## / && index(tolower(substr($0, 4)), want) > 0)
      if (printing) print
    }' "$3"
}

if [[ -n "$SECTION" ]]; then
  # The loop runs in a pipeline subshell, so it reports "something printed" back
  # through a flag file (one line per entry) rather than a variable.
  flag=$(mktemp)
  # A pipeline that dies under set -e (e.g. SIGPIPE into `head`) would skip the rm
  # below and leak the flag file.
  trap 'rm -f "$flag"' EXIT
  echo "$results" | row_paths | while IFS= read -r line; do
    marker="${line:0:1}"
    path="${line:1}"
    [[ -f "$path" ]] || continue
    body=$(walk_entry section "$SECTION" "$path")
    [[ -n "$body" ]] || continue
    slug=$(basename "$path" .md)
    vis="public"
    [[ "$marker" == "P" ]] && vis="private"
    [[ "$marker" == "P" ]] && echo "<!-- PRIVATE KB ENTRY — do not paste into public or external content -->"
    echo "=== $slug ==="
    echo "$body"
    echo ""
    echo x >> "$flag"
    log_open "$slug" "$vis"
  done
  found=$(wc -l < "$flag" | tr -d ' ')
  rm -f "$flag"
  trap - EXIT
  [[ "$found" -gt 0 ]] || echo "No entry has a section matching '$SECTION'." >&2
elif [[ "$MODE" == "full" ]]; then
  # awk resolves the path and prefixes a one-char visibility marker. Deliberately
  # NOT `read -r ... file visibility` with IFS=tab — see the NOTE above; bash's
  # read collapses adjacent tabs and would shift the columns.
  echo "$results" | row_paths | while IFS= read -r line; do
    marker="${line:0:1}"
    path="${line:1}"
    [[ -f "$path" ]] || continue
    [[ "$marker" == "P" ]] && echo "<!-- PRIVATE KB ENTRY — do not paste into public or external content -->"
    cat "$path"
    echo ""
    if [[ "$marker" == "P" ]]; then log_open "$(basename "$path" .md)" "private"; else log_open "$(basename "$path" .md)" "public"; fi
  done
elif [[ "$MODE" == "medium" ]]; then
  # Medium: the exact brief line, then the `## ` headings, then the size in KB.
  # awk emits "<marker><path><TAB><brief line>"; the loop splits on the first tab
  # with parameter expansion, not `read` (see the NOTE above).
  echo "$results" | awk -F'\t' -v pub="$PUBLIC_DIR" -v priv="$PRIVATE_DIR" "$BRIEF_FN"'{
    d = ($9 == "private") ? priv : pub
    printf "%s%s/%s\t%s\n", ($9 == "private" ? "P" : "-"), d, $8, brief_line()
  }' | while IFS= read -r line; do
    path="${line%%$'\t'*}"
    path="${path:1}"
    echo "${line#*$'\t'}"
    [[ -f "$path" ]] || continue
    walk_entry headings "" "$path"
    wc -c < "$path" | awk '{ printf "  size: %.1f KB\n", $1 / 1024 }'
  done
else
  # Brief: date | slug | [tags] | description   ("*" prefix marks private)
  echo "$results" | awk -F'\t' "$BRIEF_FN"'{ print brief_line() }'
fi
