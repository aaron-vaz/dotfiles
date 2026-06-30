---
name: conventional-commits
description: Use when committing code changes that need semantic versioning.
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: |
            if echo "$CLAUDE_BASH_COMMAND" | grep -q "git commit"; then
              # Extract commit message from command
              MSG=$(echo "$CLAUDE_BASH_COMMAND" | sed -n "s/.*-m ['\"]\\(.*\\)['\"].*/\\1/p")
              # Check if follows conventional format (type: description or type(scope): description)
              if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|chore|ci)(\(.+\))?: .+'; then
                echo '{"decision": "ask", "reason": "Commit message does not follow conventional format. Expected: type(scope): description"}' >&2
                exit 2
              fi
            fi
            exit 0
          timeout: 5
---

# Conventional Commits

This project uses semantic-release. Commit message format determines version bumps.

## Format
```
<type>(<optional scope>): <description>

[optional body]

[optional footer]
```

## Types and Version Bumps

| Type | Version Bump | Use For |
|------|--------------|---------|
| `fix:` | Patch (0.0.X) | Bug fixes |
| `feat:` | Minor (0.X.0) | New features |
| `BREAKING CHANGE:` | Major (X.0.0) | Breaking changes (in footer) |

## Other Types (no release)
- `docs:` - Documentation only
- `style:` - Formatting, whitespace
- `refactor:` - Code change that neither fixes nor adds
- `perf:` - Performance improvement
- `test:` - Adding or fixing tests
- `chore:` - Build process, dependencies
- `ci:` - CI configuration

- **Always `git add` before `git commit`** - check `git status` first; commits fail silently with "Changes not staged for commit" if files aren't staged. This has been a recurring issue.

## Critical: Branch Protection
**Never commit directly to master/main** - these branches are protected. Always create a feature branch first.

Pattern:
1. Create feature branch: `git checkout -b feature/description`
2. Make changes and commit: `git commit -m "type: description"`
3. Push to remote and create PR

If you're on master/main, stop and create a branch before committing.
