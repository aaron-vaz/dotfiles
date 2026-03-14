---
name: generate-project-docs
description: Generates comprehensive project documentation for engineer onboarding and knowledge transfer. Use when creating onboarding guides, documenting data flows, analyzing components, or mapping API endpoints. Always analyzes actual code rather than making assumptions.
model: minimax-m2.5
compatibility:
  - Any programming language
  - Any framework
  - Projects with source code access
metadata:
  version: 1.1.0
  category: documentation
  tags: [documentation, onboarding, architecture, api, components]
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
---

# Generate Project Docs Skill

This skill generates comprehensive project documentation for engineer onboarding and knowledge transfer. It analyzes actual source code to create accurate, detailed documentation rather than making assumptions.

## When to Use This Skill

Use this skill when you need to:
- Create onboarding guides for new engineers joining a project
- Document data flows or request flows through a codebase
- Deep dive into specific components, classes, or services
- Map and document REST/GraphQL API endpoints
- Generate architecture documentation with diagrams
- Create knowledge transfer documentation

## Quick Start

For most projects, start with **Onboarding Guide** (option 1) - it provides the foundation.

Then use other options to go deeper:
- **Flow Documentation** (option 2) - Trace specific request/data flows
- **Component Analysis** (option 3) - Deep dive into individual components
- **API Endpoints** (option 4) - Document REST/GraphQL endpoints

## Essential Principles

### Code-First Analysis

**NEVER make assumptions about the codebase.**

- Always analyze actual source code, configuration files, and existing documentation
- Cross-reference README.md and other existing docs, but verify claims against actual code
- If something in existing docs doesn't match the code, note the discrepancy
- If you can't find something in the code, say so explicitly

### Verify Claims

**Base all claims on actual code analysis.**

Every statement about how code works must be verified by reading the actual source:
- Read the file before describing what it does
- Don't assume behavior based on file names or conventions
- If behavior is unclear from the code, say so explicitly

### File Existence Check

**Before creating ANY document, check if it exists in claude-docs/.**

If file exists:
1. Inform user: "The file [filename] already exists (last modified: [date]). Would you like to regenerate it? This may be useful if new features, flows, or components have been added since [date]."
2. If user confirms, create new version with timestamp suffix (e.g., `Onboarding_v2_2025-01-26.md`)
3. Keep the old version

### Folder Management

**All documentation goes in claude-docs/ at project root.**

```
project-root/
└── claude-docs/
    ├── diagrams/          # Rendered diagram images
    ├── Onboarding.md
    ├── Flow_UserAuth.md
    └── ...
```

Create the folder structure if it doesn't exist.

### Diagram Restraint

**Only create diagrams that genuinely clarify.**

- Architecture overviews: YES
- Complex multi-step flows: YES
- Component relationships: YES
- Simple linear processes: NO
- Trivial relationships: NO
- Obvious structures: NO

### Ask Before Large Operations

**Confirm scope before extensive analysis.**

If documentation will require analyzing many files or complex flows, confirm with user:
- "This will require analyzing X files across Y directories. Proceed?"
- "The auth flow spans multiple services. Should I document all of them or focus on [specific area]?"

### File Links

**Use clickable markdown links for file references.**

Since docs are in `claude-docs/`, use relative paths with `../`:

```markdown
[ServiceName.kt](../src/main/kotlin/com/example/ServiceName.kt) (Lines 45-92)
```

This creates clickable links that work in most markdown viewers.

## Documentation Types

What documentation would you like to generate?

1. **Onboarding Guide** - Project overview, tech stack, structure, setup, learning path
2. **Flow Documentation** - Trace a specific data/request flow through the codebase
3. **Component Analysis** - Deep dive into a specific class, module, or service
4. **API Endpoints** - Document REST/GraphQL endpoints with schemas and handlers

**Wait for response before proceeding.**

## Workflow Routing

| Response | Workflow |
|----------|----------|
| 1, "onboarding", "overview", "getting started" | `workflows/create-onboarding-guide.md` |
| 2, "flow", "trace", "request flow", "data flow" | `workflows/create-flow-documentation.md` |
| 3, "component", "class", "module", "service", "analyze" | `workflows/create-component-analysis.md` |
| 4, "api", "endpoints", "rest", "graphql" | `workflows/create-api-endpoints.md` |

