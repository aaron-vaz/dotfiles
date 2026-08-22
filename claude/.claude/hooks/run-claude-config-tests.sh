#!/usr/bin/env bash
# PreToolUse(Bash) gate: before any `git commit` that stages Claude-config
# changes, run every mechanical test in ~/.claude/tests/*.sh. Blocks the commit
# (permissionDecision: deny) if any test script exits non-zero. Cheap no-op for
# commits in other repos or non-commit commands.
#
# Home layout note: ~/.claude is a real directory of symlinks into the dotfiles
# repo (claude/.claude/...), not a git repo of its own — so the gate is "the
# commit stages something under claude/.claude/", not "cwd is ~/.claude".
set +e

CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null)"
[[ -z "$CMD" ]] && exit 0
echo "$CMD" | grep -qE '(^|;|&&|\|\|)\s*git commit' || exit 0

STAGED="$(git diff --cached --name-only 2>/dev/null)"
echo "$STAGED" | grep -q '^claude/\.claude/' || exit 0

TESTS_DIR="${CLAUDE_CONFIG_TESTS_DIR:-$HOME/.claude/tests}"
[[ -d "$TESTS_DIR" ]] || exit 0

FAILURES=()
OUTPUT_FILE="$(mktemp)"
for test_script in "$TESTS_DIR"/*.sh; do
  [[ -f "$test_script" ]] || continue
  if ! bash "$test_script" >"$OUTPUT_FILE" 2>&1; then
    FAILURES+=("$(basename "$test_script")")
    echo "=== FAILED: $test_script ===" >&2
    cat "$OUTPUT_FILE" >&2
  fi
done
rm -f "$OUTPUT_FILE"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  REASON="~/.claude config tests failed before commit: ${FAILURES[*]}. Fix or investigate before committing (see stderr above for output)."
  jq -n --arg reason "$REASON" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
fi

exit 0
