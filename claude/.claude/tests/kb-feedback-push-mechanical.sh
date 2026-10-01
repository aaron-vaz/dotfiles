#!/usr/bin/env bash
# Mechanical tests for kb-feedback-push.sh (PreToolUse). Pushes `type: feedback`
# KB entries for the file's language/topic into context, once per session+agent+tag.
# Fully isolated: TMPDIR and KB_SEARCH point into a temp dir (stub search script
# with canned lines and an invocation log), so neither the real KB nor the real
# dedupe state is touched.
set -uo pipefail
PASS=0; FAIL=0
ok()  { echo "PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

HOOKS_DIR="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"
HOOK="$HOOKS_DIR/kb-feedback-push.sh"

TMPROOT=$(mktemp -d)
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

export TMPDIR="$TMPROOT/tmp"
mkdir -p "$TMPDIR"
STUB_LOG="$TMPROOT/stub.log"
STUB="$TMPROOT/search-kb-stub.sh"
export STUB_LOG
export KB_SEARCH="$STUB"

# Mimics `search-kb.sh --type feedback --brief`: ignores everything but logs one
# line of args per invocation, and returns the FULL canned feedback listing (the
# hook must filter it by exact tag). Includes substring-trap (javascript) and
# quoted tags.
cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
echo "$*" >> "$STUB_LOG"
echo " 2026-09-23 | kotlin-fqn-rule | [kotlin, code-style] | Kotlin FQN rule."
echo "*2026-09-06 | kotlin-quoted-tag-rule | [\"kotlin\", \"spring-boot\"] | Quoted tag rule."
echo " 2026-09-06 | testing-kotlin-rule | [testing, kotlin] | Testing and kotlin rule."
echo " 2026-09-06 | testing-rule | [testing, junit] | Testing rule."
echo " 2026-09-01 | java-rule | [java, code-style] | Java rule."
echo " 2026-09-01 | javascript-rule | [javascript, node] | JS rule."
echo " 2026-09-01 | shell-rule | [shell] | Shell rule."
echo " 2026-09-01 | shell-scripts-rule | [shell-scripts] | Shell scripts rule."
echo " 2026-09-01 | gradle-rule | [gradle, build] | Gradle rule."
echo " 2026-09-01 | documentation-rule | [documentation] | Docs rule."
STUBEOF
chmod +x "$STUB"

run_hook() {  # session agent file
  local session="$1" agent="$2" file="$3"
  if [[ -z "$agent" ]]; then
    jq -n --arg s "$session" --arg f "$file" \
      '{session_id:$s,hook_event_name:"PreToolUse",tool_name:"Read",tool_input:{file_path:$f}}' | bash "$HOOK"
  else
    jq -n --arg s "$session" --arg a "$agent" --arg f "$file" \
      '{session_id:$s,agent_id:$a,hook_event_name:"PreToolUse",tool_name:"Read",tool_input:{file_path:$f}}' | bash "$HOOK"
  fi
}
invocations() { [[ -f "$STUB_LOG" ]] && wc -l < "$STUB_LOG" | tr -d ' ' || echo 0; }
ctx_of() { jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null; }

echo "=== T1: .kt Read emits valid PreToolUse JSON with the kotlin rules ==="
OUT=$(run_hook s1 a1 /x/Foo.kt); RC=$?
[[ $RC -eq 0 ]] && ok "T1a: exit 0" || bad "T1a: rc=$RC"
[[ "$(echo "$OUT" | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)" == "PreToolUse" ]] \
  && ok "T1b: hookEventName is PreToolUse" || bad "T1b: got: $OUT"
CTX=$(echo "$OUT" | ctx_of)
[[ "$CTX" == *"kotlin-fqn-rule"* && "$CTX" == *"Standing rules"* && "$CTX" == *"--full"* ]] \
  && ok "T1c: context has header and kotlin line" || bad "T1c: ctx=$CTX"
[[ "$CTX" == *"kotlin-quoted-tag-rule"* ]] \
  && ok "T1d: quoted tag matches exactly" || bad "T1d: quoted-tag line missing: $CTX"
[[ "$CTX" != *"testing-rule"* ]] && ok "T1e: non-test .kt does not pull testing" || bad "T1e: testing leaked: $CTX"

echo ""
echo "=== T2: same session+agent+file again is silent and never searches ==="
BEFORE=$(invocations)
OUT=$(run_hook s1 a1 /x/Foo.kt); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T2a: no output on repeat" || bad "T2a: rc=$RC out=$OUT"
OUT=$(run_hook s1 a1 /y/Other.kt)
[[ -z "$OUT" ]] && ok "T2b: another .kt file in same session+agent is silent" || bad "T2b: out=$OUT"
[[ "$(invocations)" == "$BEFORE" ]] && ok "T2c: stub not invoked on repeat" || bad "T2c: stub invoked ($BEFORE -> $(invocations))"

echo ""
echo "=== T3: different agent_id in the same session gets the rules again ==="
OUT=$(run_hook s1 a2 /x/Foo.kt)
[[ "$(echo "$OUT" | ctx_of)" == *"kotlin-fqn-rule"* ]] && ok "T3: subagent re-pushed" || bad "T3: out=$OUT"

echo ""
echo "=== T4: missing agent_id is the main thread, deduped separately ==="
OUT=$(run_hook s1 "" /x/Foo.kt)
[[ "$(echo "$OUT" | ctx_of)" == *"kotlin-fqn-rule"* ]] && ok "T4a: main thread emits" || bad "T4a: out=$OUT"
OUT=$(run_hook s1 "" /x/Foo.kt)
[[ -z "$OUT" ]] && ok "T4b: main thread deduped" || bad "T4b: out=$OUT"
OUT=$(run_hook s2 "" /x/Foo.kt)
[[ "$(echo "$OUT" | ctx_of)" == *"kotlin-fqn-rule"* ]] && ok "T4c: new session emits again" || bad "T4c: out=$OUT"

echo ""
echo "=== T5: test file gets language and testing tags ==="
OUT=$(run_hook s3 a1 /x/src/test/kotlin/FooTest.kt)
CTX=$(echo "$OUT" | ctx_of)
[[ "$CTX" == *"kotlin-fqn-rule"* && "$CTX" == *"testing-rule"* ]] \
  && ok "T5a: FooTest.kt -> kotlin + testing" || bad "T5a: ctx=$CTX"
[[ "$(echo "$CTX" | grep -c 'testing-kotlin-rule')" == "1" ]] \
  && ok "T5b: line appearing under two tags printed once" || bad "T5b: dup: $CTX"
for f in /x/foo.test.ts /x/foo.spec.ts /x/test_foo.py /x/foo_test.go /x/tests/whatever.sh; do
  OUT=$(run_hook s-testnames a1 "$f")
  [[ "$(echo "$OUT" | ctx_of)" == *"testing-rule"* ]] && ok "T5c: $f -> testing" || bad "T5c: $f got: $OUT"
  rm -rf "$TMPDIR"/claude-kb-feedback-push/s-testnames
done
OUT=$(run_hook s-nontest a1 /x/src/main/Latest.kt)
[[ "$(echo "$OUT" | ctx_of)" != *"testing-rule"* ]] && ok "T5d: Latest.kt is not a test file" || bad "T5d: out=$OUT"

echo ""
echo "=== T6: unmapped extension is silent and never searches ==="
BEFORE=$(invocations)
OUT=$(run_hook s4 a1 /x/notes.txt); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T6a: .txt silent" || bad "T6a: rc=$RC out=$OUT"
OUT=$(run_hook s4 a1 /x/README.md)
[[ -z "$OUT" ]] && ok "T6b: .md silent" || bad "T6b: out=$OUT"
[[ "$(invocations)" == "$BEFORE" ]] && ok "T6c: no search for unmapped files" || bad "T6c: stub invoked"

echo ""
echo "=== T7: bad input fails open ==="
for input in 'not json' '' '{}' '{"tool_input":{}}' '{"tool_input":"str"}'; do
  OUT=$(printf '%s' "$input" | bash "$HOOK" 2>&1); RC=$?
  [[ $RC -eq 0 && -z "$OUT" ]] && ok "T7: rc=0, silent for input: ${input:-<empty>}" || bad "T7: rc=$RC out=$OUT for: $input"
done
OUT=$(jq -n '{session_id:"s5",tool_input:{file_path:"/x/Foo.kt"}}' | KB_SEARCH="$TMPROOT/missing.sh" bash "$HOOK" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T7: missing search script fails open" || bad "T7: rc=$RC out=$OUT"
OUT=$(jq -n '{session_id:"s5",tool_input:{file_path:"/x/Foo.kt"}}' | KB_SEARCH=/usr/bin/false bash "$HOOK" 2>&1); RC=$?
[[ $RC -eq 0 && -z "$OUT" ]] && ok "T7: failing search script fails open" || bad "T7: rc=$RC out=$OUT"

echo ""
echo "=== T8: never emits a permissionDecision ==="
ALL=$( { run_hook s6 a1 /x/Foo.kt; run_hook s6 a1 /x/FooTest.kt; run_hook s6 a2 /x/a.java; } 2>&1)
[[ -n "$ALL" && "$ALL" != *permissionDecision* ]] && ok "T8: output has no permissionDecision" || bad "T8: $ALL"

echo ""
echo "=== T9: additionalContext stays under 10000 chars for huge results ==="
# A separate stub returns 500 long kotlin lines.
cat > "$TMPROOT/big-stub.sh" <<'BIGEOF'
#!/usr/bin/env bash
for i in $(seq 1 500); do
  echo " 2026-09-01 | big-rule-$i | [kotlin] | $(printf 'y%.0s' $(seq 1 150))"
done
BIGEOF
chmod +x "$TMPROOT/big-stub.sh"
OUT=$(jq -n '{session_id:"s7",agent_id:"a1",tool_input:{file_path:"/x/Foo.kt"}}' | KB_SEARCH="$TMPROOT/big-stub.sh" bash "$HOOK"); RC=$?
LEN=$(echo "$OUT" | ctx_of | wc -m | tr -d ' ')
[[ $RC -eq 0 && "$LEN" -gt 0 && "$LEN" -lt 10000 ]] && ok "T9a: context is $LEN chars (<10000)" || bad "T9a: rc=$RC len=$LEN"
CTX=$(echo "$OUT" | ctx_of)
[[ "$CTX" == *"(truncated"* ]] && ok "T9b: truncation noted" || bad "T9b: no truncation note"
LAST=$(echo "$CTX" | tail -2 | head -1)
[[ "$LAST" == *"big-rule-"*"yyyy" ]] && ok "T9c: cut on a line boundary" || bad "T9c: partial line: $LAST"

echo ""
echo "=== T10: substring tag collisions are filtered to exact matches ==="
OUT=$(run_hook s8 a1 /x/Foo.java)
CTX=$(echo "$OUT" | ctx_of)
[[ "$CTX" == *"java-rule"* ]] && ok "T10a: java line surfaces" || bad "T10a: ctx=$CTX"
[[ "$CTX" != *"javascript-rule"* ]] && ok "T10b: javascript line filtered out" || bad "T10b: leaked: $CTX"
OUT=$(run_hook s8 a1 /x/run.sh)
CTX=$(echo "$OUT" | ctx_of)
[[ "$CTX" == *"shell-rule"* && "$CTX" == *"shell-scripts-rule"* ]] \
  && ok "T10c: .sh -> shell and shell-scripts entries" || bad "T10c: ctx=$CTX"
[[ "$(echo "$CTX" | grep -c 'shell-scripts-rule')" == "1" ]] && ok "T10d: shell-scripts line not duplicated" || bad "T10d: dup: $CTX"

echo ""
echo "=== T11: empty search results are recorded as seen ==="
run_hook s9 a1 /x/foo.py >/dev/null
BEFORE=$(invocations)
OUT=$(run_hook s9 a1 /x/bar.py)
[[ -z "$OUT" && "$(invocations)" == "$BEFORE" ]] && ok "T11: empty tag not re-searched" || bad "T11: out=$OUT searched=$(( $(invocations) - BEFORE ))"

echo ""
echo "=== T12: build.gradle.kts -> kotlin + gradle ==="
OUT=$(run_hook s10 a1 /x/build.gradle.kts)
[[ "$(echo "$OUT" | ctx_of)" == *"kotlin-fqn-rule"* ]] && ok "T12a: kotlin pulled" || bad "T12a: out=$OUT"
[[ "$(echo "$OUT" | ctx_of)" == *"gradle-rule"* ]] && ok "T12b: gradle rule pulled" || bad "T12b: gradle rule missing: $OUT"

echo ""
echo "=== T13: parallel Reads in one session push exactly once ==="
BEFORE=$(invocations)
for i in 1 2 3 4 5 6; do
  run_hook par a1 /x/Foo.kt > "$TMPROOT/par.$i" &
done
wait
PUSHED=0
for i in 1 2 3 4 5 6; do [[ -s "$TMPROOT/par.$i" ]] && PUSHED=$((PUSHED+1)); done
[[ "$PUSHED" == "1" ]] && ok "T13a: exactly one of 6 parallel runs produced output" || bad "T13a: $PUSHED runs produced output"
[[ "$(( $(invocations) - BEFORE ))" == "1" ]] && ok "T13b: stub ran once" || bad "T13b: stub ran $(( $(invocations) - BEFORE ))x"

echo ""
echo "=== T14: file_path containing spaces ==="
OUT=$(run_hook s-space a1 "/x/My Project/Foo Test.kt")
CTX=$(echo "$OUT" | ctx_of)
[[ "$CTX" == *"kotlin-fqn-rule"* && "$CTX" == *"testing-rule"* ]] && ok "T14a: spaces in path -> kotlin + testing" || bad "T14a: out=$OUT"
OUT=$(run_hook s-space a1 "/x/My Project/Foo Test.kt")
[[ -z "$OUT" ]] && ok "T14b: repeat deduped" || bad "T14b: out=$OUT"

echo ""
echo "=== T15: traversal-style session_id and agent_id stay inside the state dir ==="
OUT=$(run_hook "../../x y" "../../../z" /x/Foo.kt)
[[ "$(echo "$OUT" | ctx_of)" == *"kotlin-fqn-rule"* ]] && ok "T15a: emits" || bad "T15a: out=$OUT"
OUT=$(run_hook "../../x y" "../../../z" /x/Foo.kt)
[[ -z "$OUT" ]] && ok "T15b: repeat deduped" || bad "T15b: out=$OUT"
[[ ! -e "$TMPROOT/x" && ! -e "$TMPROOT/x y" && ! -e "$TMPROOT/z" && ! -e "$TMPDIR/z" && ! -e "$TMPDIR/x y" ]] \
  && ok "T15c: nothing created outside the state dir" || bad "T15c: escaped: $(ls "$TMPROOT" "$TMPDIR")"
[[ -d "$TMPDIR/claude-kb-feedback-push/______x_y/_________z/kotlin" ]] \
  && ok "T15d: sanitized claim dir exists" || bad "T15d: $(find "$TMPDIR/claude-kb-feedback-push" -maxdepth 3 | tr '\n' ' ')"

echo ""
echo "=== T16: dash-prefixed agent_id is deduped on repeat ==="
OUT=$(run_hook s-dash "-q" /x/Foo.kt)
[[ "$(echo "$OUT" | ctx_of)" == *"kotlin-fqn-rule"* ]] && ok "T16a: emits" || bad "T16a: out=$OUT"
BEFORE=$(invocations)
OUT=$(run_hook s-dash "-q" /x/Foo.kt)
[[ -z "$OUT" && "$(invocations)" == "$BEFORE" ]] && ok "T16b: repeat silent, no search" || bad "T16b: out=$OUT"

echo ""
echo "=== T17: multi-tag file triggers exactly one search, without --tag ==="
BEFORE=$(invocations)
OUT=$(run_hook s-multi a1 /x/src/test/FooTest.kt)
[[ "$(( $(invocations) - BEFORE ))" == "1" ]] && ok "T17a: one search for kotlin + testing" || bad "T17a: $(( $(invocations) - BEFORE )) searches"
[[ "$(tail -1 "$STUB_LOG")" != *--tag* ]] && ok "T17b: no --tag passed" || bad "T17b: args: $(tail -1 "$STUB_LOG")"
CTX=$(echo "$OUT" | ctx_of)
[[ "$CTX" == *"for kotlin, testing"* ]] && ok "T17c: header names both tags" || bad "T17c: ctx=$CTX"
[[ "$CTX" != *"java-rule"* && "$CTX" != *"javascript-rule"* && "$CTX" != *"documentation-rule"* && "$CTX" != *"gradle-rule"* ]] \
  && ok "T17d: unrelated listing lines filtered out" || bad "T17d: leaked: $CTX"
BEFORE=$(invocations)
run_hook s-multi a1 /x/src/test/BarTest.kt >/dev/null
[[ "$(invocations)" == "$BEFORE" ]] && ok "T17e: fully-claimed multi-tag file never searches" || bad "T17e: searched"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