**After reading the workflow, follow it exactly.**

## Available Templates

All templates in `references/`:

**Document Templates:**
- `onboarding-template.md` - Structure for onboarding guides
- `flow-template.md` - Structure for flow documentation
- `component-template.md` - Structure for component analysis
- `api-template.md` - Structure for API documentation

**Diagram Guidelines:**
- `mermaid-best-practices.md` - Rules for clean, non-overlapping Mermaid diagrams

## Available Workflows

| Workflow | Purpose |
|----------|---------|
| `create-onboarding-guide.md` | Generate project onboarding documentation |
| `create-flow-documentation.md` | Document a specific data/request flow |
| `create-component-analysis.md` | Analyze a specific component in depth |
| `create-api-endpoints.md` | Document API endpoints and schemas |

## Prerequisites

**Before starting, check that `mmdc` (Mermaid CLI) is installed:**

```bash
mmdc --version
```

If not installed, inform the user:

> **Mermaid CLI (`mmdc`) is not installed.** Diagram rendering requires it.
> Install with: `npm install -g @mermaid-js/mermaid-cli`
>
> You can continue generating documentation, but Mermaid diagrams will remain as code blocks.
> To view unrendered diagrams, paste the Mermaid code into [Mermaid Live Editor](https://mermaid.live).

Proceed with documentation generation regardless - diagrams can be rendered later once `mmdc` is available.

## Diagram Rendering

**REQUIRED: After generating any document with Mermaid diagrams, run:**

```bash
python3 ~/.claude/skills/generate-project-docs/scripts/render_mermaid.py claude-docs/[document].md
```

This converts Mermaid code blocks to PNG images in `claude-docs/diagrams/` using the locally installed `mmdc` command.

If `mmdc` is not available, the script keeps the Mermaid code blocks in the document and appends a note with a link to [Mermaid Live Editor](https://mermaid.live) where the diagrams can be rendered online by pasting the code.

**Do not skip this step.** The document is not complete until diagrams are rendered (or noted as unrendered with a link).

## Success Criteria

Documentation is complete when:

- [ ] claude-docs/ folder exists with proper structure
- [ ] File existence was checked before creation
- [ ] All claims verified against actual code
- [ ] Code was actually analyzed (not assumed)
- [ ] Diagrams add genuine value (not decorative)
- [ ] Mermaid diagrams rendered to images (or noted with online rendering link if mmdc unavailable)
- [ ] User confirmed scope for large operations

## Best Practices

1. **Start with Onboarding**: The onboarding guide provides context for all other documentation
2. **Verify Everything**: Never assume based on file names - always read the code
3. **Use Clickable Links**: All file references should be clickable markdown links
4. **Diagram Sparingly**: Only add diagrams that genuinely clarify complex relationships
5. **Check Existing Docs**: Always check if documentation already exists before creating
6. **Confirm Large Scopes**: Get user approval before analyzing many files
7. **Render Diagrams**: Always run the rendering script after creating documents with Mermaid
8. **Note Discrepancies**: If existing docs don't match code, document the discrepancy

## Troubleshooting

### Issue: Mermaid diagrams not rendering

**Symptom**: Diagrams appear as code blocks instead of images

**Solution**:

1. Ensure `mmdc` is installed: `npm install -g @mermaid-js/mermaid-cli`
2. Run the rendering script after document creation:
```bash
python3 ~/.claude/skills/generate-project-docs/scripts/render_mermaid.py claude-docs/[document].md
```

If `mmdc` cannot be installed, paste the Mermaid code into [Mermaid Live Editor](https://mermaid.live) to view the diagrams.

### Issue: File links not clickable

**Symptom**: Links appear as plain text

**Solution**: Use the correct relative path format from `claude-docs/`:
```markdown
[FileName.kt](../src/main/kotlin/path/to/FileName.kt) (Line XX)
```

### Issue: Documentation seems incomplete

**Symptom**: Missing sections or shallow coverage

**Solution**: Follow the workflow exactly and complete all steps in the success criteria checklist.

## Additional Resources

- **Templates**: See `references/` directory for document templates
- **Workflows**: See `workflows/` directory for step-by-step guides
- **Mermaid**: See `references/mermaid-best-practices.md` for diagram guidelines
- **Scripts**: See `scripts/` directory for automation tools
