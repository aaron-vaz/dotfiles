#!/usr/bin/env bash
# Mechanical test for the hook stdin-contract bug (work hit this 2026-08-19,
# home was still carrying it on 2026-08-22).
#
# These hooks all read $CLAUDE_BASH_COMMAND / $CLAUDE_TOOL_INPUT /
# $CLAUDE_FILE_PATH — env vars this Claude Code version never sets. tool_input
# arrives as JSON on stdin instead. Verified 2026-08-22 by dumping the live hook
# environment on both PreToolUse:Bash and PostToolUse:Edit|Write: the payload is
# {"hook_event_name":..,"tool_name":..,"tool_input":{..},"cwd":..} on stdin, and
# the only CLAUDE_* env vars present are CLAUDE_PROJECT_DIR, CLAUDE_PID,
# CLAUDE_CODE_SESSION_ID, CLAUDE_EFFORT, CLAUDE_CODE_ENTRYPOINT, CLAUDECODE and
# the messaging-socket pair.
#
# The `set +e` hooks failed silently (looked healthy in /hooks, enforced
# nothing); pre-commit-review.sh hard-crashed under `set -euo pipefail` with
# "CLAUDE_BASH_COMMAND: unbound variable".
set -uo pipefail
PASS=0; FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

HOOKS_DIR="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"

TMPROOT=$(mktemp -d)
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

run_bash_hook() {
  local cmd="$1" hook="$2"
  printf '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":%s}}' \
    "$(jq -Rn --arg c "$cmd" '$c')" | bash "$hook"
}

run_file_hook() {
  local tool="$1" path="$2" hook="$3"
  printf '{"hook_event_name":"PostToolUse","tool_name":%s,"tool_input":{"file_path":%s}}' \
    "$(jq -Rn --arg t "$tool" '$t')" "$(jq -Rn --arg p "$path" '$p')" | bash "$hook"
}

echo "=== T1: validate-git-usage.sh fires on cd&&git via stdin ==="
OUT=$(run_bash_hook "cd /tmp && git status" "$HOOKS_DIR/validate-git-usage.sh")
RC=$?
if [[ "$RC" -eq 0 ]] && echo "$OUT" | grep -q "Git Usage Pattern Detected"; then
  ok "T1a: fires via stdin JSON"
else
  bad "T1a: expected advisory, got (rc=$RC): $OUT"
fi
OUT=$(echo 'not json' | bash "$HOOKS_DIR/validate-git-usage.sh" 2>&1)
[[ $? -eq 0 ]] && ok "T1b: malformed stdin does not crash" || bad "T1b: crashed on malformed stdin: $OUT"

echo ""
echo "=== T2: validate-test-scope.sh fires on gradle test via stdin ==="
OUT=$(run_bash_hook "./gradlew test" "$HOOKS_DIR/validate-test-scope.sh")
RC=$?
if [[ "$RC" -eq 0 ]] && echo "$OUT" | grep -q "Test Execution Checklist"; then
  ok "T2a: fires via stdin JSON"
else
  bad "T2a: expected checklist, got (rc=$RC): $OUT"
fi
OUT=$(echo 'not json' | bash "$HOOKS_DIR/validate-test-scope.sh" 2>&1)
[[ $? -eq 0 ]] && ok "T2b: malformed stdin does not crash" || bad "T2b: crashed on malformed stdin: $OUT"

echo ""
echo "=== T3: block-planning-commits.sh detects staged planning files via stdin ==="
REPO="$TMPROOT/planning"
mkdir -p "$REPO/.claude" && cd "$REPO"
git init -q
echo "x" > .claude/scratch.md
git add .claude/scratch.md
OUT=$(run_bash_hook "git commit -m test" "$HOOKS_DIR/block-planning-commits.sh")
RC=$?
if [[ "$RC" -eq 0 ]] && echo "$OUT" | grep -q "Planning files detected"; then
  ok "T3a: detects staged .claude/ file via stdin JSON"
