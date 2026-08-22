#!/usr/bin/env bash
# PreToolUse(Bash) gate: before any `git commit` while Claude-config changes are
# staged, run every mechanical test in ~/.claude/tests/*.sh. Blocks the commit
# (permissionDecision: deny) if any test script exits non-zero. Cheap no-op for
# non-commit commands and for commits with no config changes staged.
#
# Two layout facts this has to work around:
#
# 1. ~/.claude is a directory of symlinks into the dotfiles repo, not a git repo
#    of its own — so the config repo root is resolved from the hooks symlink,
#    never assumed to be $HOME/.claude.
# 2. Hooks run in the *session's* cwd, which is usually some other repo entirely
#    (verified 2026-08-22: the payload's "cwd" is the session cwd, not the cwd of
#    a `cd X && git commit ...` compound command). A bare `git diff --cached`
#    here reads the wrong index and the gate silently never fires — the same
#    class of bug as the stale env-var contract. Always `git -C "$CONFIG_ROOT"`.
set +e

CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null)"
[[ -z "$CMD" ]] && exit 0
echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit' || exit 0

# Resolve the repo holding the Claude config, via the hooks/ symlink.
HOOKS_REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_ROOT="$(git -C "$HOOKS_REAL" rev-parse --show-toplevel 2>/dev/null)"
[[ -z "$CONFIG_ROOT" ]] && exit 0

# Path of the config dir relative to that repo root (e.g. claude/.claude).
CONFIG_PREFIX="$(git -C "$HOOKS_REAL" rev-parse --show-prefix 2>/dev/null)"
CONFIG_PREFIX="${CONFIG_PREFIX%/}"          # strip trailing slash
CONFIG_PREFIX="${CONFIG_PREFIX%/hooks}"     # .../claude/.claude/hooks -> .../claude/.claude
[[ -z "$CONFIG_PREFIX" ]] && CONFIG_PREFIX="."

git -C "$CONFIG_ROOT" diff --cached --name-only 2>/dev/null \
  | grep -q "^${CONFIG_PREFIX}/" || exit 0

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
  REASON="Claude config tests failed before commit: ${FAILURES[*]}. Fix or investigate before committing (see stderr above for output)."
  jq -n --arg reason "$REASON" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
fi

exit 0
