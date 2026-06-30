# Learning Pattern Detection Guidelines

This document defines thresholds and patterns for the learning-analyzer agent to identify skill updates.

## Pattern Detection Thresholds

### High Priority (Always Update Skills)
- **User corrections** - Any time user corrects Claude during session
  - Logged in `~/.claude/sessions/current.md` under "Corrections Made by User"
  - Indicates misunderstanding or wrong approach
  - Always warrants skill update

- **Repeated tool failures (3+ times)** - Same tool fails 3 or more times in a session
  - Check error log: `grep "Tool: <tool_name>" ~/.claude/learnings/YYYY-MM-DD.log | wc -l`
  - Indicates tool usage pattern issue
  - Update relevant skill with correct usage

- **Same error message (2+ times)** - Identical error across multiple attempts
  - Check for duplicate error messages in log
  - Indicates systematic misunderstanding
  - Add to skill's "Common Mistakes" section

### Medium Priority (Review for Patterns)
- **Tool failures across multiple days** - Same tool fails in 2+ different sessions
  - Check last 7 days: `grep -h "Tool: <tool_name>" ~/.claude/learnings/2026-*.log`
  - May indicate persistent knowledge gap
  - Consider skill update if pattern is clear

- **Skill violations** - Task where skill should have been invoked but wasn't
  - Check conversation for brainstorming without using brainstorm skill
  - Check for implementing features without TDD skill
  - Update skill's "When to Use" section or add to CLAUDE.md reminders

### Low Priority (Document but Don't Update)
- **One-time mistakes** - Single error with clear context-specific cause
  - Typos, wrong file paths, temporary issues
  - Note in session summary but don't update skills

- **Known limitations** - Tool or platform limitations
  - Not fixable via skill updates
  - Document in tool-specific reference if recurring

## Multi-Day Analysis

When analyzing patterns, check the last 7 days of logs:

```bash
# Count errors by tool across last 7 days
for log in ~/.claude/learnings/2026-02-*.log; do
  echo "=== $(basename $log) ==="
  grep "Tool:" "$log" | cut -d' ' -f2 | sort | uniq -c | sort -rn
done

# Find repeated error messages
grep -h "Error:" ~/.claude/learnings/2026-02-*.log | sort | uniq -c | sort -rn | head -10
```

## NEW_LEARNING Criteria

Only update skills for **generalizable** patterns:

✅ **Update skills when:**
- Pattern applies to future sessions
- Clear cause and prevention strategy
- Affects multiple use cases
- User explicitly corrected behavior

❌ **Don't update skills for:**
- Context-specific one-offs
- External system issues (API down, network errors)
- Already documented in skill
- Unclear root cause

## Skill Update Locations

| Pattern Type | Where to Update |
|--------------|----------------|
| Tool usage mistake | Skill's main file or "Common Mistakes" section |
| Missing skill invocation | CLAUDE.md "Red Flags" or skill "When to Use" |
| Domain-specific pattern | Domain skill (trino, jira-writing, etc.) |
| General workflow issue | CLAUDE.md "Workflow Checkpoints" |
| New table/schema info | Domain skill schemas/*.md |

## Example Analysis

**Input:** 4 failed attempts with `editJiraIssue` all showing "Failed to convert markdown to adf"

**Analysis:**
- Threshold: 3+ failures (HIGH PRIORITY)
- Same error message across attempts (HIGH PRIORITY)
- Pattern: Using ADF format instead of markdown string
- Generalizable: Yes - applies to all future Jira edits

**Action:**
- Update `~/.claude/skills/jira-writing/SKILL.md`
- Add "Atlassian MCP Tool Usage" section
- Document correct format vs incorrect format
- Add PreToolUse hook reminder (if not exists)

## Agent Best Practices Pattern Compliance

Check session activity against the 15 universal patterns in `~/.claude/references/agent-best-practices.md`.

**PATTERN_VIOLATION** classification - use the quick detection table:

| Signal in logs/session | Pattern Violated | Priority |
|------------------------|-----------------|----------|
| Multiple builds with single-file edits between them | proactive-error-capture (#1) | HIGH |
| Sequential Read calls that could be parallel | parallel-execution (#2) | MEDIUM |
| Test failures after "fixed" compilation | proactive-fixes (#3) | MEDIUM |
| Wrong repo/branch discovered mid-session | tier-confirmation (#9) | HIGH |
| Refactor done but old pattern still exists | exhaustive-scanning (#6) | HIGH |
| Bulk change with no preview shown | dry-run-mode (#10) | MEDIUM |
| Work claimed done without success checklist | explicit-validation (#13) | MEDIUM |
| Repeated mistake that skill already warns against | agent-error-guidance (#14) | HIGH |

**Action for PATTERN_VIOLATION:**
- If the violation anti-pattern is NOT already documented in the relevant skill → add it
- If it IS documented → note the violation but don't update (enforcement issue, not docs issue)

## Permission Auto-Discovery

When a tool required user approval during the session (i.e., was not in the allowlist), evaluate whether it should be auto-allowed.

**Check the error log for permission prompts:**
```bash
grep -i "permission\|denied\|allow\|approve" ~/.claude/learnings/$(date +%Y-%m-%d).log
```

**Also check command log for tools that triggered approval dialogs:**
```bash
# Look for MCP tool names that appeared in session
grep "mcp__" ~/.claude/command-log.txt | tail -50
```

**Classification: PERMISSION_GAP**
- A tool was used that required manual approval
- Evaluate: Is this tool read-only? (no side effects, no writes, no mutations)
- If read-only → add to `~/.claude/settings.json` allow list
- If write/mutating → leave as-is (requires approval by design)

**Read-only indicators:**
- Tool name contains: `get`, `list`, `search`, `read`, `fetch`, `view`, `inspect`, `query`, `find`
- Tool is a REDACTED search via REDACTED (`REDACTED REDACTED ...`) - all read-only
- Tool is a Trino read tool (`mcp__trino__inspect_table`, `mcp__trino__execute_query` with SELECT)
- Tool is a `gh` CLI read operation (`gh pr view`, `gh api` GET)

**Write indicators (do NOT auto-allow):**
- Tool name contains: `create`, `update`, `edit`, `delete`, `write`, `post`, `put`, `patch`
- Jira write tools: `editJiraIssue`, `createJiraIssue`, `transitionJiraIssue`
- Git write operations: `push`, `commit`, `reset`

**Settings format for new allow entries:**
```json
"mcp__<server>__<tool_name>"
```

## Review Frequency

- **Daily:** Automatic at session end via end-session skill
- **Weekly:** Manual review of trends across multiple sessions
- **Monthly:** Review skill effectiveness (are error rates decreasing?)
