#!/usr/bin/env bash
# Mechanical test for search-kb.sh's disclosure layers, multi-word AND search,
# ranking, and usage log. Runs against a throwaway fixture KB: search-kb.sh
# derives KB_ROOT from its own directory, so the script is COPIED into a temp dir
# next to fixture entries/ and private/ dirs. Nothing here touches the real KB,
# its index.tsv, or its usage.log.
#
# Override the script under test with KB_SCRIPT=/path/to/search-kb.sh.
set -uo pipefail
PASS=0; FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

KB_SCRIPT="${KB_SCRIPT:-$HOME/.agents/kb/search-kb.sh}"

TMPROOT=$(mktemp -d)
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

# Env that would leak the real KB or usage log into the fixture run.
unset KB_PRIVATE_DIR KB_USAGE_LOG

KB="$TMPROOT/kb"
mkdir -p "$KB/entries" "$KB/private"
cp "$KB_SCRIPT" "$KB/search-kb.sh"
chmod +x "$KB/search-kb.sh"
LOG="$TMPROOT/usage.log"

kb() { KB_USAGE_LOG="$LOG" bash "$KB/search-kb.sh" "$@"; }

# entry <dir> <slug> <date> <status> <tags> <description> — body arrives on stdin.
entry() {
  local dir="$1" slug="$2" date="$3" status="$4" tags="$5" desc="$6"
  {
    printf -- '---\nname: "%s"\ndate: %s\ntype: reference\ntags: [%s]\nstatus: %s\ndescription: "%s"\n---\n' \
      "$slug" "$date" "$tags" "$status" "$desc"
    cat
  } > "$KB/$dir/$slug.md"
}

# alpha: both "kotlin" and "imports" sit in its index row.
entry entries alpha-imports-style 2026-01-10 active "kotlin, imports" "Kotlin imports must be explicit" <<'EOF'

## Context
Why this rule exists.

## Rules
Use explicit imports only.
```bash
# this comment must not end the Rules section
echo hi
```
### Sub-rule
Sub-heading text stays inside Rules.

## Wrap-up
Closing words.
EOF

# beta: "kotlin" in the index row, "imports" nowhere in the file, "zebra" only here.
entry entries beta-kotlin-zebra 2026-01-20 active "kotlin" "Kotlin zebra patterns" <<'EOF'

## Context
Nothing about the other word here, only zebra.
EOF

# gamma: the index row has neither term; the BODY has both. Newer than alpha, so
# a date-only sort would put it first.
entry entries gamma-build-notes 2026-03-01 active "gradle" "Gradle build notes" <<'EOF'

## Notes
Remember to write kotlin code with explicit imports.
EOF

# delta: private, active, never opened.
entry private delta-private-note 2026-02-01 active "kotlin, imports" "Private kotlin imports note" <<'EOF'

## Rules
Private rule text.

## Other
Private other text.
EOF

# epsilon: archived, so hidden by default and out of the never-opened list.
entry entries epsilon-archived 2025-12-01 archived "kotlin, imports" "Archived kotlin imports" <<'EOF'

## Old
Old text.
EOF

echo "=== T1: multi-word query is an AND, in either order ==="
AB=$(kb --brief kotlin imports | sort)
BA=$(kb --brief imports kotlin | sort)
if [[ -n "$AB" && "$AB" == "$BA" ]]; then
  ok "T1a: 'kotlin imports' and 'imports kotlin' return the same non-empty set"
else
  bad "T1a: sets differ or are empty. AB=[$AB] BA=[$BA]"
fi
if echo "$AB" | grep -q 'alpha-imports-style' && echo "$AB" | grep -q 'delta-private-note'; then
  ok "T1b: both index hits present (public and private)"
else
  bad "T1b: missing an index hit: $AB"
fi
if ! echo "$AB" | grep -q 'epsilon-archived'; then
  ok "T1c: archived entry excluded by default"
else
  bad "T1c: archived entry leaked into default results"
fi

