#!/bin/bash
# PreToolUse(Read|Edit|Write|...): the first time a session/agent touches a file
# of a given language or topic, push the matching standing-rule KB entries
# (`type: feedback`) into context as additionalContext. Rules are otherwise only
# found if someone thinks to search the KB; this makes them arrive with the work.
#
# Never blocks, never prints a permissionDecision, ALWAYS exits 0. Any failure
# (malformed stdin, no file_path, search script missing/failing) prints nothing.
#
# File -> KB tag mapping (only tags with feedback entries today, plus the
# obvious future ones python/java/shell; keep it tight, every tag costs context):
#   .kt .kts                          kotlin
#   .py                               python
#   .java                             java
#   .sh .bash .zsh                    shell shell-scripts
#   .proto                            protobuf
#   *.gradle *.gradle.kts             gradle (plus kotlin for .kts)
#   test files                        testing, in addition to the language tag:
#     path contains /test/ or /tests/, or basename matches *Test.* *Tests.*
#     *Spec.* *_test.* test_*.* *.test.* *.spec.*
# Markdown is deliberately unmapped: the `documentation` feedback is about code
# comments/reference docs, and pushing it on every README read is noise.
#
# Dedupe: ${TMPDIR:-/tmp}/claude-kb-feedback-push/<session_id>/<agent>/<tag>/ is
# a claim directory. Subagents have their own context, so each agent_id (the
# main thread is the literal `main`) gets each tag once. `mkdir` is atomic, so
# exactly one of several parallel Reads wins each claim and the rest stay silent.
# The claim happens BEFORE any search, so a Read with nothing new costs one jq
# call and a mkdir. A tag is claimed even when the search returns nothing.
# session_id and agent_id are untrusted: both are sanitized before becoming paths.
#
# One search per push: `search-kb.sh --type feedback --brief` (no --tag; each
# search costs seconds) and the brief lines are filtered here. Index tags can
# carry literal quotes (`"kotlin"`), and --tag would match by SUBSTRING (`java`
# also hits `javascript`), so lines are kept only on an exact tag match.
#
# Env: KB_SEARCH overrides the search script (tests).
set +e
command -v jq &>/dev/null || exit 0

MAX_CHARS=10000
BUDGET=9500   # headroom under MAX_CHARS for the truncation note

PARSED="$(jq -r '((.session_id // "") | tostring | gsub("[\n\t]"; " ")),
                 ((.agent_id // "") | tostring | gsub("[\n\t]"; " ")),
                 ((.tool_input.file_path // "") | tostring | gsub("\n"; " "))' 2>/dev/null)"
{ IFS= read -r SESSION; IFS= read -r AGENT; IFS= read -r FILE; } <<< "$PARSED"
[[ -z "$FILE" ]] && exit 0
[[ -z "$AGENT" ]] && AGENT="main"
[[ -z "$SESSION" ]] && SESSION="nosession"

BASE="${FILE##*/}"
EXT=""
[[ "$BASE" == *.* ]] && EXT="${BASE##*.}"

TAGS=""
case "$EXT" in
  kt)            TAGS="kotlin" ;;
  kts)           TAGS="kotlin" ;;
  py)            TAGS="python" ;;
  java)          TAGS="java" ;;
  sh|bash|zsh)   TAGS="shell shell-scripts" ;;
  proto)         TAGS="protobuf" ;;
esac
case "$BASE" in
  *.gradle|*.gradle.kts) TAGS="$TAGS gradle" ;;
esac
case "$FILE" in
  */test/*|*/tests/*) TAGS="$TAGS testing" ;;
  *)
    case "$BASE" in
      *Test.*|*Tests.*|*Spec.*|*_test.*|test_*.*|*.test.*|*.spec.*) TAGS="$TAGS testing" ;;
    esac ;;
esac
TAGS="${TAGS# }"
[[ -z "$TAGS" ]] && exit 0

KB="${KB_SEARCH:-$HOME/.agents/kb/search-kb.sh}"
[[ -x "$KB" ]] || exit 0

STATE_DIR="${TMPDIR:-/tmp}"
STATE_DIR="${STATE_DIR%/}/claude-kb-feedback-push"
SESSION_DIR="$(printf '%s' "$SESSION" | tr -c 'A-Za-z0-9_-' '_')"
AGENT_DIR="$(printf '%s' "$AGENT" | tr -c 'A-Za-z0-9_-' '_')"
CLAIM_DIR="$STATE_DIR/$SESSION_DIR/$AGENT_DIR"

mkdir -p -- "$CLAIM_DIR" 2>/dev/null || exit 0
# Claim before searching: parallel tool calls in one turn push at most once (only
# one mkdir per tag succeeds), and tags with no entries are not re-searched on
# every Read.
NEW_TAGS=""
for tag in $TAGS; do
  mkdir -- "$CLAIM_DIR/$tag" 2>/dev/null || continue
  NEW_TAGS="$NEW_TAGS $tag"
done
NEW_TAGS="${NEW_TAGS# }"
[[ -z "$NEW_TAGS" ]] && exit 0

OUT="$("$KB" --type feedback --brief 2>/dev/null </dev/null || true)"
[[ -z "$OUT" ]] && exit 0
# Brief line: `<marker>date | slug | [tags] | description`. Keep lines whose tag
# field contains any new tag exactly; a line matching several tags prints once.
LINES="$(printf '%s\n' "$OUT" | awk -F' \\| ' -v want="$NEW_TAGS" '
  BEGIN { n = split(want, w, " "); for (i = 1; i <= n; i++) wanted[w[i]] = 1 }
  {
    f = $3
    gsub(/[\[\]" ]/, "", f)
    n = split(f, a, ",")
    for (i = 1; i <= n; i++) if (a[i] in wanted) { print; next }
  }' 2>/dev/null)"
[[ -z "$LINES" ]] && exit 0

TAG_LIST="${NEW_TAGS// /, }"
CTX="Standing rules (KB feedback entries) for ${TAG_LIST} - apply these to this work; load any in full with \`~/.agents/kb/search-kb.sh <slug> --full\`:"

TRUNCATED=""
while IFS= read -r line; do
  if (( ${#CTX} + ${#line} + 1 > BUDGET )); then
    TRUNCATED=1
    # Nothing fit at all: keep a cut-down first line rather than an empty list.
    [[ "$CTX" != *$'\n'* ]] && CTX="${CTX}"$'\n'"${line:0:$(( BUDGET - ${#CTX} - 1 ))}"
    break
  fi
  CTX="${CTX}"$'\n'"${line}"
done <<< "$LINES"
[[ -n "$TRUNCATED" ]] && CTX="${CTX}"$'\n'"(truncated; search the KB with --type feedback --tag <tag> for the rest)"

jq -n --arg ctx "$CTX" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}' 2>/dev/null
exit 0
