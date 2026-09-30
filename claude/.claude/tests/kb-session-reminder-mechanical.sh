#!/usr/bin/env bash
# Mechanical test for kb-session-reminder.sh.
#
# Two bugs this guards against:
#   1. entries/ is a symlink into the dotfiles repo and plain `find` does not
#      follow a symlinked start point, so the hook saw zero entries and warned
#      on every commit day.
#   2. New entries default to the private store (kb/private/), which the hook
#      never checked.
# All state comes from temp dirs via COMMAND_LOG / KB_ENTRIES_DIR / KB_PRIVATE_DIR.
set -uo pipefail
PASS=0; FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

HOOKS_DIR="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"
HOOK="$HOOKS_DIR/kb-session-reminder.sh"

TMPROOT=$(mktemp -d)
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

# Three days ago, portable across BSD (macOS) and GNU date.
OLD_STAMP=$(date -u -v-3d +%Y%m%d%H%M 2>/dev/null || date -u -d '3 days ago' +%Y%m%d%H%M)

TODAY=$(date -u +%Y-%m-%d)
COMMIT_LOG="$TMPROOT/commit-log.txt"
NO_COMMIT_LOG="$TMPROOT/no-commit-log.txt"
echo "${TODAY}T12:00:00Z: git commit -m x" > "$COMMIT_LOG"
echo "2020-01-01T12:00:00Z: git commit -m old" > "$NO_COMMIT_LOG"

# Fresh per-case store: real public dir reached through a symlink, plus a private dir.
new_case() {
  local name="$1"
  CASE="$TMPROOT/$name"
  mkdir -p "$CASE/real-entries" "$CASE/private"
  ln -s "$CASE/real-entries" "$CASE/entries"
}

# run_hook <command-log>; sets OUT and RC
run_hook() {
  OUT=$(COMMAND_LOG="$1" KB_ENTRIES_DIR="$CASE/entries" KB_PRIVATE_DIR="$CASE/private" bash "$HOOK" 2>&1)
  RC=$?
}

echo "=== T1: no commit today -> silent ==="
new_case t1
run_hook "$NO_COMMIT_LOG"
[[ "$RC" -eq 0 && -z "$OUT" ]] && ok "T1: silent, exit 0" || bad "T1: expected silence (rc=$RC): $OUT"

echo ""
echo "=== T2: commit today + fresh .md only in symlinked public dir -> silent ==="
new_case t2
touch "$CASE/real-entries/fresh.md"
run_hook "$COMMIT_LOG"
[[ "$RC" -eq 0 && -z "$OUT" ]] && ok "T2: symlinked public dir is followed, exit 0" || bad "T2: unexpected output (rc=$RC): $OUT"

echo ""
echo "=== T3: commit today + fresh .md only in private dir -> silent ==="
new_case t3
touch "$CASE/private/fresh.md"
run_hook "$COMMIT_LOG"
[[ "$RC" -eq 0 && -z "$OUT" ]] && ok "T3: private store counts, exit 0" || bad "T3: unexpected output (rc=$RC): $OUT"

echo ""
echo "=== T4: commit today + both stores stale -> warns ==="
new_case t4
touch -t "$OLD_STAMP" "$CASE/real-entries/old.md" "$CASE/private/old.md"
run_hook "$COMMIT_LOG"
if [[ "$RC" -eq 0 ]] && echo "$OUT" | grep -q "no KB entry created/updated" \
   && echo "$OUT" | grep -q "kb/private/" && echo "$OUT" | grep -q "kb/entries/"; then
  ok "T4: warns naming both stores, exit 0"
else
  bad "T4: expected warning naming both stores (rc=$RC): ${OUT:-<empty>}"
fi

echo ""
echo "=== T5: commit today + both stores empty -> warns ==="
new_case t5
run_hook "$COMMIT_LOG"
if [[ "$RC" -eq 0 ]] && echo "$OUT" | grep -q "no KB entry created/updated"; then
  ok "T5: warns on empty stores, exit 0"
else
  bad "T5: expected warning (rc=$RC): ${OUT:-<empty>}"
fi

echo ""
echo "=== T6: missing command log and missing dirs -> silent, exit 0 ==="
new_case t6
run_hook "$TMPROOT/does-not-exist.txt"
[[ "$RC" -eq 0 && -z "$OUT" ]] && ok "T6: exit 0, silent" || bad "T6: rc=$RC out: $OUT"

echo ""
echo "=================================="
echo "RESULT: $PASS passed, $FAIL failed"
echo "=================================="
exit $FAIL
