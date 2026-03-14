---
name: pr-review-learnings
description: Analyze reviewed PRs against subsequent human feedback to improve future reviews. Spawned by end-session-agent when unlearned PRs exist.
model: glm-5
---

# PR Review Learnings Agent

Compares AI review findings against human comments made around the time of the AI review (±24h), surfaces missed patterns, and suggests skill/REVIEW.md improvements.

## Input

Read `~/.claude/pr-reviews/log.jsonl` — process entries where `learned: false`.

## Workflow

### 1. Load Unlearned PRs

```bash
# Get all unlearned entries
grep '"learned":false' ~/.claude/pr-reviews/log.jsonl
```

For each unlearned PR:

### 2. Fetch AI Review Comments

```bash
# Get AI's review comments (filter by AI disclaimer prefix)
GH_HOST_ENV="" # set if enterprise GitHub host
$GH_HOST_ENV gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  | jq -r '.[] | select(.body | contains("AI-generated") or .body == "") | {id, body, submitted_at}'

# Get inline comments from AI review
$GH_HOST_ENV gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  | jq -r '.[] | select(.body | startswith("🤖")) | {path, line, body, created_at}'
```

Note the AI review timestamp (`submitted_at`).

### 3. Fetch Human Comments Within ±24h of AI Review

Human reviewers may comment in parallel with or before the AI review, not just after.
Include all human comments within a 24-hour window around the AI review timestamp.

```bash
# Compute window: 24h before and after AI review timestamp
# ai_review_timestamp e.g. "2026-03-13T11:32:00Z"
window_start=$(date -v-24H -j -f "%Y-%m-%dT%H:%M:%SZ" "{ai_review_timestamp}" +"%Y-%m-%dT%H:%M:%SZ")
window_end=$(date -v+24H -j -f "%Y-%m-%dT%H:%M:%SZ" "{ai_review_timestamp}" +"%Y-%m-%dT%H:%M:%SZ")

# Get all inline comments, filter to human comments within the window
$GH_HOST_ENV gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  | jq --arg from "$window_start" --arg to "$window_end" \
    '[.[] | select(
        .created_at >= $from and
        .created_at <= $to and
        (.body | startswith("🤖") | not)
      ) | {user: .user.login, path, line, body, created_at}]'

# Also get review-level comments within the window
$GH_HOST_ENV gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  | jq --arg from "$window_start" --arg to "$window_end" \
    '[.[] | select(
        .submitted_at >= $from and
        .submitted_at <= $to and
        .user.login != "github-actions[bot]"
      ) | {user: .user.login, body, state, submitted_at}]'
```

Note whether each human comment was **before** or **after** the AI review — this affects
how you categorise it (pre-existing concern vs. response to AI).

### 4. Analyze Gaps

For each human comment, determine:

| Category | Meaning |
|----------|---------|
| **Missed** | Human flagged something AI didn't mention |
| **Reinforced** | Human flagged same thing AI flagged |
| **Dismissed** | AI flagged something, human reviewer approved without addressing |
| **False positive** | AI flagged something the author/reviewer explicitly said was fine |

Focus on **Missed** findings — these are learning opportunities.

### 5. Identify Patterns

Group missed findings by type:
- Logic bugs
- Test coverage gaps
- Code style / idiomatic patterns
- Architecture concerns
- Security issues
- Documentation gaps

Look for patterns across multiple PRs in the log (if multiple unlearned entries exist).

### 6. Generate Learning Output

For each significant missed pattern, produce a concrete suggestion:

**If repo-specific** (only relevant to this codebase):
- Suggest addition to `/tmp/pr-review-{number}/REVIEW.md` (or create if missing)
- Format: `## Always Flag\n- [pattern description]`

**If general** (applies across all reviews):
- Suggest addition to `~/.claude/skills/pr-reviews/SKILL.md` Common Mistakes section
- Format: existing Common Mistakes entry style

Output the suggestions clearly — do NOT auto-apply them. Let the user decide.

### 7. Mark as Learned

After analysis, update the log entry:

```bash
# Replace learned:false with learned:true for processed entries
# Use a temp file approach
python3 -c "
import json, sys
lines = open('$HOME/.claude/pr-reviews/log.jsonl').readlines()
out = []
for line in lines:
    entry = json.loads(line)
    if entry.get('url') in {processed_urls}:
        entry['learned'] = True
    out.append(json.dumps(entry))
open('$HOME/.claude/pr-reviews/log.jsonl', 'w').write('\n'.join(out) + '\n')
"
```

### 8. Report

Output a concise summary:
```
PR Review Learnings — {date}

PRs analyzed: {n}
Human comments reviewed: {n}
Missed findings: {n}
Reinforced findings: {n}

Suggested improvements:
[list suggestions with file targets]
```

## Notes

- Skip PRs with no human comments yet (nothing to learn from) — leave `learned: false`
- Skip PRs where the only human activity is approval with no comments
- Focus on actionable, repeatable patterns — not one-off domain-specific issues
- False positives are also valuable — if AI consistently over-flags something, note it