else
  bad "T3a: expected planning-file warning, got (rc=$RC): $OUT"
fi
cd - >/dev/null
OUT=$(echo 'not json' | bash "$HOOKS_DIR/block-planning-commits.sh" 2>&1)
[[ $? -eq 0 ]] && ok "T3b: malformed stdin does not crash" || bad "T3b: crashed on malformed stdin: $OUT"

echo ""
echo "=== T4: pre-commit-review.sh survives stdin under set -euo pipefail ==="
# This is the one that used to hard-crash with "CLAUDE_BASH_COMMAND: unbound variable".
REPO2="$TMPROOT/substantial"
mkdir -p "$REPO2" && cd "$REPO2"
git init -q
seq 1 200 > big.txt
git add big.txt
OUT=$(run_bash_hook "git commit -m test" "$HOOKS_DIR/pre-commit-review.sh" 2>&1)
RC=$?
if [[ "$RC" -eq 0 ]] && echo "$OUT" | grep -q "SUBSTANTIAL CHANGES DETECTED"; then
  ok "T4a: fires via stdin JSON on a >50-line staged diff"
else
  bad "T4a: expected substantial-changes advisory, got (rc=$RC): $OUT"
fi
cd - >/dev/null
OUT=$(echo 'not json' | bash "$HOOKS_DIR/pre-commit-review.sh" 2>&1)
[[ $? -eq 0 ]] && ok "T4b: malformed stdin does not crash under set -e" || bad "T4b: crashed on malformed stdin: $OUT"

echo ""
echo "=== T5: PostToolUse hooks read tool_name/file_path from stdin ==="
OUT=$(run_file_hook "Write" "$TMPROOT/some/skill/SKILL.md" "$HOOKS_DIR/skill-md-review-reminder.sh")
RC=$?
if [[ "$RC" -eq 0 ]] && echo "$OUT" | grep -q "adversarial-review"; then
  ok "T5a: skill-md-review-reminder fires on a SKILL.md write"
else
  bad "T5a: expected adversarial-review reminder, got (rc=$RC): $OUT"
fi
OUT=$(run_file_hook "Write" "$TMPROOT/some/other.md" "$HOOKS_DIR/skill-md-review-reminder.sh")
[[ -z "$OUT" ]] && ok "T5b: silent on a non-SKILL.md file" || bad "T5b: fired on the wrong file: $OUT"

AUDIT_LOG_BEFORE=$({ wc -l < "$HOME/.claude/tool-audit.log"; } 2>/dev/null || echo 0)
printf '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"echo hook-contract-test"}}' \
  | bash "$HOOKS_DIR/log-tool-calls.sh"
AUDIT_LOG_AFTER=$({ wc -l < "$HOME/.claude/tool-audit.log"; } 2>/dev/null || echo 0)
if [[ "$AUDIT_LOG_AFTER" -gt "$AUDIT_LOG_BEFORE" ]]; then
  ok "T5c: log-tool-calls appends a Bash entry from stdin"
else
  bad "T5c: tool-audit.log did not grow ($AUDIT_LOG_BEFORE -> $AUDIT_LOG_AFTER)"
fi

