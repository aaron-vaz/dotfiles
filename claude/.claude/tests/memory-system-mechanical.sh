#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# The KB has two stores since 2026-08-22: entries/ (public, may be tracked in the
# public dotfiles repo) and private/ (never tracked). search-kb.sh reads both by
# default, so every expectation derived from raw files must scan both — counting
# only entries/ made T1/T7 disagree with the tool rather than with reality.
KB_STORES=("$HOME/.claude/kb/entries" "$HOME/.claude/kb/private")

# Files across both stores matching a frontmatter grep. Prints one path per line.
kb_files_matching() {
  local pattern="$1" d
  for d in "${KB_STORES[@]}"; do
    [[ -d "$d" ]] || continue
    grep -l "$pattern" "$d"/*.md 2>/dev/null || true
  done
}

# Resolve an entry slug to a path in whichever store holds it.
kb_entry_path() {
  local slug="$1" d
  for d in "${KB_STORES[@]}"; do
    [[ -f "$d/$slug.md" ]] && { echo "$d/$slug.md"; return 0; }
  done
  return 1
}

echo "=== T1: --type filter correctness ==="
FB_TMP=$(mktemp)
~/.claude/kb/search-kb.sh --type feedback --brief > "$FB_TMP" 2>&1
FB_RC=$?
FB=$(wc -l < "$FB_TMP" | tr -d ' ')
EXPECTED_FB=$(kb_files_matching '^type: feedback$' | wc -l | tr -d ' ')
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
EXPECTED_PRJ=$(kb_files_matching '^type: project$' | wc -l | tr -d ' ')
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
for slug in never-guess-identifiers never-assume-library-versions; do
  f=$(kb_entry_path "$slug") || continue
  [[ -f "$f" ]] || continue
  links=$(grep -o '\[\[[a-z-]*\]\]' "$f" | tr -d '[]')
  for l in $links; do
    kb_entry_path "$l" >/dev/null || { echo "  dangling: $l (from $(basename "$f"))"; DANGLING=$((DANGLING+1)); }
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
for slug in never-guess-identifiers never-assume-library-versions; do
  f=$(kb_entry_path "$slug") || continue
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
EXPECTED_DR=$(kb_files_matching '^type: feedback$' | xargs grep -l 'domain-rules' 2>/dev/null | wc -l | tr -d ' ')
if [[ "$DR_RC" -ne 0 ]]; then
  bad "T7: search-kb.sh --type feedback --tag domain-rules --brief crashed (rc=$DR_RC): $(cat "$DR_TMP")"
elif [[ "$DR" -eq "$EXPECTED_DR" ]]; then
  ok "T7: domain-rules query surfaces all $DR feedback entries"
else
  bad "T7: expected $EXPECTED_DR, got $DR"
fi
rm -f "$DR_TMP"

echo ""
echo "=== T8: public/private KB split holds ==="
# The whole point of the split: the public store is the one that may end up
# tracked in a PUBLIC repo, so nothing employer- or private-product-specific may
# sit in it, and the private store must never become reachable from the repo.
PUB="$HOME/.claude/kb/entries"
PRIV="$HOME/.claude/kb/private"

if [[ -d "$PRIV" ]] && [[ ! -L "$PRIV" ]]; then
  ok "T8a: private store exists and is a real dir, not a symlink into a repo"
else
  bad "T8a: $PRIV missing, or is a symlink (it must never point into a tracked repo)"
fi

# Default search must include private — excluding it by default recreates the
# exact failure mode the split was made to prevent (knowledge search can't see).
BOTH=$(~/.claude/kb/search-kb.sh --all --brief 2>/dev/null | wc -l | tr -d ' ')
PUBONLY=$(~/.claude/kb/search-kb.sh --all --no-private --brief 2>/dev/null | wc -l | tr -d ' ')
PRIVONLY=$(~/.claude/kb/search-kb.sh --all --only-private --brief 2>/dev/null | wc -l | tr -d ' ')
if [[ "$BOTH" -eq $((PUBONLY + PRIVONLY)) ]] && [[ "$BOTH" -gt 0 ]]; then
  ok "T8b: default search covers both stores ($PUBONLY public + $PRIVONLY private = $BOTH)"
else
  bad "T8b: default=$BOTH but public=$PUBONLY + private=$PRIVONLY"
fi

# Private rows must be visually marked, or private content can be copied outward
# without anyone noticing what it was.
if [[ "$PRIVONLY" -eq 0 ]] || ~/.claude/kb/search-kb.sh --all --only-private --brief 2>/dev/null | grep -q '^\*'; then
  ok "T8c: private rows are marked with a leading * in brief output"
else
  bad "T8c: private rows are not marked — they are indistinguishable from public ones"
fi

# Index staleness must survive a DELETE, not just an add/edit. `-newer` alone
# only ever sees additions and modifications, so a removed or moved entry left
# its row in the index forever — search kept returning a file that no longer
# existed. `find -L` matters too: entries/ is a symlink into the dotfiles repo,
# and plain `find` does not follow a symlinked start point.
PROBE="$PUB/zz-staleness-probe.md"
printf -- '---\nname: zz-staleness-probe\ndate: 2026-01-01\ndescription: probe\ntype: reference\ntags: [probe]\nstatus: active\n---\nbody\n' > "$PROBE"
AFTER_ADD=$(~/.claude/kb/search-kb.sh --all --tag probe --brief 2>/dev/null | wc -l | tr -d ' ')
rm -f "$PROBE"
AFTER_DEL=$(~/.claude/kb/search-kb.sh --all --tag probe --brief 2>/dev/null | wc -l | tr -d ' ')
if [[ "$AFTER_ADD" -eq 1 ]] && [[ "$AFTER_DEL" -eq 0 ]]; then
  ok "T8e: index picks up an added entry through the symlink and drops a deleted one"
else
  bad "T8e: add saw $AFTER_ADD (want 1), delete saw $AFTER_DEL (want 0) — index is not self-healing"
fi

# Nothing naming the employer may sit in the public store.
LEAK=$(grep -rilE 'REDACTED|REDACTED|REDACTED|REDACTED|@REDACTEDgroup' "$PUB" 2>/dev/null || true)
if [[ -z "$LEAK" ]]; then
  ok "T8d: no employer references in the public KB store"
else
  bad "T8d: employer references in public store: $LEAK"
fi

echo ""
echo "=================================="
echo "RESULT: $PASS passed, $FAIL failed"
echo "=================================="
exit $FAIL
