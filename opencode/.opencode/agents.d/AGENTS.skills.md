# Custom Skills Reference

## INSTALLED SKILLS (8)

| Skill | Purpose | When to Use | Status |
|-------|---------|-------------|--------|
| agents-md-validator | AGENTS.md validation | Validate structure, commands, paths, scoring | ✅ OpenCode compatible |
| find-skills | Skill discovery | Find/install new skills for specific tasks | ✅ OpenCode compatible |
| jvm | Gradle/Maven builds | Build/test issues, Java version errors | ✅ Migrated to OpenCode |
| jvm-test-quality | Test coverage | Coverage gaps, branch coverage, test plans | ✅ OpenCode compatible |
| kotlin-review | Kotlin patterns | Review PRs, idiomatic patterns | ✅ OpenCode compatible |
| learnings | Learnings management | Capture and manage corrections/preferences | ✅ OpenCode compatible |
| mermaid-diagram-creator | Diagrams | Flowcharts, sequence, state, class, ER diagrams | ✅ OpenCode compatible |
| self-review | Self code review | After committing, staff-level review | ✅ Migrated to OpenCode |

## SKILL INVOCATION

```bash
# Invoke skill directly
skill(name="kotlin-review")

# Use during delegation
task(category="quick", load_skills=["kotlin-review"], prompt="...")
```

## SKILL PRIORITY

**User-installed skills OVERRIDE built-in defaults** when domain matches.

Example:
- `jvm` skill → use over generic build commands
- `kotlin-review` skill → use over generic code review
- `react-best-practices` skill → use over generic frontend patterns

## WHEN TO LOAD SKILLS

| Task Pattern | Skills to Load |
|--------------|----------------|
| Kotlin code review | `kotlin-review` |
| Build/test JVM project | `jvm`, `jvm-test-quality` |
| Self-review before PR | `self-review` |
| Create diagrams | `mermaid-diagram-creator` |
| Manage learnings | `learnings` |
| Validate AGENTS.md | `agents-md-validator` |

## SKILL VS BUILT-IN

| Domain | Use Skill | Or Built-In |
|--------|-----------|-------------|
| Git operations | — | Built-in git tools |
| JVM builds | `jvm` | Manual gradle/mvn commands |
| Code review | `kotlin-review` | General analysis |
| Diagrams | `mermaid-diagram-creator` | ASCII/text descriptions |