echo ""
echo "=== T2: a term present in only one entry excludes the other ==="
ZEBRA=$(kb --brief kotlin zebra)
if echo "$ZEBRA" | grep -q 'beta-kotlin-zebra' && ! echo "$ZEBRA" | grep -q 'alpha-imports-style'; then
  ok "T2a: 'kotlin zebra' keeps beta, drops alpha (AND)"
else
  bad "T2a: unexpected result: $ZEBRA"
fi
NONE=$(kb --brief kotlin zebra imports)
if [[ -z "$NONE" ]]; then
  ok "T2b: a term no entry contains alongside others yields nothing"
else
  bad "T2b: expected empty, got: $NONE"
fi
LITERAL=$(kb --brief 'zebra.*patterns')
if [[ -z "$LITERAL" ]]; then
  ok "T2c: terms are literal strings, not regexes"
else
  bad "T2c: regex metacharacters were interpreted: $LITERAL"
fi

echo ""
echo "=== T3: body-only fallback hit ranks below an index hit ==="
RANKED=$(kb --brief kotlin imports | sed -n 's/^[* ][0-9-]* | \([^ ]*\) |.*/\1/p')
FIRST_GAMMA=$(echo "$RANKED" | grep -n '^gamma-build-notes$' | cut -d: -f1)
LAST_INDEX_HIT=$(echo "$RANKED" | grep -n -E '^(alpha-imports-style|delta-private-note)$' | tail -1 | cut -d: -f1)
if [[ -n "$FIRST_GAMMA" && -n "$LAST_INDEX_HIT" && "$FIRST_GAMMA" -gt "$LAST_INDEX_HIT" ]]; then
  ok "T3a: gamma (body-only, newest) is present and ranked after every index hit"
else
  bad "T3a: ranking wrong. order: $(echo "$RANKED" | tr '\n' ' ')"
fi
TOP=$(echo "$RANKED" | head -1)
if [[ "$TOP" == "delta-private-note" ]]; then
  ok "T3b: among equal scores the newer index hit leads"
else
  bad "T3b: expected delta-private-note first, got $TOP"
fi
# Name/slug/description weighs 2 per term, tags-only 1: a description hit beats a tag-only hit.
entry entries zeta-tag-only 2026-06-01 active "rankprobe" "Unrelated text" < /dev/null
entry entries eta-desc-hit 2026-01-01 active "misc" "rankprobe in the description" < /dev/null
RANK2=$(kb --brief rankprobe | sed -n 's/^[* ][0-9-]* | \([^ ]*\) |.*/\1/p' | head -1)
if [[ "$RANK2" == "eta-desc-hit" ]]; then
  ok "T3c: description hit (score 2) outranks a newer tag-only hit (score 1)"
else
  bad "T3c: expected eta-desc-hit first, got $RANK2"
fi
rm -f "$KB/entries/zeta-tag-only.md" "$KB/entries/eta-desc-hit.md"

echo ""
echo "=== T4: body-only hits still honour filters ==="
PRIV_ONLY=$(kb --brief --no-private kotlin imports)
if ! echo "$PRIV_ONLY" | grep -q 'delta-private-note'; then
  ok "T4a: --no-private excludes private index hits"
else
  bad "T4a: private entry leaked under --no-private"
fi
TAGGED=$(kb --brief --tag gradle kotlin imports)
if echo "$TAGGED" | grep -q 'gamma-build-notes' && [[ $(echo "$TAGGED" | wc -l | tr -d ' ') -eq 1 ]]; then
  ok "T4b: --tag filter applies to a body-only hit"
else
  bad "T4b: expected only gamma, got: $TAGGED"
fi
TAGGED_OUT=$(kb --brief --tag nosuchtag kotlin imports)
if [[ -z "$TAGGED_OUT" ]]; then
  ok "T4c: a tag that matches nothing filters out body-only hits too"
else
  bad "T4c: expected empty, got: $TAGGED_OUT"
fi

echo ""
echo "=== T5: --medium shows headings and size under the exact brief line ==="
BRIEF_LINE=$(kb --brief --tag imports alpha | head -1)
MEDIUM=$(kb --medium alpha-imports-style)
if [[ "$(echo "$MEDIUM" | head -1)" == "$BRIEF_LINE" ]]; then
  ok "T5a: first --medium line is identical to the --brief line"
