#!/usr/bin/env bash
# Mechanical tests for the delegation setup: enforce-delegation.sh (main thread
# must not edit code), subagent-track.sh (SubagentStart bookkeeping),
# subagent-statusline.js (subagentStatusLine renderer), and the agent
# definitions. Payload shapes were captured live on v2.1.285 (2026-09-30):
#   - PreToolUse carries agent_id/agent_type ONLY inside a subagent
#   - subagentStatusLine stdin: { columns, tasks: [{ id, status, label,
#     startTime(ms), model, contextWindowSize, tokenCount, tokenSamples }] }
set -uo pipefail
PASS=0; FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

HOOKS_DIR="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"
AGENTS_DIR="${CLAUDE_AGENTS_DIR:-$HOME/.claude/agents}"

TMPROOT=$(mktemp -d)
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

edit_payload() {
  local tool="$1" path="$2" agent_id="${3:-}"
  if [[ -n "$agent_id" ]]; then
    jq -n --arg t "$tool" --arg p "$path" --arg a "$agent_id" \
      '{hook_event_name:"PreToolUse",tool_name:$t,tool_input:{file_path:$p},agent_id:$a,agent_type:"implementer"}'
  else
    jq -n --arg t "$tool" --arg p "$path" \
      '{hook_event_name:"PreToolUse",tool_name:$t,tool_input:{file_path:$p}}'
  fi
}

run_enforce() { bash "$HOOKS_DIR/enforce-delegation.sh"; }

echo "=== T1: enforce-delegation.sh denies main-thread code edits ==="
OUT=$(edit_payload Edit "/Users/someone/Code/app/src/Main.kt" | run_enforce)
if [[ "$(echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" == "deny" ]] \
   && echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q "impl-orchestrator"; then
  ok "T1a: main-thread Edit on code path denied, reason names impl-orchestrator"
else
  bad "T1a: expected deny naming impl-orchestrator, got: $OUT"
fi
echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecisionReason' | grep -q "Bash file writes" \
  && ok "T1a2: reason forbids Bash-write workarounds" || bad "T1a2: reason must forbid Bash file-write workarounds"
OUT=$(edit_payload Write "/Users/someone/Code/app/README.md" | run_enforce)
[[ "$(echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" == "deny" ]] \
  && ok "T1b: main-thread Write denied" || bad "T1b: expected deny, got: $OUT"
OUT=$(jq -n '{tool_name:"NotebookEdit",tool_input:{notebook_path:"/Users/someone/Code/nb.ipynb"}}' | run_enforce)
[[ "$(echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" == "deny" ]] \
  && ok "T1c: main-thread NotebookEdit denied via notebook_path" || bad "T1c: expected deny, got: $OUT"

echo ""
echo "=== T2: enforce-delegation.sh allows subagents and exempt paths ==="
OUT=$(edit_payload Edit "/Users/someone/Code/app/src/Main.kt" "agent-abc123" | run_enforce)
[[ -z "$OUT" ]] && ok "T2a: subagent edit (agent_id present) allowed" || bad "T2a: expected silent allow, got: $OUT"
for p in "/Users/someone/.claude/agents/x.md" "$HOME/.agents/kb/private/x.md" "/tmp/scratch.txt" \
         "/private/var/folders/ab/cd/T/cc-XXXX/file.txt" "/Users/someone/dotfiles/claude/.claude/settings.json"; do
  OUT=$(edit_payload Write "$p" | run_enforce)
  [[ -z "$OUT" ]] && ok "T2b: exempt path allowed: $p" || bad "T2b: expected allow for $p, got: $OUT"
done
OUT=$(edit_payload Edit "/Users/someone/Code/app/src/Main.kt" | CC_MAIN_EDITS=1 run_enforce)
[[ -z "$OUT" ]] && ok "T2c: CC_MAIN_EDITS=1 bypass allowed" || bad "T2c: expected allow with bypass, got: $OUT"

