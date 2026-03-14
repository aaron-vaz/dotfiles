# Create Component Analysis Workflow

## Required Reading

**Read these reference files NOW:**
1. `references/component-template.md`
2. `references/mermaid-best-practices.md`

## Critical Principle

**ALL content must be based on actual code.**
- Never make up metrics, configurations, or behaviors
- If something doesn't exist in the code, don't include it
- Only document what you can verify by reading the source

---

## Process

### Step 1: Setup and Identify Component

```bash
mkdir -p claude-docs/diagrams
```

Ask user to specify which component to analyze:
- "Which component would you like to analyze? (e.g., AuthService, UserRepository, PaymentProcessor)"
- "Please provide the file path or class/module name."

Check for existing analysis:
```bash
ls -la claude-docs/Component_*.md 2>/dev/null
```

---

### Step 2: Locate and Read Component

Find the component in the codebase:

1. **Search by name**: Use grep/glob to find the file
2. **Read the entire file**: Understand the full implementation
3. **Count lines**: Note total lines of code
4. **Identify boundaries**: Single file vs. directory/package

Document with clickable link (relative from claude-docs/):
**File**: [ComponentName.kt](../src/main/kotlin/com/example/ComponentName.kt) (X lines)

---

### Step 3: Analyze Overview & Purpose

Determine what this component does:

1. **Primary responsibility**: What is its main job?
2. **Position in system**: Where does it sit in the architecture?
3. **Key characteristics** (focus on architecture):
   - Architecture pattern (Strategy, Facade, Service, etc.)
   - Design principles (SRP, DI, etc.)
   - Core dependencies (2-3 main ones)
   - Stateless vs stateful

Create "The One-Line Summary":
> **[ComponentName] [does X] by [doing Y] to [achieve Z].**

---

### Step 4: Document The Core Problem It Solves

Explain what you'd have to do WITHOUT this component:

1. **Without the component**: List all manual steps required
2. **Create a complexity diagram** showing those steps
3. **With the component**: Show the simple API call that handles everything

This establishes the value proposition clearly.

---

### Step 5: List Key Features & Design Decisions

Create a simple list of major architectural/implementation decisions.

**NO diagrams in this section** - diagrams go in method sections.

For each feature/decision:
- What it is
- Why this approach was chosen

Example:
- **Reactive Streams**: Uses Flux for non-blocking processing of large datasets
- **Strategy Pattern**: Allows swapping sorting algorithms at runtime
- **Fail-fast validation**: Validates all inputs before processing begins

---

### Step 6: Create Architecture Section

**Follow `references/mermaid-best-practices.md` for clean diagrams.**

Document:
1. **Component position in system**: Text hierarchy showing where it sits
2. **Component structure diagram**: Show methods and dependencies

---

### Step 7: Document Public Methods (CENTRALIZED)

**This is the main section.** For each public method, document EVERYTHING about it in one place:

1. **File and line range**: [File.kt](../src/main/kotlin/path/to/File.kt) (Lines X-Y)
2. **Purpose**: One sentence
3. **Signature**: Full method signature
4. **Parameters**: As a list (not table)
5. **Returns**: What it returns
6. **Processing Behavior** - detailed steps:
   - Each step with line references
   - Code snippets showing actual code
   - Detailed explanation of what happens
7. **Flow Diagram**: Sequence diagram for this specific method
8. **Edge Cases**: With line references

**Example Processing Behavior format:**

````
**Step 1: Validation** (Lines 45-52)

[Explanation of what happens]

```kotlin
// Lines 45-52
val validated = input.validate()
if (!validated.isValid) {
    throw ValidationException(validated.errors)
}
```
````

Do NOT create separate "Algorithm Details" section - keep everything centralized per method.

---

### Step 8: Create Decision Guide (if multiple methods)

If component has multiple public methods:

1. **Flowchart**: When to use which method
2. **Comparison table**: Method | Use Case | Latency (only if latency data exists in code)

---

### Step 9: Create Real-World Scenarios

Document 2-3 real-world usage scenarios:

For each scenario:
1. **Context**: When does this happen?
2. **Code example**: Actual usage pattern
3. **What happens internally**: Step-by-step
4. **Request/Response payloads**: JSON examples

---

### Step 10: Document Debugging & Observability

**ONLY document what actually exists in the code:**

1. **Common Issues**: Error conditions found in actual code
   - Exception types thrown
   - Error messages from code
   - Line references

**Do NOT include:**
- Made-up metrics (unless they exist in code)
- Tracing functionality (unless it exists in code)
- Generic debugging advice

If no observability exists, state: "This component has minimal observability. Consider adding logging for [specific areas]."

---

### Step 11: Create Key Takeaways

Summarize 5-7 key points that someone MUST understand about this component.

---

### Step 12: Create Next Steps for Learning

1. **Related Components**: List with rationale for why to study next
2. **Common Questions**: Q&A format

---

### Step 13: Write the Document

Using the template from `references/component-template.md`:

1. Fill in all sections with findings from actual code
2. **Key Features** = simple list (no diagrams)
3. **Public Methods** = centralized with all details per method
4. **Debugging** = only actual code behaviors (no made-up metrics)
5. Verify every claim against source code

**Do NOT include:**
- "Usage from:" references
- Configuration section (params already in method signatures)
- Made-up metrics or tracing

Save to `claude-docs/Component_[ComponentName].md`

---

### Step 14: Render Diagrams

```bash
python3 ~/.claude/skills/generate-project-docs/scripts/render_mermaid.py claude-docs/Component_[ComponentName].md
```

---

## Success Criteria

Component analysis is complete when:

- [ ] Table of Contents at top
- [ ] Component file as clickable link: [Name.kt](../path/to/Name.kt)
- [ ] Overview with one-line summary and key characteristics
- [ ] "The Core Problem It Solves" with before/after
- [ ] Key Features as simple list (NO diagrams)
- [ ] Architecture with component position and structure diagram
- [ ] Each Public Method has CENTRALIZED documentation:
  - [ ] Signature, parameters, returns
  - [ ] Processing Behavior with code snippets and line refs
  - [ ] Flow diagram for that specific method
  - [ ] Edge cases with line refs
- [ ] Decision Guide (if multiple methods)
- [ ] Real-World Scenarios with JSON payloads
- [ ] Debugging based ONLY on actual code (no made-up metrics)
- [ ] Key Takeaways (5-7 points)
- [ ] ALL content verified against actual source code
- [ ] NO separate Algorithm Details section
- [ ] NO Configuration section
- [ ] Diagrams rendered to images
