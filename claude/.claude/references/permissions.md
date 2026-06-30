# Claude Code Permissions Configuration

This document covers how to configure permissions in `settings.json` to auto-approve specific operations.

## When to Use Permissions Config

Use `permissions.allow` rules to:
- Auto-approve repetitive operations in specific workflows (PR reviews, builds, tests)
- Reduce permission prompts for trusted operations
- Scope permissions to specific repos/workspaces

**Don't use for:**
- One-off commands (just approve the prompt)
- Untrusted or potentially destructive operations

## Syntax

### Basic Structure

```json
{
  "permissions": {
    "allow": [
      "ToolName(parameter:pattern*)"
    ],
    "deny": [
      "ToolName(parameter:pattern*)"
    ],
    "ask": [
      "ToolName(parameter:pattern*)"
    ],
    "defaultMode": "default"
  }
}
```

### Tool Patterns

**Bash commands:**
```json
"Bash(command:gh pr view*)"      // Allow all gh pr view commands
"Bash(command:git -C /tmp/*)"    // Allow git in /tmp directories
"Bash(command:npm test)"         // Exact match only
```

**File operations:**
```json
"Read(file_path:/path/to/file)"           // Specific file
"Edit(file_path:/path/to/dir/*)"          // Directory pattern
"Write(file_path:/tmp/build-cache/*)"     // Temp files
```

**Wildcards:**
- `*` matches any characters within a path segment
- Use exact paths for security-critical operations
- Pattern matching uses standard glob syntax

## Scoping: Global vs Repo-Specific

### Global (`~/.claude/settings.json`)

**Use for:**
- Operations you trust everywhere
- Read-only commands (gh pr view, git log)
- User-specific preferences

**Example:**
```json
{
  "permissions": {
    "allow": [
      "Bash(command:git status*)",
      "Bash(command:git log*)",
      "Bash(command:gh pr view*)"
    ]
  }
}
```

### Repo-Specific (`<repo>/.claude/settings.json`)

**Use for:**
- Workflow-specific operations (PR reviews from one repo)
- Project-specific build/test commands
- Operations scoped to temp directories

**Example:**
```json
{
  "permissions": {
    "allow": [
      "Bash(command:gh repo clone*)",
      "Bash(command:git -C /tmp/pr-review-*)",
      "Bash(command:rm -rf /tmp/pr-review-*)"
    ]
  }
}
```

**Why repo-specific is better:**
- Permissions only apply when working from that workspace
- More restrictive (safer)
- Easier to audit per-project
- Can't accidentally trigger from wrong context

## Common Patterns

### PR Review Workflow

**Location:** `<workspace>/.claude/settings.json` (where you invoke PR reviews from)

```json
{
  "permissions": {
    "allow": [
      "Bash(command:gh pr view*)",
      "Bash(command:gh pr diff*)",
      "Bash(command:gh pr checkout*)",
      "Bash(command:gh pr checks*)",
      "Bash(command:gh api*repos/*/pulls/*/reviews*)",
      "Bash(command:gh api*repos/*/pulls/*/comments*)",
      "Bash(command:gh repo clone*)",
      "Bash(command:git -C /tmp/pr-review-*)",
      "Bash(command:rm -rf /tmp/pr-review-*)"
    ]
  }
}
```

### Build/Test Automation

**Location:** `<project>/.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(command:./gradlew test*)",
      "Bash(command:./gradlew build*)",
      "Bash(command:mvn test*)",
      "Bash(command:npm test*)"
    ]
  }
}
```

### Safe Git Operations

**Location:** `~/.claude/settings.json` (global)

```json
{
  "permissions": {
    "allow": [
      "Bash(command:git status*)",
      "Bash(command:git log*)",
      "Bash(command:git diff*)",
      "Bash(command:git show*)",
      "Bash(command:git branch --list*)"
    ]
  }
}
```

## Permission Modes

### defaultMode Options

- `"default"` - Prompt for each operation (default)
- `"dontAsk"` - Auto-approve all operations (use with caution)
- `"acceptEdits"` - Auto-approve file edits only
- `"plan"` - Require plan approval before execution
- `"bypassPermissions"` - Skip permission system entirely (dangerous)

**Recommendation:** Use specific `allow` rules instead of `defaultMode: "dontAsk"`

## Debugging

**Check effective permissions:**
```bash
# View merged permissions from all sources
# (global + repo + local settings)
cat ~/.claude/settings.json | jq .permissions
cat <repo>/.claude/settings.json | jq .permissions
```

**Test a permission:**
1. Add the rule to settings.json
2. Restart Claude Code session (settings are loaded at startup)
3. Try the operation - should not prompt

**Common issues:**
- Forgot to restart session after editing settings.json
- Pattern too specific (use `*` wildcards)
- Pattern too broad (creates security risk)
- Wrong tool name (use exact tool name from Claude Code)

## Security Best Practices

1. **Principle of least privilege:** Only allow what you need
2. **Scope to temp directories:** `/tmp/pr-review-*` not `/tmp/*`
3. **Use repo-specific over global:** Limits blast radius
4. **Avoid blanket wildcards:** `command:*` is dangerous
5. **Review regularly:** Audit `.claude/settings.json` monthly
6. **Document why:** Add comments explaining each allow rule

## Skills and Permissions

**Important:** Skills cannot configure permissions in frontmatter.

```yaml
---
name: my-skill
# ❌ No permission fields supported here
---
```

**Workaround:** Document required permissions in skill README, ask users to add to their settings.json.

**Agent mode parameter:** When spawning agents, you can pass `mode: "dontAsk"` to bypass prompts for that agent only:

```javascript
Agent(
  subagent_type="code-reviewer",
  mode="dontAsk",  // Agent runs without permission prompts
  prompt="Review changes"
)
```

## References

- Official settings schema: `~/.claude/settings.json` (see validation errors for field names)
- Hook configuration: `~/.claude/references/hooks.md`
- Skills index: `~/.claude/references/skills-index.md`
