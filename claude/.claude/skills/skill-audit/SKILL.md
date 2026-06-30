---
name: skill-audit
description: Audit skill files for token waste — identifies content Claude already knows from training vs pain-learned project-specific rules. Run periodically or after adding new skills.
---

# Skill Audit

Audit `~/.claude/skills/` to identify token waste. Skills should be precision tools, not textbooks.

## The Litmus Test

For each instruction, ask:
1. **Would Claude do this correctly without being told?** → cut it
2. **Did this come from a real failure in a real session?** → keep the rule, consider trimming the explanation
3. **Is this a choice between valid approaches?** → one line stating the choice, cut justification
4. **Is it enforced by tooling (linters, CI, formatters)?** → cut it, tooling catches it

Write for the diff, not the default. Claude has read every language book and open-source codebase. It doesn't need general best practices — it needs what's different about your project.

## What to Keep
- Exact commands, file paths, tool names, API endpoints specific to this setup
- Rules that contradict common defaults (these came from pain)
- Toolchain gotchas (specific CLI bugs, version format quirks, API limitations)
- EG/org-specific knowledge
- Workflow structure and step ordering
- Choices between valid approaches (one line each)

## What to Cut
- Explanations of why a rule is good
- Examples of the wrong approach
- "When to Use / When NOT to Use" sections that restate the frontmatter description
- General language/framework idioms Claude defaults to correctly
- "Common Mistakes" sections that are preemptive coaching rather than real failures
- Output format templates (model formats well without rigid templates)
- Update/sync instructions for externally-sourced skills
- Meta-commentary ("This is important", "Always remember")

## Workflow

1. Run this prompt on all skills using Opus:

```
Read all SKILL.md files in ~/.claude/skills/ (recursively).
For each skill, apply the litmus test above.
Report: current lines, estimated lines after trim, % reduction,
specific line ranges to cut with reason (preemptive vs model-already-knows vs redundant),
what to keep and why (especially pain-learned rules).
Prioritize by highest token savings first.
Be conservative about pain-learned rules — keep the rule even when trimming the explanation.
```

2. Review the report — for each proposed cut, confirm it's not a pain-learned rule that just looks generic
3. Apply trims using parallel agents, one per skill
4. Commit: `chore(skills): trim token waste — N lines removed`

## Drift Detection

Signs a skill needs auditing:
- Grew by >20 lines without a matching incident or new toolchain integration
- Contains sections titled "Overview", "When to Use", "Review Philosophy", "Common Mistakes"
- Has more explanation lines than rule lines
- Contains language-level best practices (e.g., "prefer immutable variables", "use const over let")