echo ""
echo "=== T3: enforce-delegation.sh resolves symlinked config dirs ==="
# Must live outside every temp-dir exemption, else this proves nothing.
SYMROOT=$(mktemp -d "$HOME/.deleg-symlink-test.XXXXXX")
mkdir -p "$SYMROOT/real/.claude/agents"
ln -s "$SYMROOT/real/.claude/agents" "$SYMROOT/link-agents"
OUT=$(edit_payload Write "$SYMROOT/link-agents/new.md" | run_enforce)
[[ -z "$OUT" ]] && ok "T3a: path through symlink into .claude allowed" || bad "T3a: expected allow, got: $OUT"
OUT=$(edit_payload Write "$SYMROOT/plain/new.md" | run_enforce)
[[ "$(echo "$OUT" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" == "deny" ]] \
  && ok "T3b: non-.claude path in same dir still denied" || bad "T3b: expected deny, got: $OUT"
rm -rf "$SYMROOT"

echo ""
echo "=== T4: enforce-delegation.sh survives bad input ==="
OUT=$(echo 'not json' | run_enforce 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T4a: malformed stdin fails open" || bad "T4a: rc=$RC out=$OUT"
OUT=$(echo '' | run_enforce 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T4b: empty stdin fails open" || bad "T4b: rc=$RC out=$OUT"
OUT=$(jq -n '{tool_name:"Edit",tool_input:{}}' | run_enforce 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T4c: missing file_path fails open" || bad "T4c: rc=$RC out=$OUT"

echo ""
echo "=== T5: subagent-track.sh records agent_type by agent_id ==="
STATE_ROOT="$TMPROOT/claude-config"
jq -n '{hook_event_name:"SubagentStart",agent_id:"agent-abc123",agent_type:"impl-orchestrator"}' \
  | CLAUDE_CONFIG_DIR="$STATE_ROOT" bash "$HOOKS_DIR/subagent-track.sh"
[[ "$(cat "$STATE_ROOT/state/subagents/agent-abc123" 2>/dev/null)" == "impl-orchestrator" ]] \
  && ok "T5a: agent_type written" || bad "T5a: state file missing or wrong"
jq -n '{agent_id:"../../evil",agent_type:"x"}' | CLAUDE_CONFIG_DIR="$STATE_ROOT" bash "$HOOKS_DIR/subagent-track.sh"
[[ ! -e "$STATE_ROOT/evil" && ! -e "$TMPROOT/evil" ]] && ok "T5b: path-traversal agent_id rejected" || bad "T5b: traversal not rejected"
OUT=$(echo 'not json' | CLAUDE_CONFIG_DIR="$STATE_ROOT" bash "$HOOKS_DIR/subagent-track.sh" 2>&1); RC=$?
[[ $RC -eq 0 ]] && ok "T5c: malformed stdin does not crash" || bad "T5c: rc=$RC out=$OUT"

echo ""
echo "=== T6: subagent-statusline.js renders one JSON line per task ==="
NOW_MS=$(( ($(date +%s) - 95) * 1000 ))
STATUS_INPUT=$(jq -n --argjson start "$NOW_MS" '{
  columns: 60,
  tasks: [
    {id:"agent-abc123", type:"local_agent", status:"running",
     label:"Refactor the payment retry loop and add backoff tests for every provider",
     startTime:$start, model:"claude-haiku-4-5-20251001", contextWindowSize:200000,
     tokenCount:34259, tokenSamples:[0,31925,34079,34259], effort:"high"},
    {id:"agent-done", status:"completed", label:"finished thing", model:"claude-opus-5-5", tokenCount:0}
  ]}')
OUT=$(echo "$STATUS_INPUT" | CLAUDE_CONFIG_DIR="$STATE_ROOT" node "$HOOKS_DIR/subagent-statusline.js" 2>&1)
LINES=$(printf '%s\n' "$OUT" | grep -c .)
[[ "$LINES" -eq 2 ]] && ok "T6a: two tasks -> two lines" || bad "T6a: expected 2 lines, got $LINES: $OUT"
[[ "$(printf '%s\n' "$OUT" | head -1 | jq -r '.id' 2>/dev/null)" == "agent-abc123" ]] \
  && ok "T6b: line is valid JSON carrying the task id" || bad "T6b: bad JSON/id: $OUT"
ROW=$(printf '%s\n' "$OUT" | head -1 | jq -r '.content' 2>/dev/null)
PLAIN=$(printf '%s' "$ROW" | sed $'s/\x1b\\[[0-9;]*m//g')
printf '%s' "$PLAIN" | grep -q "impl-orchestrator" \
  && ok "T6c: agent type from SubagentStart state shown" \
  || { [[ "$PLAIN" == *haiku* ]] && bad "T6c: type missing (state is agent-abc123 -> impl-orchestrator): $PLAIN" || bad "T6c: unexpected row: $PLAIN"; }
[[ "$PLAIN" == *haiku-4-5* && "$PLAIN" == *17%* ]] \
  && ok "T6d: model tier and context % shown" || bad "T6d: expected haiku-4-5 and 17%: $PLAIN"
WIDTH=$(printf '%s' "$PLAIN" | python3 -c 'import sys; print(len(sys.stdin.read()))')
[[ "$WIDTH" -le 59 ]] && ok "T6e: row truncated to columns (visible width $WIDTH <= 59)" || bad "T6e: visible width $WIDTH exceeds 59: $PLAIN"

echo ""
echo "=== T7: subagent-statusline.js edge cases ==="
OUT=$(echo '{"columns":80,"tasks":[]}' | node "$HOOKS_DIR/subagent-statusline.js" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T7a: no tasks -> no output" || bad "T7a: rc=$RC out=$OUT"
OUT=$(echo 'not json' | node "$HOOKS_DIR/subagent-statusline.js" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T7b: malformed stdin -> silent, exit 0" || bad "T7b: rc=$RC out=$OUT"
OUT=$(echo '{"tasks":[{"id":"../../x","status":"running","label":"a"}]}' | CLAUDE_CONFIG_DIR="$STATE_ROOT" node "$HOOKS_DIR/subagent-statusline.js" 2>&1); RC=$?
[[ $RC -eq 0 ]] && ok "T7c: hostile id + no columns/model does not crash" || bad "T7c: rc=$RC out=$OUT"

echo ""
echo "=== T8: agent definitions are well-formed ==="
for agent in impl-orchestrator implementer quick-editor scout test-runner change-reviewer; do
  f="$AGENTS_DIR/$agent.md"
  if [[ ! -f "$f" ]]; then bad "T8: missing $f"; continue; fi
  name=$(awk '/^---$/{n++; next} n==1 && /^name:/{sub(/^name:[[:space:]]*/,""); print; exit}' "$f")
  model=$(awk '/^---$/{n++; next} n==1 && /^model:/{sub(/^model:[[:space:]]*/,""); print; exit}' "$f")
  [[ "$name" == "$agent" ]] && ok "T8a: $agent name matches filename" || bad "T8a: $agent name is '$name'"
  # haiku is excluded on purpose: auto mode does not support it.
  case "$model" in opus|sonnet|fable) ok "T8b: $agent uses an auto-mode-capable tier alias ($model)" ;; *) bad "T8b: $agent model '$model' must be opus|sonnet|fable (haiku lacks auto mode)" ;; esac
done
ORCH_TOOLS=$(awk '/^---$/{n++; next} n==1 && /^tools:/{print; exit}' "$AGENTS_DIR/impl-orchestrator.md")
[[ "$ORCH_TOOLS" == *Agent* && "$ORCH_TOOLS" != *Edit* && "$ORCH_TOOLS" != *Write* ]] \
  && ok "T8c: orchestrator can spawn but cannot edit" || bad "T8c: orchestrator tools wrong: $ORCH_TOOLS"
for worker in implementer quick-editor scout test-runner change-reviewer; do
  TOOLS=$(awk '/^---$/{n++; next} n==1 && /^tools:/{print; exit}' "$AGENTS_DIR/$worker.md")
  [[ -n "$TOOLS" && "$TOOLS" != *Agent* ]] && ok "T8d: $worker has explicit tools and no Agent (no runaway nesting)" || bad "T8d: $worker tools wrong: '$TOOLS'"
done

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
