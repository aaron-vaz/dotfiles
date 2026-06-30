# Session Startup

Execute the following immediately, then say "Ready" and wait for user input.

## 1. Spawn Session Quality Agent (Non-Blocking)

**Skip if any condition is true:**
- `~/.claude/sessions/current.md` is missing or under 500 bytes (trivial/empty previous session)
- `~/.claude/sessions/.quality-check-last-run` exists and was modified within the last 7 days

If none of the skip conditions apply, execute this single tool call:

**Agent:**
- subagent_type: `general-purpose`
- description: `Run session quality checks`
- prompt: `You are running the weekly session quality and archival check. Do the following: (1) Scan recent sessions in ~/.claude/sessions/ — look for unarchived KB-worthy sessions. (2) For any session with substantial content (>1000 bytes) not already in ~/.claude/kb/entries/ by date slug, invoke the session-archiver skill to archive it automatically. (3) Touch ~/.claude/sessions/.quality-check-last-run. (4) Output a brief summary. Stop.`
- run_in_background: `true`

## 2. Load Session Context

Execute these reads in parallel:
- Read `~/.claude/sessions/current.md` to restore context from previous session
- Read `~/.claude/persona.md` for communication style

## 3. Acknowledge

After spawning the agent and loading context, output:

```
Ready.
```

**Do NOT wait for the agent to complete.** It runs in background.
