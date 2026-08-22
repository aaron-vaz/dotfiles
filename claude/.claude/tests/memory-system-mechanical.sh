#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== T1: --type filter correctness ==="
FB_TMP=$(mktemp)
~/.claude/kb/search-kb.sh --type feedback --brief > "$FB_TMP" 2>&1
FB_RC=$?
FB=$(wc -l < "$FB_TMP" | tr -d ' ')
EXPECTED_FB=$(grep -l '^type: feedback$' ~/.claude/kb/entries/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$FB_RC" -ne 0 ]]; then
  bad "T1a: search-kb.sh --type feedback --brief crashed (rc=$FB_RC): $(cat "$FB_TMP")"
elif [[ "$FB" -eq "$EXPECTED_FB" ]]; then
  ok "T1a: --type feedback count matches frontmatter count ($FB)"
else
  bad "T1a: expected $EXPECTED_FB (from frontmatter), got $FB"
fi
rm -f "$FB_TMP"

PRJ_TMP=$(mktemp)
~/.claude/kb/search-kb.sh --type project --brief > "$PRJ_TMP" 2>&1
PRJ_RC=$?
PRJ=$(wc -l < "$PRJ_TMP" | tr -d ' ')
EXPECTED_PRJ=$(grep -l '^type: project$' ~/.claude/kb/entries/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$PRJ_RC" -ne 0 ]]; then
  bad "T1b: search-kb.sh --type project --brief crashed (rc=$PRJ_RC): $(cat "$PRJ_TMP")"
elif [[ "$PRJ" -eq "$EXPECTED_PRJ" ]]; then
  ok "T1b: --type project count matches frontmatter count ($PRJ)"
else
  bad "T1b: expected $EXPECTED_PRJ (from frontmatter), got $PRJ"
fi
rm -f "$PRJ_TMP"

echo ""
echo "=== T2: discovery symlinks are live ==="
NEWDIR=~/Code/_verify-discovery-test-$$
mkdir -p "$NEWDIR"
if ls ~/.claude/_index/code | grep -q "$(basename "$NEWDIR")"; then
  ok "T2: new dir under ~/Code instantly visible via _index/code — zero doc edits needed"
else
  bad "T2: new dir not visible through discovery symlink"
fi
rmdir "$NEWDIR"

echo ""
echo "=== T3: auto-memory two-store drift check ==="
DRIFT=$(find ~/.claude/projects -path '*/memory/*.md' 2>/dev/null)
if [[ -z "$DRIFT" ]]; then
  ok "T3: no files inside any */memory/ dir — auto-memory still inert, no two-store drift"
else
  bad "T3: found files: $DRIFT"
fi

echo ""
echo "=== T4: cross-links in feedback entries resolve ==="
DANGLING=0
for f in ~/.claude/kb/entries/never-guess-identifiers.md ~/.claude/kb/entries/never-assume-library-versions.md; do
  [[ -f "$f" ]] || continue
  links=$(grep -o '\[\[[a-z-]*\]\]' "$f" | tr -d '[]')
  for l in $links; do
    [[ -f "$HOME/.claude/kb/entries/${l}.md" ]] || { echo "  dangling: $l (from $(basename "$f"))"; DANGLING=$((DANGLING+1)); }
  done
done
[[ "$DANGLING" -eq 0 ]] && ok "T4: all Related: [[wikilinks]] in feedback entries resolve to real files" || bad "T4: $DANGLING dangling link(s)"

echo ""
echo "=== T5: --list-tags still works (no regression) ==="
TAGCOUNT=$(~/.claude/kb/search-kb.sh --list-tags | wc -l | tr -d ' ')
[[ "$TAGCOUNT" -gt 5 ]] && ok "T5: --list-tags returns tag set ($TAGCOUNT tags)" || bad "T5: only $TAGCOUNT tags"

echo ""
echo "=== T6: feedback entries have Why/How to apply ==="
MISSING_SCHEMA=0
for f in ~/.claude/kb/entries/never-guess-identifiers.md ~/.claude/kb/entries/never-assume-library-versions.md; do
  [[ -f "$f" ]] || continue
  if ! grep -q "^\*\*Why:\*\*" "$f"; then
    echo "  missing Why: in $(basename "$f")"
    MISSING_SCHEMA=$((MISSING_SCHEMA+1))
  fi
  if ! grep -q "^\*\*How to apply:\*\*" "$f"; then
    echo "  missing How to apply: in $(basename "$f")"
    MISSING_SCHEMA=$((MISSING_SCHEMA+1))
  fi
done
[[ "$MISSING_SCHEMA" -eq 0 ]] && ok "T6: all feedback entries have Why/How to apply schema" || bad "T6: $MISSING_SCHEMA missing schema element(s)"

echo ""
echo "=== T7: retrieval-trigger — domain-rules tag surfaces feedback entries ==="
DR_TMP=$(mktemp)
~/.claude/kb/search-kb.sh --type feedback --tag domain-rules --brief > "$DR_TMP" 2>&1
DR_RC=$?
DR=$(wc -l < "$DR_TMP" | tr -d ' ')
EXPECTED_DR=$(grep -l '^type: feedback$' ~/.claude/kb/entries/*.md 2>/dev/null | xargs grep -l 'domain-rules' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$DR_RC" -ne 0 ]]; then
  bad "T7: search-kb.sh --type feedback --tag domain-rules --brief crashed (rc=$DR_RC): $(cat "$DR_TMP")"
elif [[ "$DR" -eq "$EXPECTED_DR" ]]; then
  ok "T7: domain-rules query surfaces all $DR feedback entries"
else
  bad "T7: expected $EXPECTED_DR, got $DR"
fi
rm -f "$DR_TMP"

echo ""
echo "=================================="
echo "RESULT: $PASS passed, $FAIL failed"
echo "=================================="
exit $FAIL
