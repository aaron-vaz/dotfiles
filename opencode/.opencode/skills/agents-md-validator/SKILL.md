---
name: agents-md-validator
description: Validates AGENTS.md files for completeness, accuracy, and best practices. Checks command existence, file paths, structure, and scores documentation quality.
model: opencode-go/kimi-k2.5
---

# AGENTS.md Validator

Validates project and global AGENTS.md files for quality and accuracy.

## Usage

```bash
# Validate current project's AGENTS.md
@agents-md-validator

# Validate with verbose output
@agents-md-validator --verbose

# Validate specific file
@agents-md-validator /path/to/AGENTS.md
```

## What It Checks

### 1. Structure Validation
- [ ] Has main title (H1)
- [ ] Has overview/introduction section
- [ ] Has actionable sections (not just prose)
- [ ] Uses proper markdown hierarchy (no skipped levels)
- [ ] Contains code examples
- [ ] Uses tables for structured data

### 2. Command Validation
- [ ] All shell commands in code blocks are executable
- [ ] Commands use correct syntax for detected build system
- [ ] No deprecated or removed commands
- [ ] Build/test commands actually exist in project

### 3. Path Validation
- [ ] Referenced files exist (e.g., `./src/config.ts`)
- [ ] Directory structures are accurate
- [ ] Links to other docs are valid
- [ ] No broken internal references

### 4. Content Quality
- [ ] Examples are realistic and runnable
- [ ] No placeholder text (TODO, FIXME, XXX)
- [ ] Consistent terminology
- [ ] Appropriate level of detail (concise but complete)

### 5. Coverage Scoring

| Metric | Weight | Description |
|--------|--------|-------------|
| Structure | 20% | Proper organization and hierarchy |
| Commands | 25% | All documented commands exist and work |
| Paths | 20% | Referenced files/directories exist |
| Examples | 20% | Code examples are valid and helpful |
| Completeness | 15% | Covers major workflows and patterns |

**Score Ranges:**
- 90-100: Excellent - Production ready
- 80-89: Good - Minor improvements needed
- 70-79: Fair - Some issues to address
- 60-69: Poor - Significant gaps
- <60: Critical - Needs major rewrite

## Validation Rules

### Rule: No Placeholder Content
```
FAIL if content contains:
- "TODO" or "FIXME" or "XXX"
- "Coming soon" or "Not implemented"
- Empty code blocks
- Lorem ipsum
```

### Rule: Commands Must Exist
```
For each shell command block:
1. Extract the command (first word)
2. Check if it exists in PATH or package.json scripts
3. For build commands, verify against detected build system
4. Flag unknown commands
```

### Rule: Paths Must Exist
```
For each file/directory path:
1. Resolve relative to project root
2. Check if file/directory exists
3. Flag missing paths
4. Note: Paths in examples (e.g., `/home/user/...`) can be skipped
```

### Rule: Build System Consistency
```
Detected build system must match documented commands:
- Gradle project → ./gradlew commands
- Maven project → mvn commands
- npm project → npm/pnpm/yarn commands
- Cargo project → cargo commands
```

## Output Format

```
═══════════════════════════════════════════════════
AGENTS.md Validation Report
═══════════════════════════════════════════════════
File: ./AGENTS.md
Project: my-project
Build System: Gradle

STRUCTURE [18/20]
  ✓ Has main title
  ✓ Has overview section
  ✓ Uses proper heading hierarchy
  ✗ Missing code examples section

COMMANDS [22/25]
  ✓ ./gradlew build (exists)
  ✓ ./gradlew test (exists)
  ✗ ./gradlew lint (not found - did you mean check?)

PATHS [18/20]
  ✓ ./src/main/kotlin
  ✓ ./build.gradle.kts
  ✗ ./docs/CONTRIBUTING.md (not found)

EXAMPLES [18/20]
  ✓ All code blocks valid syntax
  ✓ Examples are runnable
  ✗ One example references non-existent file

COMPLETENESS [12/15]
  ✓ Build commands documented
  ✓ Test commands documented
  ✗ Debug workflow not covered
  ✗ Deployment process not covered

═══════════════════════════════════════════════════
TOTAL SCORE: 88/100 (Good)
═══════════════════════════════════════════════════

RECOMMENDATIONS:
1. Fix: ./gradlew lint → ./gradlew check
2. Create: ./docs/CONTRIBUTING.md or remove reference
3. Add: Debug workflow section with common issues
4. Add: Deployment/deep workflow documentation
```

## Best Practices Reference

### Good AGENTS.md Structure
```markdown
# Project Name

## Overview
Brief description of project purpose and architecture.

## Quick Start
```bash
./gradlew build
./gradlew test
```

## Project Structure
```
src/
├── main/
│   └── kotlin/
└── test/
    └── kotlin/
```

## Common Tasks

### Build
```bash
./gradlew build
```

### Test
```bash
./gradlew test
```

## Code Patterns

### Pattern Name
Description of when to use this pattern.

```kotlin
// Example code
```

## Troubleshooting

### Common Issue
Solution steps...
```

## Anti-Patterns to Avoid

1. **Wall of Text**: Use bullet points and tables
2. **Outdated Info**: Keep in sync with code changes
3. **Missing Examples**: Every concept needs a code example
4. **Generic Content**: Project-specific details only
5. **Broken Links**: Validate all references