echo ""
echo "=== T6: no hook still reads the stale env-var contract ==="
STALE=$(grep -ln 'CLAUDE_BASH_COMMAND\|CLAUDE_TOOL_INPUT\|CLAUDE_FILE_PATH\|CLAUDE_TOOL_NAME' "$HOOKS_DIR"/*.sh 2>/dev/null \
  | xargs -I{} sh -c 'grep -q "tool_input" "{}" || echo "{}"' 2>/dev/null)
if [[ -z "$STALE" ]]; then
  ok "T6: every hook referencing a stale env var also reads stdin JSON"
else
  bad "T6: these hooks read only the stale env-var contract: $STALE"
fi

echo ""
echo "=== T7: settings.json inline hooks resolve tool_input from stdin ==="
SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
if jq -e . "$SETTINGS" > /dev/null 2>&1; then
  ok "T7a: settings.json is valid JSON"
else
  bad "T7a: settings.json is malformed JSON"
fi
INLINE=$(jq -r '[.hooks[]?[]?.hooks[]? | select(.command != null) | .command] | .[]' "$SETTINGS" 2>/dev/null \
  | grep -E 'CLAUDE_TOOL_INPUT|CLAUDE_BASH_COMMAND|CLAUDE_FILE_PATH' \
  | grep -v 'tool_input')
if [[ -z "$INLINE" ]]; then
  ok "T7b: no inline settings.json hook relies solely on a stale env var"
else
  bad "T7b: inline hooks still on the stale contract: $INLINE"
fi

echo ""
echo "=== T8: run-claude-config-tests.sh gate fires from an unrelated cwd ==="
# Regression guard for the second instance of the same bug class: hooks run in
# the *session's* cwd, not the cwd of a `cd X && git commit` compound command,
# so a bare `git diff --cached` in the gate reads the wrong index and the gate
# silently never fires. It shipped that way and let two failing-test commits
# through. Run from an unrelated repo and assert it still resolves the config
# repo and denies when a test fails.
# Isolated: the gate resolves its config repo from its own file location, so a
# synthetic repo containing a copy of it exercises the real resolution logic
# without reading (or touching) the live index.
FAKE_CONFIG="$TMPROOT/fakeconfig"
mkdir -p "$FAKE_CONFIG/claude/.claude/hooks"
git -C "$FAKE_CONFIG" init -q
cp "$HOOKS_DIR/run-claude-config-tests.sh" "$FAKE_CONFIG/claude/.claude/hooks/"
GATE="$FAKE_CONFIG/claude/.claude/hooks/run-claude-config-tests.sh"

FAKE_TESTS="$TMPROOT/faketests"
mkdir -p "$FAKE_TESTS"
printf '#!/usr/bin/env bash\nexit 1\n' > "$FAKE_TESTS/always-fails.sh"
chmod +x "$FAKE_TESTS/always-fails.sh"

UNRELATED="$TMPROOT/unrelated"
mkdir -p "$UNRELATED" && git -C "$UNRELATED" init -q
cd "$UNRELATED"

# Nothing staged in the fake config repo yet — gate must stay silent.
OUT=$(printf '{"tool_input":{"command":"git commit -m x"}}' \
      | CLAUDE_CONFIG_TESTS_DIR="$FAKE_TESTS" bash "$GATE" 2>/dev/null)
[[ -z "$OUT" ]] && ok "T8a: silent when no config files are staged" \
                || bad "T8a: fired with nothing staged: $OUT"

# Stage a config file — gate must now run the (failing) tests and deny, despite
# cwd being an entirely different repo. This is the regression that shipped:
# a bare `git diff --cached` here reads $UNRELATED's index and matches nothing.
echo x > "$FAKE_CONFIG/claude/.claude/some-config.md"
git -C "$FAKE_CONFIG" add -A >/dev/null 2>&1
OUT=$(printf '{"tool_input":{"command":"git commit -m x"}}' \
      | CLAUDE_CONFIG_TESTS_DIR="$FAKE_TESTS" bash "$GATE" 2>/dev/null)
if echo "$OUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  ok "T8b: denies from an unrelated cwd when a config test fails"
else
  bad "T8b: gate did not deny — it is a no-op from a foreign cwd. Got: ${OUT:-<empty>}"
fi

# Non-commit commands stay free.
OUT=$(printf '{"tool_input":{"command":"git status"}}' \
      | CLAUDE_CONFIG_TESTS_DIR="$FAKE_TESTS" bash "$GATE" 2>/dev/null)
[[ -z "$OUT" ]] && ok "T8c: ignores non-commit git commands" \
                || bad "T8c: fired on git status: $OUT"
cd - >/dev/null

echo ""
echo "=================================="
echo "RESULT: $PASS passed, $FAIL failed"
echo "=================================="
exit $FAIL
