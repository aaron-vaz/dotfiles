#!/usr/bin/env bash
# Mechanical tests for block-session-urls.sh (PreToolUse Bash): a git commit, tag, notes or merge,
# or a gh write, whose text carries a claude.ai session URL or a Claude-Session trailer is denied.
# The harness's own attribution instructions add them, so this must not depend on the exact shape
# of the git command. Payload: {"tool_name":"Bash","tool_input":{"command":"..."},"cwd":"..."} on stdin.
set -uo pipefail
PASS=0; FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

HOOKS_DIR="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"
HOOK="$HOOKS_DIR/block-session-urls.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

URL='https://claude.ai/code/session_abc123'

run_hook() {
  jq -n --arg c "$1" --arg d "${2:-$WORK}" '{tool_name:"Bash",tool_input:{command:$c},cwd:$d}' | bash "$HOOK"
}
denied() { [[ "$(run_hook "$@" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" == "deny" ]]; }

echo "=== T1: denies a session URL or trailer in any form of git commit / tag / notes / merge ==="
DENY=(
  "git commit -m \"feat: x

Claude-Session: $URL\""
  'git commit -m "feat: x Claude-Session: s"'
  'git -C /repo commit -m "x Claude-Session: s"'
  'git -c user.name=a commit -m "x Claude-Session: s"'
  'git --no-pager commit -m "x Claude-Session: s"'
  'git --git-dir=/r/.git commit -m "x Claude-Session: s"'
  'git commit --amend -m "x Claude-Session: s"'
  'git add -A && git commit -m "x Claude-Session: s"'
  'cd /repo && git commit -m "x Claude-Session: s"'
  "git tag -a v1 -m \"release $URL\""
  "git notes add -m \"see $URL\""
  'git merge -m "x Claude-Session: s" topic'
  "git commit -m \"\$(cat <<'MSG'
feat: x

Claude-Session: $URL
MSG
)\""
)
for c in "${DENY[@]}"; do
  denied "$c" && ok "T1: denied: ${c%%$'\n'*}" || bad "T1: expected deny for: ${c%%$'\n'*}"
done

echo ""
echo "=== T2: denies a session URL in a gh write ==="
GH=(
  "gh pr create --title t --body \"see $URL\""
  "gh pr comment 1 --body \"$URL\""
  "gh issue create --title t --body \"Claude-Session: s\""
  "gh api repos/o/r/issues/1/comments -f body=\"$URL\""
  "gh release create v1 --notes \"$URL\""
)
for c in "${GH[@]}"; do
  denied "$c" && ok "T2: denied: $c" || bad "T2: expected deny for: $c"
done

echo ""
echo "=== T3: allows ordinary commands, and reading about session URLs ==="
ALLOW=(
  'git commit -m "feat: x

Co-Authored-By: Claude <noreply@anthropic.com>"'
  'git -c user.name=a commit -m "fix: y"'
  'git status'
  "git log --grep=\"Claude-Session:\" --oneline"
  "git log -S\"claude.ai/code/session\" --oneline"
  "git grep -n \"$URL\""
  "echo $URL"
  "grep -c 'claude.ai/code/session' notes.md"
  'gh pr view 1'
  'gh pr create --title t --body "plain description"'
)
for c in "${ALLOW[@]}"; do
  denied "$c" && bad "T3: false positive on: ${c%%$'\n'*}" || ok "T3: allowed: ${c%%$'\n'*}"
done

echo ""
echo "=== T4: looks inside files given with -F / --file / --body-file ==="
printf 'feat: x\n\nClaude-Session: %s\n' "$URL" > "$WORK/dirty.txt"
printf 'feat: x\n\nCo-Authored-By: Claude <noreply@anthropic.com>\n' > "$WORK/clean.txt"
denied "git commit -F $WORK/dirty.txt"      && ok "T4a: absolute -F file with a trailer"   || bad "T4a: expected deny"
denied "git commit --file=$WORK/dirty.txt"  && ok "T4b: --file= with a trailer"            || bad "T4b: expected deny"
denied "git commit -F dirty.txt"            && ok "T4c: relative -F file, resolved against the payload cwd" || bad "T4c: expected deny"
denied "gh pr create --body-file $WORK/dirty.txt" && ok "T4d: --body-file with a trailer"  || bad "T4d: expected deny"
denied "git commit -F $WORK/clean.txt"      && bad "T4e: false positive on a clean -F file" || ok "T4e: clean -F file allowed"
denied "git commit -F $WORK/missing.txt"    && bad "T4f: false positive on a missing file"  || ok "T4f: missing file allowed (git reports it)"

echo ""
echo "=== T5: deny reason is actionable ==="
REASON=$(run_hook 'git commit -m "x Claude-Session: s"' | jq -r '.hookSpecificOutput.permissionDecisionReason')
[[ "$REASON" == *"Co-Authored-By"* && "$REASON" == *"session"* ]] \
  && ok "T5a: reason names the cause and what to keep" || bad "T5a: unexpected reason: $REASON"

echo ""
echo "=== T6: survives bad input ==="
OUT=$(echo 'not json' | bash "$HOOK" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T6a: malformed stdin fails open" || bad "T6a: rc=$RC out=$OUT"
OUT=$(jq -n '{tool_name:"Bash",tool_input:{}}' | bash "$HOOK" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T6b: missing command fails open" || bad "T6b: rc=$RC out=$OUT"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
