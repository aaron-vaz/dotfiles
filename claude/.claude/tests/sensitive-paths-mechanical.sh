#!/usr/bin/env bash
# Mechanical tests for guard-sensitive-paths.sh (PreToolUse Bash). The Read(~/...)
# deny rules only cover Claude's file tools; this hook is the Bash-side guard.
# Payload shape: {"tool_name":"Bash","tool_input":{"command":"..."}} on stdin.
set -uo pipefail
PASS=0; FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

HOOKS_DIR="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"
HOOK="$HOOKS_DIR/guard-sensitive-paths.sh"

run_guard() {
  jq -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK"
}

denied()  { [[ "$(run_guard "$1" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" == "deny" ]]; }

echo "=== T1: denies commands naming protected paths ==="
CASES=(
  'cat ~/.ssh/id_ed25519'
  'cat $HOME/.ssh/config'
  'cat ${HOME}/.gnupg/pubring.kbx'
  "cat $HOME/.ssh/id_rsa"
  'cd ~ && cat .ssh/id_rsa'
  'tar czf /tmp/x.tgz ~/.gnupg'
  'ls ~/Library/Keychains'
  'cat ~/.npmrc'
  'cat ~/.pypirc'
  'cat ~/.netrc'
  'cat ~/.docker/config.json'
  'cat ~/.kube/config'
  'python3 -c "print(open(\"/x/.ssh/id_rsa\").read())"'
  'echo hi; cat "$HOME/.ssh/id_rsa"'
)
for c in "${CASES[@]}"; do
  denied "$c" && ok "T1: denied: $c" || bad "T1: expected deny for: $c"
done

echo ""
echo "=== T2: allows ordinary commands and project-level files ==="
ALLOW=(
  'git push origin master'
  'ssh -T git@github.com'
  'cat ./.npmrc'
  'cat project/.npmrc'
  'ls ~/Code'
  'echo "$HOME"'
  'cat ~/.kubeconfig-notes.md'
  'cat ~/.sshfoo'
  'grep -rn ssh README.md'
  "cat $HOME/Code/app/.npmrc"
  './gradlew test'
)
for c in "${ALLOW[@]}"; do
  denied "$c" && bad "T2: false positive on: $c" || ok "T2: allowed: $c"
done

echo ""
echo "=== T3: deny reason is actionable ==="
REASON=$(run_guard 'cat ~/.ssh/id_rsa' | jq -r '.hookSpecificOutput.permissionDecisionReason')
[[ "$REASON" == *"! prefix"* && "$REASON" == *"protected credential path"* ]] \
  && ok "T3a: reason names the cause and the ! escape" || bad "T3a: unexpected reason: $REASON"

echo ""
echo "=== T4: survives bad input ==="
OUT=$(echo 'not json' | bash "$HOOK" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T4a: malformed stdin fails open" || bad "T4a: rc=$RC out=$OUT"
OUT=$(echo '' | bash "$HOOK" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T4b: empty stdin fails open" || bad "T4b: rc=$RC out=$OUT"
OUT=$(jq -n '{tool_name:"Bash",tool_input:{}}' | bash "$HOOK" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T4c: missing command fails open" || bad "T4c: rc=$RC out=$OUT"

echo ""
echo "=== T5: HOME with regex metacharacters does not break matching ==="
ODD_HOME="/tmp/we.ird+home(x)"
OUT=$(jq -n --arg c "cat $ODD_HOME/.ssh/id_rsa" '{tool_name:"Bash",tool_input:{command:$c}}' | HOME="$ODD_HOME" bash "$HOOK")
[[ "$(echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" == "deny" ]] \
  && ok "T5a: metachar home still matched" || bad "T5a: expected deny, got: $OUT"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
