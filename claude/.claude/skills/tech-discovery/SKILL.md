---
name: tech-discovery
description: Use when creating technical discovery documents for new features or system enhancements, before implementation.
---

# Tech Discovery Writing

## Overview

Automates creation of technical discovery documents by guiding through structured sections and producing consistent documentation.

**Core principle:** Separate design exploration from documentation.

## When to Use

Use when you need to create a tech discovery document from:
- A PRD or requirements document that needs technical elaboration
- A problem statement that needs solution exploration
- An existing system that needs enhancement
- A blank page (full questionnaire mode)

**When NOT to use:**
- Retrospective documentation (this is for planning before implementation)
- Simple feature specs
- Architecture decision records (different format)

## Standard Tech Discovery Template

```markdown
## Background
[Problem statement - what's broken or inefficient]
[Business motivation - why this matters]
[Current state and pain points]

## Problem Statement
[Key pain points as bullets]
[What needs to change]

## Requirements

#### General
[Cross-cutting requirements]

#### [Component/Area Name]
[Specific requirements for this component]

## Proposed Solution

[High-level architecture overview]

### [Component Name]
[Component description and responsibilities]
[Implementation details as bullets]

## Tasks

### [Component/Area Name]
* Task breakdown as bullets
* With implementation details

## References
[Links to PRDs, related docs, diagrams]
```

**Formatting Conventions:**
- `##` for main sections, `###` for subsections, `####` for requirement categories
- Bullets for lists, requirements, tasks
- Tasks organized by component/area

## Workflow Steps

1. **Scaffold initial sections** — Background, Problem Statement, Requirements
2. **Present draft** — Show sections for review
3. **Explore architecture** — work through design alternatives with the user
4. **Document architecture** — Capture chosen design in Proposed Solution
5. **Generate Tasks** — Break down implementation by component
6. **Compile References** — Link to source docs

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping architecture exploration | Always explore design alternatives before documenting |
| Missing Requirements before Solution | Complete Background/Problem/Requirements before architecture |
| Task list too vague | Break down by component with specific implementation details |
| Missing integration points | Document how components interact |
| Generic problem statement | Be specific about pain points and stakeholders |
| Inventing API / class / field names | Describe capabilities — leave concrete names to implementation |
| Misframing logic ownership | Be explicit whether a component is system of record, extension, enrichment, or workaround |
| Adding engineering preferences to "Proposed Solution" | Only include decisions the requirements/design explicitly produced |
| Conflating implementation tickets with feasibility | Open questions → "Investigate / spike" tasks, not implementation tasks |
| Silent legacy-path treatment | State explicitly whether legacy paths are preserved, removed, or deprecated |

## Quick Reference

| Starting Point | Initial Sections | Focus | Output |
|----------------|------------------|-------|--------|
| PRD | Extract Background/Problem/Requirements | Architecture design | Complete tech discovery |
| Problem | Guide Requirements gathering | Architecture design | Complete tech discovery |
| Existing system | Analyze current + enhancement needs | Migration + enhancement design | Complete tech discovery |
| Blank slate | Full questionnaire | Architecture design | Complete tech discovery |
