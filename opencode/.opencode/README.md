# OpenCode Configuration

Personal OpenCode configuration with oh-my-opencode plugin, custom skills, and a modular documentation system.

## What This Is

This is a comprehensive configuration setup for [OpenCode](https://opencode.ai) (an open-source AI coding agent) that provides:

- **Multi-agent orchestration** via oh-my-opencode plugin
- **Custom skills** for domain-specific tasks (Kotlin, JVM, React, etc.)
- **Modular documentation** - AGENTS.md broken into referenced modules
- **Learnings system** - Captures corrections to prevent repeated mistakes
- **Knowledge base** - Searchable patterns from past sessions
- **Dotfiles integration** - Config managed via symlinks for version control

## Directory Structure

```
~/Code/shell/dotfiles/opencode/          # Dotfiles repo location
└── .opencode/                            # Actual config files
    ├── AGENTS.md                         # Main instructions (index)
    ├── agents.d/                         # Modular AGENTS.md components
    │   ├── AGENTS.agents.md              # Agent & model configuration
    │   ├── AGENTS.skills.md              # Custom skills reference
    │   ├── AGENTS.workflows.md           # Build/test/git/debug workflows
    │   ├── AGENTS.conventions.md         # Patterns & anti-patterns
    │   ├── AGENTS.config.md              # Configuration setup details
    │   └── AGENTS.learnings.md           # Learnings system reference
    ├── settings.json                     # OpenCode settings (mostly empty)
    ├── opencode.json                     # Provider config + plugins
    ├── oh-my-opencode.json               # Agent/category model assignments
    ├── install.sh                        # Symlink setup script
    ├── skills/                           # Custom skills (12 skills)
    │   ├── agents-md-updater/
    │   ├── agents-md-validator/
    │   ├── conventional-commits/
    │   ├── find-skills/
    │   ├── generate-project-docs/
    │   ├── jvm/
    │   ├── jvm-test-quality/
    │   ├── kotlin-review/
    │   ├── learnings/                    # NEW: Learnings manager
    │   ├── mermaid-diagram-creator/
    │   ├── pr-review-learnings/
    │   ├── react-best-practices/
    │   └── self-review/
    ├── kb/                               # Knowledge base
    │   └── search-kb.sh                  # KB search script
    ├── snippet/                          # Code snippets
    └── learnings/                        # Learnings database
        └── learnings.json                # Structured corrections/preferences

~/.config/opencode/                       # Symlinked location (active config)
├── AGENTS.md → ~/Code/shell/dotfiles/opencode/.opencode/AGENTS.md
├── agents.d/ → ~/Code/shell/dotfiles/opencode/.opencode/agents.d/
├── settings.json → ~/Code/shell/dotfiles/opencode/.opencode/settings.json
├── opencode.json → ~/Code/shell/dotfiles/opencode/.opencode/opencode.json
├── oh-my-opencode.json → ~/Code/shell/dotfiles/opencode/.opencode/oh-my-opencode.json
├── skills/ → ~/Code/shell/dotfiles/opencode/.opencode/skills/
├── kb/ → ~/Code/shell/dotfiles/opencode/.opencode/kb/
├── snippet/ → ~/Code/shell/dotfiles/opencode/.opencode/snippet/
└── learnings/ → ~/Code/shell/dotfiles/opencode/.opencode/learnings/
```

## How It Works

### 1. Symlink System

The config uses symlinks so all changes are tracked in the dotfiles git repo:

- **Source of truth**: `~/Code/shell/dotfiles/opencode/.opencode/`
- **Active location**: `~/.config/opencode/` (symlinked)
- **Install script**: `install.sh` creates all symlinks

When OpenCode runs, it reads from `~/.config/opencode/` which actually points to the dotfiles repo.

### 2. Modular AGENTS.md

Instead of one giant file, AGENTS.md is broken into modules:

- `AGENTS.md` - Main index with quick reference
- `agents.d/AGENTS.agents.md` - Agent & model configuration
- `agents.d/AGENTS.skills.md` - Custom skills reference
- `agents.d/AGENTS.workflows.md` - Build/test/git/debug workflows
- `agents.d/AGENTS.conventions.md` - Patterns & anti-patterns
- `agents.d/AGENTS.config.md` - Configuration setup details
- `agents.d/AGENTS.learnings.md` - Learnings system reference

This keeps the main file readable while allowing detailed reference material.

### 3. Agent Configuration

Agents are configured in `oh-my-opencode.json`:

| Agent | Model | Purpose |
|-------|-------|---------|
| sisyphus | kimi-k2.5 | Main orchestrator |
| hephaestus | glm-5 | Deep autonomous work |
| oracle | glm-5 | Architecture/debugging |
| librarian | minimax-m2.5-free | Docs/code search (free) |
| explore | minimax-m2.5-free | Codebase grep (free) |

Categories (task types) also have model assignments for domain optimization.

### 4. Custom Skills

Skills provide specialized instructions for specific domains:

| Skill | Purpose |
|-------|---------|
| `jvm` | Gradle/Maven builds, troubleshooting |
| `kotlin-review` | Kotlin idiomatic patterns |
| `react-best-practices` | React/Next.js development |
| `jvm-test-quality` | Test coverage and quality |
| `agents-md-validator` | Validate AGENTS.md files |
| `learnings` | Manage learnings database |

Load skills during delegation:
```typescript
task(category="quick", load_skills=["kotlin-review"], prompt="...")
```

### 5. Learnings System

Captures corrections to prevent repeated mistakes:

**Location**: `~/.config/opencode/learnings/learnings.json`

**Categories**:
- `misconceptions` - Things I got wrong
- `preferences` - User preferences
- `config` - Configuration details
- `commands` - Command corrections
- `patterns` - Code patterns learned
- `workflows` - Workflow corrections

**Example Entry**:
```json
{
  "id": "opencode-config-structure",
  "context": "Understanding config location",
  "whatIGotWrong": "Thought config was in dotfiles/opencode/",
  "correction": "Config is in dotfiles/opencode/.opencode/",
  "tags": ["config", "dotfiles"]
}
```

### 6. Knowledge Base

Searchable patterns from past sessions:

```bash
# Search KB
~/.config/opencode/kb/search-kb.sh "error pattern"
~/.config/opencode/kb/search-kb.sh --tag kotlin
~/.config/opencode/kb/search-kb.sh --medium
```

## Installation

### First-Time Setup

```bash
# 1. Backup existing config (if any)
mv ~/.config/opencode ~/.config/opencode.backup

# 2. Run install script
~/Code/shell/dotfiles/opencode/install.sh

# 3. Verify symlinks
ls -la ~/.config/opencode/
```

### What install.sh Does

1. Creates `~/.config/opencode/` directory
2. Symlinks individual files from `.opencode/` subdirectory
3. Symlinks directories (skills, kb, snippet, learnings)
4. Reports success for each component

## Making Changes

### To Update Config

**Important**: Always edit source files, NOT symlinks!

```bash
# 1. Navigate to source
cd ~/Code/shell/dotfiles/opencode/.opencode

# 2. Edit files (e.g., AGENTS.md, oh-my-opencode.json)
vim AGENTS.md

# 3. Changes are immediately active (symlinks reflect instantly)

# 4. Commit to track changes
cd ~/Code/shell/dotfiles
git add -A
git commit -m "config: update agent models"
git push
```

### To Add a Learning

When I make a mistake and you correct me:

```bash
# 1. Edit learnings.json
cd ~/Code/shell/dotfiles/opencode/.opencode/learnings
vim learnings.json

# 2. Add entry to appropriate category
# See AGENTS.learnings.md for format

# 3. Commit
cd ~/Code/shell/dotfiles
git add -A
git commit -m "learnings: add config structure correction"
git push
```

### To Add a Skill

```bash
# 1. Create skill directory
cd ~/Code/shell/dotfiles/opencode/.opencode/skills
mkdir my-skill

# 2. Create SKILL.md
cat > my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does
---

# My Skill

Instructions here...
EOF

# 3. Update install.sh if needed (for new directories)
# 4. Re-run install.sh
# 5. Commit changes
```

## Key Concepts

### Delegation Over Implementation

I should delegate to specialized agents rather than implement directly:

- Research → `librarian`, `explore` (background)
- Hard problems → `oracle`, `hephaestus`
- Planning → `prometheus`, `metis`, `momus`
- Visual work → `visual-engineering` category

### Skill Priority

User-installed skills override built-in defaults:

- `jvm` skill → use over generic build commands
- `kotlin-review` → use over generic code review
- `react-best-practices` → use over generic frontend

### Always Check First

Before making assumptions:

1. **Search learnings** - Did I get this wrong before?
2. **Search KB** - Any patterns from past sessions?
3. **Verify** - Check actual files, don't assume

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Symlink broken | Re-run `install.sh` |
| Config not loading | Check `ls -la ~/.config/opencode` |
| Skill not found | Verify directory exists in `skills/` |
| Changes not reflecting | Edit source files, not symlinks |
| Learnings not working | Check `learnings.json` syntax |

## Files Reference

| File | Purpose |
|------|---------|
| `AGENTS.md` | Main global instructions (index) |
| `agents.d/*.md` | Modular reference docs |
| `opencode.json` | Provider config + plugin list |
| `oh-my-opencode.json` | Agent/category model assignments |
| `settings.json` | OpenCode settings |
| `skills/*/SKILL.md` | Custom skill definitions |
| `learnings/learnings.json` | Corrections database |
| `kb/search-kb.sh` | KB search script |
| `install.sh` | Setup symlinks |

## See Also

- [OpenCode Documentation](https://opencode.ai/docs)
- [oh-my-opencode Plugin](https://www.opencode.live/ecosystem/oh-my-opencode/)
- `AGENTS.md` - Start here for usage instructions
- `agents.d/AGENTS.config.md` - Detailed config reference