else
  bad "T5a: medium first line [$(echo "$MEDIUM" | head -1)] != brief [$BRIEF_LINE]"
fi
if echo "$MEDIUM" | grep -qx '  ## Context' && echo "$MEDIUM" | grep -qx '  ## Rules' && echo "$MEDIUM" | grep -qx '  ## Wrap-up'; then
  ok "T5b: each ## heading is listed, indented two spaces"
else
  bad "T5b: headings missing: $MEDIUM"
fi
if ! echo "$MEDIUM" | grep -q 'this comment must not' && ! echo "$MEDIUM" | grep -qF '### Sub-rule'; then
  ok "T5c: code-fence content and ### sub-headings are not listed as headings"
else
  bad "T5c: listed a non-## heading: $MEDIUM"
fi
if echo "$MEDIUM" | grep -Eq '^  size: [0-9]+\.[0-9] KB$'; then
  ok "T5d: size line present"
else
  bad "T5d: no size line: $MEDIUM"
fi
PRIV_MED=$(kb --medium delta-private-note | head -1)
if [[ "${PRIV_MED:0:1}" == "*" ]]; then
  ok "T5e: private marker kept on the medium brief line"
else
  bad "T5e: missing * on private medium line: $PRIV_MED"
fi

echo ""
echo "=== T6: --section prints only the matching section ==="
SEC=$(kb --section rules alpha-imports-style)
if echo "$SEC" | grep -q '=== alpha-imports-style ===' \
   && echo "$SEC" | grep -q 'Use explicit imports only' \
   && echo "$SEC" | grep -q 'this comment must not end the Rules section' \
   && echo "$SEC" | grep -q 'Sub-heading text stays inside Rules'; then
  ok "T6a: section body (incl. fenced # comment and ### sub-section) printed under a slug header"
else
  bad "T6a: section output wrong: $SEC"
fi
if ! echo "$SEC" | grep -q 'Why this rule exists' && ! echo "$SEC" | grep -q 'Closing words'; then
  ok "T6b: neighbouring sections are not printed"
else
  bad "T6b: leaked a neighbouring section: $SEC"
fi
SEC_PRIV=$(kb --section 'OTHER' delta-private-note)
if echo "$SEC_PRIV" | grep -q 'PRIVATE KB ENTRY' && echo "$SEC_PRIV" | grep -q 'Private other text' && ! echo "$SEC_PRIV" | grep -q 'Private rule text'; then
  ok "T6c: case-insensitive match, private banner printed, only that section"
else
  bad "T6c: private section output wrong: $SEC_PRIV"
fi
SEC_MULTI=$(kb --section context --tag kotlin)
if echo "$SEC_MULTI" | grep -q '=== alpha-imports-style ===' && echo "$SEC_MULTI" | grep -q '=== beta-kotlin-zebra ==='; then
  ok "T6d: multiple matching entries each get a header"
else
  bad "T6d: expected alpha and beta headers: $SEC_MULTI"
fi
ERR=$(kb --section 'no such heading' alpha-imports-style 2>&1 >/dev/null)
RC=$?
OUT=$(kb --section 'no such heading' alpha-imports-style 2>/dev/null)
if [[ "$RC" -eq 0 && -n "$ERR" && -z "$OUT" ]]; then
  ok "T6e: no matching section -> note on stderr, empty stdout, exit 0"
else
  bad "T6e: rc=$RC stderr=[$ERR] stdout=[$OUT]"
fi

echo ""
echo "=== T7: usage log is written by --full/--section, never by --brief/--medium ==="
rm -f "$LOG"
kb --brief kotlin >/dev/null
kb --medium kotlin >/dev/null
if [[ ! -e "$LOG" ]]; then
  ok "T7a: --brief/--medium do not create usage.log"
else
  bad "T7a: usage.log written by a non-open mode: $(cat "$LOG")"
