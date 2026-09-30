#!/bin/bash
# PreToolUse(Edit|Write|NotebookEdit): the main session does not edit code —
# implementation goes through the impl-orchestrator subagent.
#
# Main-thread vs subagent: `agent_id` is present in the hook payload only when
# the call comes from inside a subagent (verified 2026-09-30, v2.1.285). So a
# missing agent_id == main thread. Do NOT run the main session with --agent or
# the `agent` setting: that would stamp agent_type on main-thread calls too.
#
# Always allowed from the main thread:
#   - anything under a `.claude/` directory (config, agents, memory)
#   - ~/.agents/ (knowledge base)
#   - temp dirs (scratchpads, throwaway `mcc` sessions)
#   - everything, when CC_MAIN_EDITS=1 (escape hatch: `CC_MAIN_EDITS=1 cc`)
# Bash is deliberately not gated: ad-hoc questions need it, and shell-level
# writes can't be told apart from reads reliably.
set +e
command -v jq &>/dev/null || exit 0

PAYLOAD="$(cat 2>/dev/null)"
[[ -z "$PAYLOAD" ]] && exit 0

AGENT_ID="$(echo "$PAYLOAD" | jq -r '.agent_id // empty' 2>/dev/null)"
[[ -n "$AGENT_ID" ]] && exit 0
[[ "${CC_MAIN_EDITS:-}" == "1" ]] && exit 0

TARGET="$(echo "$PAYLOAD" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)"
[[ -z "$TARGET" ]] && exit 0

# Resolve symlinks in the parent dir so ~/.claude/x and the dotfiles path agree.
PARENT="$(dirname "$TARGET")"
RESOLVED_PARENT="$(cd "$PARENT" 2>/dev/null && pwd -P)"
if [[ -n "$RESOLVED_PARENT" ]]; then
  RESOLVED="$RESOLVED_PARENT/$(basename "$TARGET")"
else
  RESOLVED="$TARGET"
fi

for candidate in "$TARGET" "$RESOLVED"; do
  case "$candidate" in
    */.claude/*|"$HOME"/.agents/*|/tmp/*|/private/tmp/*|/var/folders/*|/private/var/folders/*) exit 0 ;;
  esac
  if [[ -n "${TMPDIR:-}" && "$candidate" == "${TMPDIR%/}"/* ]]; then
    exit 0
  fi
done

REASON="The main session doesn't edit code — delegate. Spawn the impl-orchestrator subagent (Agent tool, subagent_type \"impl-orchestrator\", NO model parameter) with a full brief: goal, constraints, acceptance criteria, relevant paths. For a trivial 1-3 file mechanical edit, spawn quick-editor instead. Do NOT work around this with Bash file writes (sed -i, heredocs, python/tee redirects) — delegate. Blocked target: $TARGET. To edit directly in a session on purpose, relaunch with CC_MAIN_EDITS=1."

jq -n --arg reason "$REASON" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
exit 0
