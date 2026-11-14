# Hook Configuration Examples

**Last Updated:** 2026-11-14

Reference for configuring Claude Code hooks in `~/.claude/settings.json`.

## Active Hooks

Check your current configuration:
```bash
cat ~/.claude/settings.json
```

## Hook Types

| Hook Event | When It Fires | Use Cases |
|------------|---------------|-----------|
| `SessionStart` | Beginning of new session | Load context, display reminders |
| `PreToolUse` | Before tool execution | Validate inputs, show warnings |
| `PostToolUse` | After tool completes | Verify results, log actions |

## Examples by Use Case

### Session Context Loading

**Purpose:** Auto-load session context at start

```json
{
  "hooks": {
    "SessionStart": [{
      "type": "command",
      "command": "cat ~/.claude/sessions/current.md 2>/dev/null || echo 'No current session context'"
    }]
  }
}
```

**What it does:**
- Loads previous session context automatically
- Falls back gracefully if no session file exists

### Pre-Commit Reminders

**Purpose:** Remind to run quality checks before committing

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "if jq -r '.tool_input.command // empty' | grep -q \"git commit\"; then echo '⚠️  Pre-commit reminder: Consider running /claude-md-management:claude-md-improver if you made architectural changes'; fi"
      }]
    }]
  }
}
```

**What it does:**
- Fires before any Bash command
- Checks if command contains "git commit"
- Shows reminder about CLAUDE.md audit for architectural changes

**Variation - Test Verification:**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "if jq -r '.tool_input.command // empty' | grep -q \"git commit\"; then echo 'Reminder: tests must pass before committing'; fi"
      }]
    }]
  }
}
```

### Scope Validation

**Purpose:** Prevent unauthorized refactoring

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit",
      "hooks": [{
        "type": "command",
        "command": "echo 'Check: was this edit within the requested scope? No unauthorized refactoring.'"
      }]
    }]
  }
}
```

**What it does:**
- Fires after every Edit tool use
- Prompts review of whether edit stayed in scope
- Catches scope creep early

### Build Verification

**Purpose:** Ensure build passes after code changes

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit",
      "hooks": [{
        "type": "command",
        "command": "echo '⚠️  Code changed - remember to verify build passes before committing'"
      }]
    }]
  }
}
```

### Java Version Check

**Purpose:** Remind about JVM version for Maven/Gradle builds

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "if jq -r '.tool_input.command // empty' | grep -qE '(mvn|./gradlew)'; then echo 'Reminder: Verify correct Java version active (check project CLAUDE.md)'; fi"
      }]
    }]
  }
}
```

### Skill Invocation Reminder

**Purpose:** Remind to use skills before implementation

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write",
      "hooks": [{
        "type": "command",
        "command": "echo '⚠️  Creating new file - did you invoke relevant skills first?'"
      }]
    }]
  }
}
```

## Combining Multiple Hooks

