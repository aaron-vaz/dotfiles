# Create Onboarding Guide Workflow

## Required Reading

**Read these reference files NOW:**
1. `references/onboarding-template.md`
2. `references/mermaid-best-practices.md`

## Context

This workflow creates the ENTRY POINT document for new engineers.
It provides high-level understanding of the system - enough to build a mental model.
For deep dives, engineers use Flow, Component, or API workflows.

---

## Process

### Step 1: Setup Documentation Folder

```bash
mkdir -p claude-docs/diagrams
```

Check if `claude-docs/Onboarding.md` already exists:
```bash
ls -la claude-docs/Onboarding*.md 2>/dev/null
```

If exists, inform user with last modified date and ask about regeneration.

---

### Step 2: Analyze Executive Summary

Understand what this project does and why it matters:

1. **Read README.md** for project description
2. **Check package descriptions**: package.json, pyproject.toml, pom.xml
3. **Look for architecture docs**: ARCHITECTURE.md, docs/

Document:
- **What**: Type of project (microservice, library, API, etc.)
- **Why**: Business problem being solved
- **Who**: Target users, teams, or systems that use this
- **Scale**: Production characteristics if applicable (requests/day, regions)
- **Business Value**: How it fits in the larger system (numbered flow showing where this project sits)

---

### Step 3: Extract Technology Stack

Pull actual versions from configuration files:

**Create two tables:**

1. **Core Technologies**: Language, framework, database, runtime
2. **Key Dependencies**: Important libraries with versions and purposes

**For Node.js**: Read package.json
**For Python**: Read requirements.txt or pyproject.toml
**For JVM**: Read pom.xml or build.gradle

List each with actual version and purpose.

---

### Step 4: Document Project Structure

Explore and document the directory layout:

1. **List root directory** and major subdirectories
2. **Create directory tree** with inline comments for each section
3. **Count source files**: `find . -name "*.kt" -o -name "*.java" | wc -l` (adjust for language)
4. **Estimate lines**: `find . -name "*.kt" | xargs wc -l | tail -1`
5. **Identify architecture pattern**: layered, hexagonal, clean architecture, etc.

Example format:
```
project-root/
├── src/main/kotlin/
│   ├── api/           # HTTP/gRPC endpoint handlers
│   ├── service/       # Business logic
│   └── repository/    # Data access
└── pom.xml            # Build configuration
```

**Statistics**:
- **X** source files
- **~Y** lines of code
- **[Pattern]** architecture

---

### Step 5: Create Architecture Overview

**Follow `references/mermaid-best-practices.md` for clean diagrams.**

This section must include:

1. **Architecture pattern explanation**:
   - Name the pattern (layered, microservices, clean architecture, etc.)
   - List each layer with what it does and why

2. **System architecture diagram**:
   - External systems (clients, third-party APIs)
   - Application layers (API, service, data)
   - Infrastructure (databases, caches, queues)

3. **Request flow explanation** (numbered list):
   - How requests enter the system
   - What processing happens
   - Where data is stored/retrieved
   - How responses return

4. **Key design patterns used**:
   - Strategy, DI, Circuit Breaker, etc.
   - Where each is used

---

### Step 6: Identify Key Components

Map 4-6 major components with detailed context:

For each component document:

1. **Location**: Directory path
2. **What it does**: 2-3 sentences explaining:
   - What responsibility this component has
   - Why it exists (what problem it solves)
3. **Key classes/files**: 2-3 main files with one-sentence descriptions
4. **Dependencies**: What other components it depends on
5. **Used by**: What components use this one
6. **Deep dive pointer**: `/generate-project-docs` → option 3 → "[Name]"

Also create a **Component Dependency Map** diagram showing relationships.

---

### Step 7: Document Main Flows (High-Level)

Identify 2-4 primary request/data flows and document at HIGH LEVEL:

For each flow:
1. **Trigger**: What starts this flow (API call, event, job)
2. **Summary**: One paragraph describing end-to-end
3. **Components involved**: Chain like `A` → `B` → `C`
4. **High-level steps**: 3-5 steps without implementation details
5. **Deep dive pointer**: `/generate-project-docs` → option 2 → "[Flow Name]"

This is NOT detailed flow documentation - just enough to understand what happens.

---

