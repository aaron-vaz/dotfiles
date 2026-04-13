# OpenCode Global Instructions

Personal coding preferences and workflow conventions for AI-assisted development.

## OVERVIEW

Global configuration for OpenCode with custom skills and workflow conventions optimized for Kotlin/Gradle projects with React frontend support.

## QUICK START

```bash
# Search KB for past patterns
~/.config/opencode/kb/search-kb.sh "error pattern"

# Build/test commands
./gradlew build test spotlessCheck    # Gradle
npm run lint test build               # npm

# Git worktrees for parallel work
git worktree add -b feat-x .worktrees/feat-x main

# Update config
cd ~/Code/shell/dotfiles && git add -A && git commit -m "config: ..." && git push
```

## REFERENCES

| Topic | File |
|-------|------|
| Agent & Model Config | [`agents.d/AGENTS.agents.md`](./agents.d/AGENTS.agents.md) |
| Custom Skills | [`agents.d/AGENTS.skills.md`](./agents.d/AGENTS.skills.md) |
| Workflows (Build/Test/Git/Debug) | [`agents.d/AGENTS.workflows.md`](./agents.d/AGENTS.workflows.md) |
| Conventions & Anti-Patterns | [`agents.d/AGENTS.conventions.md`](./agents.d/AGENTS.conventions.md) |
| Configuration Setup | [`agents.d/AGENTS.config.md`](./agents.d/AGENTS.config.md) |
| Learnings & Corrections | [`agents.d/AGENTS.learnings.md`](./agents.d/AGENTS.learnings.md) |

## KEY CONVENTIONS

| Rule | Details |
|------|---------|
| No comments | Unless explicitly requested |
| No type suppression | Never `as any`, `@ts-ignore`, empty catch |
| Conventional commits | `feat/fix/refactor/docs/test/chore` |
| Delegate work | Use specialized agents, implement directly only for trivial tasks |
| Verify basics | Run lint/tests before marking complete |
| Fix root causes | Not symptoms; after 3 failures: STOP → REVERT → CONSULT ORACLE |
| Check file changes | Before writing, re-read if file may have been modified since last read |

## KEY ANTI-PATTERNS

| Never | Instead |
|-------|---------|
| Assume version numbers | Verify via web search or catalogs |
| Assume API signatures | Check docs with Context7 or web search |
| Shotgun debugging | Systematic hypothesis testing |
| Commit without request | Only when user asks |
| Force push main/master | Never on protected branches |
| Overwrite user changes | Re-read file before writing if user may have modified it |
| Trust snippet/grep output blindly | Verify actual file state (e.g., `git status` shows staged/unstaged, not untracked) |

## WHERE TO LOOK

| Task | Check |
|------|-------|
| Build config | `build.gradle.kts`, `settings.gradle.kts` |
| Dependencies | `gradle/libs.versions.toml` |
| Project structure | Project `AGENTS.md` or `CLAUDE.md` |
| Code patterns | Existing similar files in same module |
| Agent delegation | [`AGENTS.agents.md`](./agents.d/AGENTS.agents.md) |
| Skills available | [`AGENTS.skills.md`](./agents.d/AGENTS.skills.md) |

## INITIALIZATION

```
Session Start
  ├─→ Load AGENTS.md (global instructions)
  ├─→ Load skills/ directory (custom skills)
  └─→ Check project AGENTS.md (project-specific overrides)
```

## STRUCTURE

```
~/.config/opencode/
├── AGENTS.md              # This file - main index
├── agents.d/               # Referenced modules
├── settings.json           # OpenCode settings
├── opencode.json           # Provider config + plugins
├── skills/                 # Custom skills
├── kb/                     # Knowledge base
├── snippet/                # Code snippets
└── learnings/              # Corrections and preferences
    └── learnings.json      # Structured learnings database
```

## MODE SWITCHING

**OpenCode requires MANUAL mode switching (type `/mode <name>` in chat)**

| Mode | Best For | Model | Tools |
|------|----------|-------|-------|
| `build` | Coding, editing, testing (default) | kimi-k2.5 | All tools |
| `plan` | Architecture, design, analysis | glm-5.1 | Read-only |
| `review` | Code review, analysis | kimi-k2.5 | Read-only |

### When to Switch Modes

**Start with PLAN mode when:**
- Designing new features or systems
- Architecture decisions
- Refactoring large components
- Adding major functionality
- Complex requirements breakdown

**Stay in BUILD mode (default) for:**
- Bug fixes
- Small enhancements
- Writing tests
- Documentation
- Code cleanup
- 90% of day-to-day work

**Use REVIEW mode when:**
- Before committing significant changes
- Self-review before PR
- Analyzing code issues

### How to Switch

```bash
# In OpenCode chat:
/mode plan     # For architecture/design
/mode build    # For coding (default)
/mode review   # For code review

# Or start with mode:
opencode --mode plan
```