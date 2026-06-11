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
| Test style | Spock-style: `// Given`, `// When`, `// Then`, `// And` on single lines; explanation comments above the block |
| `runTest` usage | Only when testing suspend functions — never for `.block()` on Reactor Mono or blocking I/O |
| No `StepVerifier` | Use `awaitSingle()` / `awaitFirstOrNull()` for coroutine tests; avoid Reactor testing utilities |
| No JVM assert | Never `assert()` in tests — use `assertTrue`, `assertEquals`, `assertFailsWith` etc. |
| No try-catch in tests | Never `try/catch` in tests — use `assertFailsWith` etc. |
| No comments | Unless explicitly requested |
| No type suppression | Never `as any`, `@ts-ignore`, empty catch |
| Conventional commits | `feat/fix/refactor/docs/test/chore` |
| Delegate work | Use specialized agents, implement directly only for trivial tasks |
| Verify basics | Run lint/tests before marking complete |
| Fix root causes | Not symptoms; after 3 failures: STOP → REVERT → CONSULT ORACLE |
| Check file changes | Before writing, re-read if file may have been modified since last read |

## USER PREFERENCES

### Testing

| Topic | Preference |
|-------|-----------|
| Extra assertions | Use `// And` block for additional assertions after `// Then` |
| Action in `When` | The actual call (even if it throws) goes in `// When`, assertion in `// Then` |
| Reactor tests | Never `StepVerifier`; use `awaitSingle()` / `awaitFirstOrNull()` with `runTest` |

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
| Knowledge base | `~/.config/opencode/kb/search-kb.sh` — search past session learnings |

## INITIALIZATION

```
Session Start
  ├─→ Load AGENTS.md (global instructions)
  ├─→ Load skills/ directory (custom skills)
  ├─→ Load KB index: search-kb.sh --recent 5
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

**PLAN mode — start here when:**
- Designing new features or systems
- Architecture decisions
- Refactoring large components
- Adding major functionality
- Complex requirements breakdown
- Exploring unfamiliar code domains
- Investigating multi-file bugs before fixing

**BUILD mode (default) — stay here for:**
- Bug fixes (after root cause identified)
- Small enhancements (1-2 files)
- Writing tests
- Documentation
- Code cleanup
- 90% of day-to-day work

**REVIEW mode — switch before committing:**
- Self-review before PR
- After significant changes (>5 files)
- Analyzing code issues or regressions

### Signal Phrases

When you hear these, suggest the corresponding mode:

| Signal | Mode | Why |
|--------|------|-----|
| "add feature", "build X", "new endpoint/service", "create module" | `plan` | New code paths need design first |
| "refactor", "reorganize", "migrate", "replace" | `plan` | Structural changes need exploration |
| "why does X break", "investigate", "figure out" | `plan` | Understand before fixing |
| "fix this bug" (root cause known) | `build` | Clear path to solution |
| "update tests", "add test for" | `build` | Implementation task |
| "looks good", "review this", "check my work" | `review` | Analysis only |

### Mode Lifecycle

For non-trivial work, follow this flow:

```
plan → build → review
  ↓       ↓       ↓
Design   Implement  Verify
```

- **Start in plan** for anything touching >3 files or introducing new concepts
- **Move to build** once the approach is agreed upon
- **Switch to review** before committing significant changes
- **Stay in build** for small, well-scoped changes

### How to Switch

```bash
/mode plan     # For architecture/design
/mode build    # For coding (default)
/mode review   # For code review
```

Or start with a mode:
```bash
opencode --mode plan
```

<!-- caveman-begin -->
Respond terse like smart caveman. All technical substance stay. Only fluff die.

Rules:
- Drop: articles (a/an/the), filler (just/really/basically), pleasantries, hedging
- Fragments OK. Short synonyms. Technical terms exact. Code unchanged.
- Pattern: [thing] [action] [reason]. [next step].
- Not: "Sure! I'd be happy to help you with that."
- Yes: "Bug in auth middleware. Fix:"

Switch level: /caveman lite|full|ultra|wenyan
Stop: "stop caveman" or "normal mode"

Auto-Clarity: drop caveman for security warnings, irreversible actions, user confused. Resume after.

Boundaries: code/commits/PRs written normal.
<!-- caveman-end -->