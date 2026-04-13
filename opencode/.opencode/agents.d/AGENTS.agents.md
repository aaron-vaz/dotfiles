# Agent & Model Configuration

## MODE WORKFLOW

OpenCode requires **manual mode switching** (unlike Claude Code). Use these guidelines:

### When to Start with PLAN Mode

**Start in plan mode (`/mode plan`) when:**
- Designing new features or systems
- Making architecture decisions
- Refactoring large components
- Adding new major functionality
- Breaking down complex requirements

**Plan mode features:**
- Model: `opencode-go/glm-5.1` (better at reasoning/architecture)
- Read-only: Cannot write files or run commands
- Purpose: Brainstorm, design, analyze before implementing

### When to Use BUILD Mode (Default)

**Stay in build mode for:**
- Bug fixes
- Small enhancements
- Writing tests
- Documentation updates
- Code cleanup
- Simple refactors
- 90% of day-to-day coding

**Build mode features:**
- Model: `opencode-go/kimi-k2.5` (reliable, high quota)
- Full tool access: Read, Write, Edit, Bash, Task
- Default mode on startup

### When to Use REVIEW Mode

**Switch to review mode (`/mode review`) when:**
- Before committing significant changes
- Self-review before creating a PR
- Analyzing existing code for issues
- Want read-only code analysis

**Review mode features:**
- Model: `opencode-go/kimi-k2.5`
- Read-only: Cannot modify files
- Purpose: Objective code analysis

## MODELS

| Model | Quota (5h) | Best For |
|-------|-----------|----------|
| kimi-k2.5 | 1,850 | General coding (default) |
| glm-5.1 | 880 | Architecture, planning |
| glm-5 | 1,150 | Deep reasoning (alternative) |
| mimo-v2-pro | 1,290 | High-quality coding |
| minimax-m2.7 | 14,000 | Fast, cheap tasks |

## SKILL MODEL ASSIGNMENTS

Skills automatically load their preferred models:

| Skill | Model | Override |
|-------|-------|----------|
| self-review | opencode-go/glm-5.1 | Yes |
| kotlin-review | opencode-go/kimi-k2.5 | Yes |
| jvm | opencode-go/kimi-k2.5 | Yes |
| learnings | opencode-go/kimi-k2.5 | Yes |

## TYPICAL WORKFLOW

```
1. New feature request
   └─→ Switch to PLAN mode: "/mode plan"
   └─→ Discuss design, architecture
   └─→ Get implementation approach

2. Implementation
   └─→ Switch to BUILD mode: "/mode build"
   └─→ Write code, tests
   └─→ Iterate

3. Before commit
   └─→ Optional: Switch to REVIEW mode: "/mode review"
   └─→ Review changes
   └─→ Back to BUILD to fix issues

4. Self-review (optional)
   └─→ Load skill: skill(name="self-review")
   └─→ Skill loads glm-5.1 automatically
```

## SWITCHING MODES

```bash
# In OpenCode chat, type:
/mode plan     # Architecture/planning
/mode build    # Coding (default)
/mode review   # Code review

# Or start with mode:
opencode --mode plan
```