You can combine multiple hooks on the same event:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "if jq -r '.tool_input.command // empty' | grep -q \"git commit\"; then echo '⚠️  Pre-commit checklist: tests pass, pre-commit-reviewer run, CLAUDE.md updated?'; fi"
          },
          {
            "type": "command",
            "command": "if jq -r '.tool_input.command // empty' | grep -qE '(mvn|./gradlew)'; then echo '⚠️  JVM build - verify Java version matches project requirements'; fi"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "echo '✓ File edited - was this within requested scope?'"
          }
        ]
      }
    ]
  }
}
```

## Hook Best Practices

### Do:
- ✅ Keep messages concise and actionable
- ✅ Use warnings (⚠️) for important reminders
- ✅ Check specific command patterns (not broad matches)
- ✅ Fail gracefully with `2>/dev/null` or exit codes
- ✅ Test hooks thoroughly before relying on them

### Don't:
- ❌ Block execution with long-running commands
- ❌ Echo verbose output that clutters the UI
- ❌ Use hooks for commands that should be in skills
- ❌ Create hooks that fire too frequently
- ❌ Make hooks that require user input

## Hook Input Contract

Hooks receive tool metadata as JSON on stdin, not through environment variables. This was verified on 2026-08-22 by wiring a probe hook that dumped stdin and the environment on `PreToolUse:Bash` and `PostToolUse:Edit|Write`. `tests/hook-stdin-contract-mechanical.sh` is the executable specification.

The payload looks like this:

```json
{"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "..."}, "cwd": "/path/of/the/session", "session_id": "..."}
```

- `PostToolUse` nests its input under `tool_input` in the same way and adds `tool_response`.
- Inside a subagent the payload also carries `agent_id` and `agent_type`; both are absent on main-thread calls.
- The only `CLAUDE_*` variables that exist are `CLAUDE_PROJECT_DIR`, `CLAUDE_PID`, `CLAUDE_CODE_SESSION_ID`, `CLAUDE_EFFORT`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDECODE`, and `CLAUDE_CODE_MESSAGING_SOCKET` with its `_TOKEN`.
- `CLAUDE_BASH_COMMAND`, `CLAUDE_TOOL_INPUT`, `CLAUDE_FILE_PATH` and `CLAUDE_TOOL_NAME` are never set. A hook that reads them matches an empty string, enforces nothing, and still looks healthy in `/hooks`.

Read the command like this, keeping the environment fallback in case the contract reverts:

```bash
CMD="$(jq -r '.tool_input.command // empty' 2>/dev/null || true)"
CMD="${CMD:-${CLAUDE_BASH_COMMAND:-}}"
```

The `|| true` matters under `set -e`: an unguarded failing command substitution kills the script, which is how `pre-commit-review.sh` once crashed with `CLAUDE_BASH_COMMAND: unbound variable`.

### Working directory

A hook runs in the session's working directory, not in the directory of a compound command such as `cd ~/Code/shell/dotfiles && git commit ...`. The payload's `cwd` field is the session directory. A bare `git diff --cached` or `git -C .` inside a hook therefore reads whatever repository the session happens to be in.

- A hook that guards one specific repository should resolve it from its own file location, for example `git -C "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)" rev-parse --show-toplevel`. This works through the `~/.claude` symlinks because `pwd -P` resolves them.
- A hook that acts on the repository the user is committing in should try, in order: `git -C <path>` from the command, a leading `cd <path>`, the payload's `.cwd`, then `$PWD`.

### Verifying a hook

A guard without a test of its own is not a guard. A silent hook looks identical to a working one in `/hooks`, so assert a side effect (a log file, a denial, a warning) before trusting it. Test a repository-resolving hook against a synthetic repository rather than the live index: the hook resolves its root from its own path, so copying it into a fake repository makes it resolve there.

## Testing Hooks

To test a hook without restarting Claude:

1. Edit `~/.claude/settings.json`
2. Save the file
3. Run a command that should trigger the hook
4. Verify the expected output appears

**Example test:**
```bash
# Add a hook that echoes on any bash command
# Then run: ls
# Should see your hook message
```

## Disabling Hooks Temporarily

Comment out the hook JSON (won't work - JSON doesn't support comments).

**Workaround - Disable by changing matcher:**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "DisabledBash",  // Changed from "Bash"
      "hooks": [...]
    }]
  }
}
```

## Common Matchers

| Matcher | Matches Tool |
|---------|-------------|
| `Bash` | Bash command execution |
| `Edit` | File editing |
| `Write` | File creation |
| `Read` | File reading |
| `Grep` | Content search |
| `Glob` | File pattern matching |
| `Task` | Agent spawning |

## Hook Troubleshooting

**Hook not firing:**
- Check JSON syntax is valid
- Verify matcher matches tool name exactly
- Ensure command is executable in shell
- Test command independently first

**Hook firing too often:**
- Narrow the matcher pattern
- Add more specific command checks
- Use grep patterns to filter

**Hook output not visible:**
- Check command produces stdout
- Verify no errors swallowed by 2>/dev/null
- Test command in terminal first

## Further Reading

- Official docs: Check Claude Code documentation for latest hook capabilities
- Settings file: `~/.claude/settings.json` for your active configuration
