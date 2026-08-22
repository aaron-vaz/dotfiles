#!/bin/bash
# Remind to switch to a planning-grade model when planning/design keywords are
# detected. Fires on UserPromptSubmit. Outputs a systemMessage banner plus
# additionalContext for Claude.
set -euo pipefail

PROMPT=$(jq -r '.prompt // empty' 2>/dev/null || true)
[[ -z "$PROMPT" ]] && exit 0

if echo "$PROMPT" | grep -qiE '\b(brainstorm|tech.{0,5}discovery|write.{0,10}plan|create.{0,10}plan|lets.{0,5}design)\b'; then
  printf '%s\n' '{"systemMessage":"Planning session? /model opusplan for the main loop","hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"PLANNING TRIGGER: prompt matches planning/design keywords. AGENTS.md routes planning/research/architecture to the fable tier and design docs to opus. If the session is currently on a lower tier, remind the user once that /model opusplan switches the main loop to Opus."}}'
fi
