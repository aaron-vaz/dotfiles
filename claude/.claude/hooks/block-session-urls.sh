#!/bin/bash
# PreToolUse(Bash): deny a git commit or gh write whose text carries a claude.ai session URL or a
# Claude-Session trailer. The harness's own attribution instructions add them, so a remembered rule
# kept losing to them — see KB no-session-urls-in-external-content.
set +e

PAYLOAD="$(cat 2>/dev/null)"
CMD="$(echo "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[[ -n "$CMD" ]] || exit 0

if ! echo "$CMD" | grep -qE '(git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit|gh[[:space:]]+(pr|issue|api|release))'; then
  exit 0
fi

PATTERN='claude\.ai/code/session|Claude-Session:'

# The message usually rides inline (-m, a heredoc, --body), but -F/--file/--body-file point at a file
# whose contents the command text never shows.
PAYLOAD_CWD="$(echo "$PAYLOAD" | jq -r '.cwd // empty' 2>/dev/null)"
FILES="$(echo "$CMD" | grep -oE '(-F|--file|--body-file)[[:space:]=]+[^[:space:];&|]+' | sed -E 's/^(-F|--file|--body-file)[[:space:]=]+//')"

HIT=""
echo "$CMD" | grep -qE "$PATTERN" && HIT="the command text"
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  f="${f%\"}"; f="${f#\"}"; f="${f%\'}"; f="${f#\'}"
  f="${f/#\~/$HOME}"
  [[ "$f" = /* ]] || f="${PAYLOAD_CWD:-$PWD}/$f"
  if [[ -f "$f" ]] && grep -qE "$PATTERN" "$f"; then
    HIT="${HIT:+$HIT and }$f"
  fi
done <<< "$FILES"

[[ -n "$HIT" ]] || exit 0

REASON="Blocked: a claude.ai/code session URL or Claude-Session trailer was found in $HIT. Remove that line and retry — keep the Co-Authored-By trailer and the Claude Code footer. (KB: no-session-urls-in-external-content)"
jq -n --arg r "$REASON" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
exit 0