fi
kb --full alpha-imports-style >/dev/null
if [[ -f "$LOG" && "$(wc -l < "$LOG" | tr -d ' ')" -eq 1 ]] \
   && grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z	alpha-imports-style	public$' "$LOG"; then
  ok "T7b: --full appends 'timestamp<TAB>slug<TAB>visibility'"
else
  bad "T7b: bad log: $(cat "$LOG" 2>/dev/null)"
fi
kb --section rules delta-private-note >/dev/null
if grep -Eq '	delta-private-note	private$' "$LOG"; then
  ok "T7c: --section logs a private entry with visibility=private"
else
  bad "T7c: no private section line: $(cat "$LOG")"
fi
BEFORE=$(wc -l < "$LOG" | tr -d ' ')
kb --section 'no such heading' alpha-imports-style >/dev/null 2>&1
AFTER=$(wc -l < "$LOG" | tr -d ' ')
if [[ "$BEFORE" -eq "$AFTER" ]]; then
  ok "T7d: a --section that prints nothing logs nothing"
else
  bad "T7d: log grew from $BEFORE to $AFTER for an empty section"
fi
# Default location and failure isolation.
DEFAULT_LOG="$KB/usage.log"
env -u KB_USAGE_LOG bash "$KB/search-kb.sh" --full beta-kotlin-zebra >/dev/null
if [[ -f "$DEFAULT_LOG" ]] && grep -q 'beta-kotlin-zebra' "$DEFAULT_LOG"; then
  ok "T7e: default log location is usage.log next to the script"
else
  bad "T7e: default usage.log not written in the fixture KB root"
fi
UNWRITABLE_OUT=$(KB_USAGE_LOG="$TMPROOT/no-such-dir/usage.log" bash "$KB/search-kb.sh" --full alpha-imports-style 2>&1)
UNWRITABLE_RC=$?
if [[ "$UNWRITABLE_RC" -eq 0 ]] && echo "$UNWRITABLE_OUT" | grep -q 'Use explicit imports only' && ! echo "$UNWRITABLE_OUT" | grep -qi 'no such'; then
  ok "T7f: an unwritable usage log neither fails nor pollutes the output"
else
  bad "T7f: rc=$UNWRITABLE_RC output: $UNWRITABLE_OUT"
fi

echo ""
echo "=== T8: --usage lists counts and never-opened active entries ==="
rm -f "$LOG"
kb --full alpha-imports-style >/dev/null
kb --full alpha-imports-style >/dev/null
kb --full beta-kotlin-zebra >/dev/null
USAGE=$(kb --usage)
COUNTS=$(echo "$USAGE" | sed -n '/^Open counts/,/^Active entries never opened/p')
NEVER=$(echo "$USAGE" | sed -n '/^Active entries never opened/,$p')
if echo "$COUNTS" | sed -n '2p' | grep -Eq '^  2  alpha-imports-style  \(public\)$' \
   && echo "$COUNTS" | sed -n '3p' | grep -Eq '^  1  beta-kotlin-zebra  \(public\)$'; then
  ok "T8a: open counts listed most-opened first"
else
  bad "T8a: counts wrong: $COUNTS"
fi
if echo "$NEVER" | grep -q 'gamma-build-notes' && echo "$NEVER" | grep -q 'delta-private-note'; then
  ok "T8b: never-opened active entries listed (public and private)"
else
  bad "T8b: never-opened section wrong: $NEVER"
fi
if ! echo "$NEVER" | grep -q 'alpha-imports-style' && ! echo "$NEVER" | grep -q 'beta-kotlin-zebra'; then
  ok "T8c: opened entries are not in the never-opened list"
else
  bad "T8c: opened entry listed as never opened: $NEVER"
fi
if ! echo "$NEVER" | grep -q 'epsilon-archived'; then
  ok "T8d: archived entries are not in the never-opened list"
else
  bad "T8d: archived entry listed: $NEVER"
fi
rm -f "$LOG"
EMPTY_USAGE=$(kb --usage)
if echo "$EMPTY_USAGE" | grep -q '(none)' && echo "$EMPTY_USAGE" | grep -q 'alpha-imports-style'; then
  ok "T8e: with no log, counts say (none) and every active entry is never-opened"
