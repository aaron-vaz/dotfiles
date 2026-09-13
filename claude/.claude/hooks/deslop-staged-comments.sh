#!/usr/bin/env bash
# Reports slop in the comment lines of a staged diff, at `git commit`.
#
# Exists because the rules alone did not work. The repo policy banning repeated rationale, the
# self-review slop step, and the global test-label rule were all written down and loaded, and all
# three were violated in one session — the gap was never the criteria, it was re-running the check
# after writing more. A hook cannot forget.
#
# Advisory: prints and exits 0. Blocking a commit over prose would be worse than the prose.

set -euo pipefail

# Tool input arrives as JSON on stdin. `|| true` matters under set -e — malformed or empty stdin
# makes jq exit non-zero, which would kill the script here (see pre-commit-review.sh).
CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null || true)"
CMD="${CMD:-${CLAUDE_BASH_COMMAND:-}}"

echo "$CMD" | grep -q "git commit" || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Added comment lines only, with their file, from the staged diff. `-U0` keeps context lines out, so
# an untouched comment near an edit is not reported as new writing.
DIFF="$(git diff --cached -U0 -- '*.kt' '*.kts' '*.java' '*.py' '*.ts' '*.tsx' '*.go' '*.rs' '*.sql' '*.sh' 2>/dev/null || true)"
[[ -n "$DIFF" ]] || exit 0

COMMENTS="$(
  printf '%s\n' "$DIFF" | awk '
    /^\+\+\+ b\// { file = substr($0, 7); next }
    # `*` catches block-comment interiors, which is most of the prose in a KDoc-heavy file.
    /^\+[[:space:]]*(\/\/|\*|#)/ {
      line = $0
      sub(/^\+[[:space:]]*(\/\/|\*|#)[[:space:]]*/, "", line)
      if (length(line) > 0) print file "\t" line
    }
  ' || true
)"
[[ -n "$COMMENTS" ]] || exit 0

FINDINGS=""

# 1. The same rationale in more than one file. Catches verbatim copies only — paraphrase defeats it,
#    which is why the output says so rather than implying a clean run means clean.
DUPES="$(
  printf '%s\n' "$COMMENTS" | awk -F'\t' '
    {
      file = $1
      n = split(tolower($2), w, /[^a-z0-9]+/)
      for (i = 1; i + 7 <= n; i++) {
        s = ""
        for (j = 0; j < 8; j++) s = s w[i+j] " "
        if (!(s SUBSEP file in seen)) { seen[s SUBSEP file] = 1; files[s] = files[s] " " file; count[s]++ }
      }
    }
    END { for (s in count) if (count[s] > 1) print "  \"" s "\"\n    in:" files[s] }
  ' | head -20 || true
)"
[[ -n "$DUPES" ]] && FINDINGS="$FINDINGS\nSame wording in more than one file — keep the rationale once, at the site that enforces it:\n$DUPES\n"

# 2. Cut-on-sight phrases. Deliberately short: only entries with near-zero false-positive rate in
#    technical writing. Load-bearing adverbs (silently, deliberately) are NOT here, on purpose.
PHRASES="$(
  printf '%s\n' "$COMMENTS" \
    | grep -inE "here's (the thing|why|what|the deal)|it turns out|let me be clear|the truth is|let that sink in|full stop\.|make no mistake|let's (break this down|unpack|dive in|explore)|it'?s worth noting|it bears mentioning|at its core|at the end of the day|in conclusion|to sum up|in summary|\b(leverage|utilize)\b|serves as|deep dive|\bdelve\b|\b(really|simply|actually|genuinely|literally)\b" \
    | head -12 || true
)"
[[ -n "$PHRASES" ]] && FINDINGS="$FINDINGS\nFiller or jargon:\n$(printf '%s\n' "$PHRASES" | sed 's/^/  /')\n"

# 3. Rotting citations, including the naked ordinal (`// 7.4 batch selection:`) that reads as prose
#    and survives a keyword grep.
CITES="$(
  printf '%s\n' "$COMMENTS" \
    | grep -inE "(design|tasks)\.md|\btask[[:space:]]+[0-9]|\bdecision[[:space:]]+[0-9]|[A-Z]{2,}-[0-9]+|^[^\t]*\t[0-9]+\.[0-9]+[[:space:]]" \
    | grep -vE "(TODO|FIXME)\(" | head -8 || true
)"
[[ -n "$CITES" ]] && FINDINGS="$FINDINGS\nCitations that rot — inline the reasoning, drop the pointer:\n$(printf '%s\n' "$CITES" | sed 's/^/  /')\n"

[[ -n "$FINDINGS" ]] || exit 0

printf '\n✍️  DESLOP — staged comment lines\n────────────────────────────────'
printf '%b' "$FINDINGS"
cat << 'EOF'
Judge each before acting; none of these are automatic deletions. Criteria: deslop skill.

Grep catches verbatim repetition only. Four reworded copies of one idea pass this check clean, so
a quiet run is not evidence the diff is clean — read the comments you added.
EOF

exit 0
