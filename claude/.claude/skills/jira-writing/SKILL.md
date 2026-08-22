---
name: jira-writing
description: Use when creating Jira issues from tech docs, meeting notes, one-liners, or bug reports.
---

# Jira Writing

## Your Jira Format

**Title Pattern:**
- With tag: `[Tag] Action verb + description` (for epics, backend-only, frontend-only features)
- Without tag: `Action verb + description`

**Body Structure:**
```markdown
## **Background**
[Business context, why it matters, integration points - REQUIRED]

## **Tech hints** (optional)
[Implementation details, architecture decisions, bullet points]

## **Acceptance Criteria**
[Concrete outcomes as bullet points - REQUIRED]

## **Reference** (optional)
[Links to related docs, tech discoveries, specs]
```

**Formatting Conventions:**
- Section headers: `## **Header**` (double asterisks for bold)
- Bullet points where appropriate
- Links: `[Text](URL)`
- Tech hints: Note-style bullets, can be incomplete sentences

## Extraction Workflows

### From Tech Discovery Document

**When:** You have a tech discovery Confluence page or detailed technical spec

**Command:** "Create Jira from tech doc: [link or paste content]"

**Process:** Load extract-tech-doc.md pattern (see that file for details)

## Workflow Steps

1. **Load extraction pattern** - Based on input type
2. **Extract/build sections** - Background (required), Acceptance Criteria (required), Tech hints (optional), Reference (optional)
3. **Present draft** - Show formatted Jira body for review
4. **Get title** - Suggest tag if applicable, get user approval
5. **User reviews** - Make changes if needed
6. **Create Jira** - Use Atlassian MCP tools

## Jira Creation Settings

**Default values** — read the Cloud ID and project key from `~/.localrc`
(machine-specific, untracked); this repo is public, so they don't live here:
- Cloud ID: `$JIRA_CLOUD_ID`
- Project: `$JIRA_PROJECT_KEY` (can be overridden per issue)
- Issue type: `Story` (can be changed to Task, Bug, Epic)
- Assignee: Unset (uses project default)

**What this skill WON'T do:**
- Won't auto-post without approval — this applies to issue creation, comments, AND transitions
- Won't guess at missing required sections
- Won't change your writing style

**Draft-first rule for ALL Jira writes:**
Before calling `addCommentToJiraIssue`, `transitionJiraIssue`, `editJiraIssue`, or `createJiraIssue`:
1. Show the user exactly what will be posted/changed
2. Wait for explicit approval
3. Only then call the tool

## Atlassian MCP Tool Usage

**When updating/creating Jira descriptions:**

Use plain markdown strings, NOT ADF format:

```json
{
  "description": "## **Background**\n\nText here...\n\n## **Acceptance Criteria**\n\n- Item 1\n- Item 2"
}
```

**DON'T use ADF format** (this fails with "Failed to convert markdown to adf"):
```json
{
  "description": {
    "type": "doc",
    "version": 1,
    "content": [...]
  }
}
```

The MCP tool handles markdown-to-ADF conversion internally. Send markdown strings directly.

**Jira comments cannot be edited** -- the Atlassian MCP has no `editComment` tool. To fix a posted comment, delete it with `deleteCommentFromJiraIssue` and re-post. For `addCommentToJiraIssue` with ADF format, the `commentBody` parameter must be a JSON **object** (the ADF doc node), not a stringified JSON string.

**`createJiraIssue` double-escapes `\n` in the `description` parameter.** Passing description directly in `createJiraIssue` renders as literal `\n` text in Jira — newlines and section breaks are lost. Always use a three-step pattern:
1. `createJiraIssue` with summary + issuetype only (no description)
2. `editJiraIssue` with `fields.description` + top-level `contentFormat: markdown` — this path handles newlines correctly
3. `editJiraIssue` for custom fields (Pod, Functional Area) if not done in step 2

Confirmed failure: EGEXP-18669 (2026-06-16) — description created via `createJiraIssue` rendered as one unformatted block. Fixed by re-posting via `editJiraIssue` with `contentFormat: markdown`.

**`createJiraIssue` silently drops some custom fields from `additional_fields`.** Confirmed drops on EGEXP: `customfield_10317` (Pod) and `customfield_10361` (Functional Area) are accepted by the schema but not persisted. Steps 2+3 above can be combined into one `editJiraIssue` call.

**EGEXP required custom fields on every new story/epic:**
- `customfield_10317` — Pod (e.g. "Readout and Trustworthiness")
- `customfield_10361` — Functional Area (e.g. "Clickstream & Experimentation - Experimentation")

**Source the values from a sibling ticket, not the parent epic.** Epics are often created with these fields blank; sibling stories in the same pod carry the correct values. Before creating a new child, `getJiraIssue` on a recent sibling in the same pod and copy Pod + Functional Area from there.

**Blank lines between bullets break the list in markdown→ADF conversion.** `editJiraIssue` roundtrips description through ADF and treats a blank line between list items as a section terminator — items after the blank line are silently dropped or split into a new block. Write bullet lists compactly with no interleaved blank paragraphs:

```markdown
- Item 1
- Item 2
- Item 3
```

Not:
```markdown
- Item 1

- Item 2

- Item 3
```

After any `editJiraIssue` description update, `getJiraIssue` and diff to confirm no bullets/milestones were chopped.

**`transitionJiraIssue` Resolution field gotcha.** Some workflow transitions (notably "Done" / "Closed" on EGEXP stories) require `Resolution` but reject explicit values like `{"resolution": {"name": "Done"}}` with `"The selected resolution cannot be chosen during this action."`. The valid resolution is workflow-specific and cannot be discovered from the transition payload alone. Workflow:
1. `getJiraIssue` on a recently-resolved sibling ticket in the same project
2. Read its `fields.resolution.name` (e.g. `"Fixed"`, `"Done"`, `"Won't Do"`)
3. Pass that exact value: `{"transition": {"id": "31"}, "fields": {"resolution": {"name": "<sibling-value>"}}}`
4. If that still fails, the workflow may not accept *any* resolution from this transition — try a different transition id (e.g. "Resolve Issue" instead of "Done"), or transition without `fields` first and let the workflow default fire.

Recurring failure pattern (4x identical errors on EGEXP-18447, 2026-05-22): looping `transitionJiraIssue` with different `resolution.name` values without first fetching a working sibling — never converges, just rotates through "cannot be chosen" errors.

**Confluence CQL search (`searchConfluenceUsingCql`) quirks:**
- `limit` must be a **number**, not a string — `"limit": 5` fails validation; use `"limit": 5` as integer.
- Valid CQL space fields are `space.key`, `space.type`, `space.category`, `space.title` — there is no `space.creator`.
- `space.title = "..."` often errors with "Could not parse cql" — prefer `space.key = "<KEY>"` when targeting a specific space.
- When a Confluence URL is known, skip CQL entirely and use `getConfluencePage`/page-id lookups instead of search.

## Quick Reference

| Input Type | Required Sections | Optional Sections | Tag Suggestion |
|------------|------------------|-------------------|----------------|
| Tech doc | Background, AC | Tech hints, Reference | Check for backend/frontend/epic |
| Meeting notes | Background, AC | Tech hints, Reference | Based on discussion scope |
| One-liner | Background, AC | Tech hints, Reference | Based on expanded context |
| Bug report | Background, AC | Tech hints, Reference | Usually no tag |
