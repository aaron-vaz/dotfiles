#!/bin/bash
# Reminds to run adversarial-review (Gate 2) after editing a SKILL.md file.
# Runs as a PostToolUse hook on Edit|Write. Per AGENTS.md Workflow Checkpoints.
set +e

# Tool metadata arrives as JSON on stdin. CLAUDE_TOOL_NAME / CLAUDE_TOOL_INPUT
# are a stale contract and are never set (verified 2026-08-22) — reading them
# made this hook a silent no-op. See validate-git-usage.sh for the full note.
PAYLOAD="$(cat 2>/dev/null)"
TOOL_NAME="$(echo "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)"
[[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]] && exit 0

FILE_PATH="$(echo "$PAYLOAD" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$(basename "$FILE_PATH")" != "SKILL.md" ]] && exit 0

# Dedup: one reminder per file per hour to avoid alarm fatigue across multi-edit drafting sessions.
LOCK_KEY=$(echo -n "$FILE_PATH" | md5 2>/dev/null || echo -n "$FILE_PATH" | md5sum | cut -d' ' -f1)
LOCK_FILE="/tmp/claude-skillmd-reminded-${LOCK_KEY}-$(date +%Y%m%d%H)"
[[ -f "$LOCK_FILE" ]] && exit 0
touch "$LOCK_FILE" 2>/dev/null

printf '%s\n' '{"systemMessage":"SKILL.md edited — run adversarial-review (Gate 2) before finalizing","hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"STOP before finalizing: this SKILL.md draft has not been through adversarial-review Gate 2 yet. Invoke it now (once for this drafting session is enough — you will not be reminded again this hour)."}}'
exit 0