### Step 8: Document API Contract (High-Level)

Provide overview of the API surface:

1. **API Overview table**: Endpoint Group | Base Path | Purpose
2. **Key Endpoints** (2-3 most important):
   - HTTP method and path
   - Purpose (one sentence)
   - Simplified request/response JSON
3. **Deep dive pointer**: `/generate-project-docs` → option 4

This is NOT full API documentation - just the contract shape.

---

### Step 9: Document Local Development Setup

Cross-reference README with actual configuration:

1. **Prerequisites Checklist** with checkboxes:
   - [ ] Prerequisite with version
   - Verification command for each
2. **Quick Start**: Step-by-step numbered commands
3. **Verify Setup**: Health check command + expected output

---

### Step 10: Document Testing

1. **Running Tests**: Commands for unit, integration tests
2. **Testing Endpoints**: Multiple methods (curl, gRPCurl, tools)
3. **Understanding Results**: Key response fields and what they mean

---

### Step 11: Document Key Concepts

Identify domain-specific terminology:

Create a table with Term | Definition for:
- Important domain concepts
- Project-specific terminology
- Acronyms used in the codebase

This helps engineers understand the "language" of the project.

---

### Step 12: Document Troubleshooting

1. **Common issues** (3-5): Symptom, cause, solution with commands
2. **Debugging tips**: General tips for this tech stack

---

### Step 13: Create Next Steps with Learning Path

Create a week-by-week learning path with clear targets:

**Week 1 – Setup & Orientation:**
- [ ] Prerequisites, build, run, test basics

**Week 2 – Core Understanding:**
- [ ] Key components with file references: [Component.kt](../src/main/kotlin/path/to/Component.kt)
- [ ] Main flow

**Week 3+ – Deep Dives & Advanced Topics:**
- Use other workflows for detailed documentation

**Priority Areas table**:
| Priority | Area | Type | Why Important | Command |
Star ratings: ⭐⭐⭐ Critical, ⭐⭐ Important, ⭐ Supplementary

**How to Use Other Workflows** reference table.

---

### Step 14: Document Additional Resources

Gather links to:
1. **Documentation**: Related docs, wikis, README files
2. **Communication**: Slack channels, team contacts
3. **Monitoring & Observability**: Dashboards, logging tools
4. **Deployment**: CI/CD pipelines, deployment tools

Check for these in README, docs/, or common locations.

---

### Step 15: Write the Document

Using the template from `references/onboarding-template.md`:

1. Fill in all sections with findings
2. **Executive Summary** with What/Why/Who/Scale/Business Value
3. **Project Structure** with directory tree and statistics
4. **Architecture** with pattern explanation before diagram
5. **Components** with 2-3 sentences each + dependencies
6. **Flows** at high level with deep dive pointers
7. **Week-by-week learning path** with week labels in Next Steps
8. Include "Deep dive" callouts throughout
9. Save to `claude-docs/Onboarding.md`

---

### Step 16: Render Diagrams

```bash
python3 ~/.claude/skills/generate-project-docs/scripts/render_mermaid.py claude-docs/Onboarding.md
```

Verify diagrams rendered successfully.

---

## Success Criteria

Onboarding guide is complete when:

- [ ] **Executive Summary** with What/Why/Who/Scale/Business Value
- [ ] **Tech Stack** with versions from config files (two tables)
- [ ] **Project Structure** with directory tree and statistics
- [ ] **Architecture Overview** with:
  - [ ] Pattern explanation
  - [ ] Layer descriptions
  - [ ] Architecture diagram
  - [ ] Request flow numbered list
  - [ ] Key design patterns
- [ ] **Key Components** with 2-3 sentences each + dependencies
- [ ] Component dependency map diagram
- [ ] **Main Flows** at high level with deep dive pointers
- [ ] **API Contract** shows shape with deep dive pointer
- [ ] **Local Development Setup** with prerequisites checklist
- [ ] **Testing** with multiple methods and result interpretation
- [ ] **Key Concepts** terminology table
- [ ] **Troubleshooting** with common issues (3-5)
- [ ] **Next Steps** with learning path and priority table
- [ ] **Additional Resources** with docs/Slack/monitoring links
- [ ] Deep dive callouts throughout
- [ ] Mermaid diagrams rendered
