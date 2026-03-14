# Custom Skills Reference

## INSTALLED SKILLS (11)

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| agents-md-updater | Documentation sync | After code changes, check if docs need updating |
| agents-md-validator | AGENTS.md validation | Validate structure, commands, paths, scoring |
| conventional-commits | Semantic versioning | Commit changes with proper versioning |
| find-skills | Skill discovery | Find/install new skills for specific tasks |
| generate-project-docs | Project documentation | Onboarding guides, API mapping, data flows |
| jvm | Gradle/Maven builds | Build/test issues, Java version errors |
| jvm-test-quality | Test coverage | Coverage gaps, branch coverage, test plans |
| kotlin-review | Kotlin patterns | Review PRs, idiomatic patterns |
| mermaid-diagram-creator | Diagrams | Flowcharts, sequence, state, class, ER diagrams |
| pr-review-learnings | PR feedback learning | Learn from human PR feedback |
| react-best-practices | React/Next.js | Write, review, refactor React code |
| self-review | Self code review | After committing, staff-level review |

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
| Kotlin PR review | `kotlin-review`, `pr-reviews` |
| Build/test JVM project | `jvm`, `jvm-test-quality` |
| React frontend work | `react-best-practices`, `frontend-ui-ux` |
| Create diagrams | `mermaid-diagram-creator` |
| Commit changes | `conventional-commits` |

## SKILL VS BUILT-IN

| Domain | Use Skill | Or Built-In |
|--------|-----------|-------------|
| Browser automation | — | `playwright`, `dev-browser` |
| Git operations | — | `git-master` |
| Frontend/UI | `react-best-practices` | `frontend-ui-ux` |
| Project docs | `generate-project-docs` | — |