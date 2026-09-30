#!/bin/bash
# PreToolUse(Bash): deny shell commands that name the credential paths the
# `Read(~/...)` deny rules in settings.json protect for the file tools. Those
# rules don't cover Bash (`cat ~/.ssh/id_ed25519` sails through), and Bash
# argument rules are bypassable, so this is a text-level guard. Best-effort:
# it catches explicit references, not obfuscation (variable indirection,
# globs like ~/.s*h, base64). The robust alternative is sandbox.filesystem
# .denyRead, which also sandboxes all Bash (breaks git-over-SSH here).
#
# Protected, when anchored at the home dir (~, $HOME, ${HOME}, absolute home):
#   .ssh .gnupg .kube Library .netrc .npmrc .pypirc .docker/config.json
# Plus a bare `.ssh` / `.gnupg` / `.kube` path token anywhere, which covers
# `cd ~ && cat .ssh/id_rsa`. A project-level ./.npmrc is NOT blocked.
#
# Implicit use is untouched: `git push` and `ssh host` read keys themselves and
# never name the path. Runs inside subagents too (settings hooks always do).
# Legit need to read one of these yourself: run it with the `!` prefix.
set +e
command -v jq &>/dev/null || exit 0

CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null)"
[[ -z "$CMD" ]] && exit 0

HOME_RE="$(printf '%s' "${HOME%/}" | sed 's/[][\.*^$/|(){}+?]/\\&/g')"
HOME_ANCHOR="(~|\\\$HOME|\\\$\\{HOME\\}|${HOME_RE})"
END='([^[:alnum:]_.-]|$)'

ANCHORED="${HOME_ANCHOR}/(\\.ssh|\\.gnupg|\\.kube|Library|\\.netrc|\\.npmrc|\\.pypirc|\\.docker/config\\.json)${END}"
BARE="(^|[^[:alnum:]_.~-])\\.(ssh|gnupg|kube)${END}"

MATCH=""
if printf '%s' "$CMD" | grep -qE "$ANCHORED"; then
  MATCH="$(printf '%s' "$CMD" | grep -oE "$ANCHORED" | head -1)"
elif printf '%s' "$CMD" | grep -qE "$BARE"; then
  MATCH="$(printf '%s' "$CMD" | grep -oE "$BARE" | head -1)"
fi
[[ -z "$MATCH" ]] && exit 0

REASON="Blocked: this command names a protected credential path (matched \"${MATCH# }\"). ~/.ssh, ~/.gnupg, ~/.kube, ~/Library, ~/.netrc, ~/.npmrc, ~/.pypirc and ~/.docker/config.json are off-limits to Claude, same as the Read tool. git and ssh use their keys implicitly, so you don't need to name them. If you really need this, ask the user to run it themselves with the ! prefix."

jq -n --arg reason "$REASON" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
exit 0
