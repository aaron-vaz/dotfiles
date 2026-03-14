# PR Comment Formats

## Inline Comments (on diff lines)

```markdown
🔴 **Critical: [Issue title]**  (or 🟡 Important, 💡 Suggestion)

[Clear issue statement]

**Why it matters:** [Impact explanation]

**Suggested fix:**
\`\`\`tsx
[code suggestion]
\`\`\`

**Sources:**
- [Link to OWASP/MDN/official docs explaining the issue]
- [Link to relevant best practice or security advisory]

---
🤖 *AI-assisted review*
```

## Source Requirements

Always include sources to back up reasoning:
- Security issues → OWASP, CWE, or security advisories
- Best practices → Official docs (React, TypeScript, MDN, etc.)
- Performance → Browser/framework documentation
- Accessibility → WCAG guidelines, WAI-ARIA docs

## Summary Comment Header

All PR review summaries MUST start with:

```markdown
> 🤖 **AI-assisted review** - Please verify my reasoning before resolving. I may have missed context or gotten something wrong.

---
```

## Severity Icons

| Icon | Severity | Meaning |
|------|----------|---------|
| 🔴 | Critical | Must fix before merge |
| 🟡 | Important | Should fix, but not blocking |
| 💡 | Suggestion | Nice to have, optional |
| 🟣 | Pre-existing | Bug exists but was NOT introduced by this PR — worth noting, not blocking |

## Refinement Loop

**IMPORTANT: This happens PRIVATELY with your human partner, NOT in public GitHub comments.**

After presenting draft findings to your human partner, ask:
> "Review ready. Anything I missed, got wrong, or should dig deeper on?"

**On feedback:**
- Missed context → revisit Deep Context Scan
- Missed bugs → re-review targeted files
- Over-flagged → drop those items

**Loop until partner says "looks good" or "post it".**

**NEVER include refinement questions in the actual PR comments posted to GitHub.**
