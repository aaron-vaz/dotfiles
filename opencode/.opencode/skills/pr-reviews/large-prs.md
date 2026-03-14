# Large PR Strategy

If diff is huge:

1. **Ask if it can be split** (if not already merged)
2. **Focus on architectural changes first**
3. **Review file-by-file if needed**
4. **Prioritize new code over moved/renamed code**

## Triage Order

1. **New files** - Most likely to have issues
2. **Modified core logic** - High impact
3. **Test files** - Verify coverage
4. **Config changes** - Check for security/breaking changes
5. **Renamed/moved files** - Lowest priority (usually safe)

## Breaking Down Large Reviews

```bash
# Get changed files list (pipe through grep, gh pr diff has no --name-only flag)
$GH_HOST_ENV gh pr diff {number} | grep "^diff --git" | sed 's|.*b/||'

# Review specific directory (gh pr diff doesn't support file path filtering)
# Use git after checkout instead:
git -C /tmp/pr-review-{number} diff main -- src/components/
git -C /tmp/pr-review-{number} diff main -- src/api/
```

## When to Suggest Splitting

Suggest split if PR has:
- Multiple unrelated features
- Both refactoring AND new features
- Changes spanning 3+ unrelated modules
- More than ~500 lines of meaningful changes