else
  bad "T8e: no-log output wrong: $EMPTY_USAGE"
fi

echo ""
echo "=== T9: listings without a query stay newest-first ==="
ORDER=$(kb --brief --all | sed -n 's/^[* ][0-9-]* | \([^ ]*\) |.*/\1/p' | tr '\n' ' ')
EXPECT="gamma-build-notes delta-private-note beta-kotlin-zebra alpha-imports-style epsilon-archived "
if [[ "$ORDER" == "$EXPECT" ]]; then
  ok "T9: --all lists by date descending"
else
  bad "T9: got [$ORDER] want [$EXPECT]"
fi

echo ""
echo "=== T10: a fresh KB with no index.tsv works ==="
# Regression: `find -newer <missing index>` exits non-zero, and under set -e that
# used to kill a first run silently.
rm -f "$KB/index.tsv"
FRESH=$(kb --brief --all | wc -l | tr -d ' ')
if [[ "$FRESH" -eq 5 && -f "$KB/index.tsv" ]]; then
  ok "T10: first run builds the index and lists all 5 fixture entries"
else
  bad "T10: expected 5 rows and an index, got $FRESH rows"
fi

echo ""
echo "=== T11: backslashes in terms and headings are literal (awk -v would mangle them) ==="
# BSD awk processes escape sequences in -v values: a term `\d` became `d` (matching
# every row through the .md filename column) and `C:\temp` became `C:<TAB>emp`.
# The script passes them through ENVIRON instead. These entries are removed below.
entry entries theta-regex-note 2026-07-01 active "regex" 'Use \d for digits' < /dev/null
entry entries iota-path-index 2026-07-02 active "paths" 'Windows path C:\temp in the description' < /dev/null
entry entries kappa-path-body 2026-08-01 active "paths" "Body only note" <<'EOF'

## Notes
The scratch dir is C:\temp on that box.
EOF
entry entries lambda-backslash-section 2026-07-03 active "sections" "Section heading probe" <<'EOF'

## Path C:\tmp notes
Backslash section text.

## Other
Other section text.
EOF
BS_D=$(kb --brief --all '\d' | sed -n 's/^[* ][0-9-]* | \([^ ]*\) |.*/\1/p')
if [[ "$BS_D" == "theta-regex-note" ]]; then
  ok "T11a: query '\d' matches only the entry literally containing \d, not every .md row"
else
  bad "T11a: expected only theta-regex-note, got: $(echo "$BS_D" | tr '\n' ' ')"
fi
BS_PATH=$(kb --brief 'C:\temp' | sed -n 's/^[* ][0-9-]* | \([^ ]*\) |.*/\1/p' | tr '\n' ' ')
if [[ "$BS_PATH" == "iota-path-index kappa-path-body " ]]; then
  ok "T11b: description hit for 'C:\temp' ranks above a newer body-only hit"
else
  bad "T11b: expected [iota-path-index kappa-path-body ], got [$BS_PATH]"
fi
BS_SEC=$(kb --section 'C:\tmp' lambda-backslash-section)
if echo "$BS_SEC" | grep -q '=== lambda-backslash-section ===' \
   && echo "$BS_SEC" | grep -q 'Backslash section text' \
   && ! echo "$BS_SEC" | grep -q 'Other section text'; then
  ok "T11c: --section with a backslash heading matches literally"
else
  bad "T11c: section output wrong: $BS_SEC"
fi
BS_SEC_NONE=$(kb --section '\x' lambda-backslash-section 2>/dev/null)
if [[ -z "$BS_SEC_NONE" ]]; then
  ok "T11d: --section '\x' is literal, not an escape that matches other headings"
else
  bad "T11d: expected empty, got: $BS_SEC_NONE"
fi
rm -f "$KB/entries/theta-regex-note.md" "$KB/entries/iota-path-index.md" \
      "$KB/entries/kappa-path-body.md" "$KB/entries/lambda-backslash-section.md"

echo ""
echo "=================================="
echo "RESULT: $PASS passed, $FAIL failed"
echo "=================================="
exit $FAIL
