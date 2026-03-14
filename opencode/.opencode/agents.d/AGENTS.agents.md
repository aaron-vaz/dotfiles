# Agent & Model Configuration

## AGENT ASSIGNMENTS

| Agent | Model | Use Case |
|-------|-------|----------|
| sisyphus | kimi-k2.5 | Orchestration, delegation, main agent |
| hephaestus | glm-5 | Deep autonomous work, implementation |
| oracle | glm-5 | Architecture, debugging, consultation |
| librarian | minimax-m2.5-free | Docs/code search (free tier) |
| explore | minimax-m2.5-free | Codebase grep (free tier) |
| prometheus | kimi-k2.5 | Strategic planning |
| metis | kimi-k2.5 | Plan analysis, hidden intentions |
| momus | glm-5 | Quality review, plan verification |
| multimodal-looker | kimi-k2.5 | Image/document analysis |

## CATEGORY ASSIGNMENTS

| Category | Model | Use Case |
|----------|-------|----------|
| visual-engineering | gemini-3-flash | Frontend/UI/UX/styling/animation |
| ultrabrain | glm-5 | Hard logic problems, algorithms |
| deep | glm-5 | Autonomous research, complex tasks |
| artistry | gemini-3-flash | Creative design work |
| quick | minimax-m2.5-free | Trivial tasks, typo fixes |
| unspecified-low | kimi-k2.5 | Default low-effort tasks |
| unspecified-high | glm-5 | Default high-effort tasks |
| writing | kimi-k2.5 | Documentation, prose |

## DELEGATION PATTERNS

### When to Use Which Agent

| Task Type | Agent | Reason |
|-----------|-------|--------|
| Orchestration | sisyphus | Main coordinator, delegates to specialists |
| Implementation | hephaestus/deep | Deep work, autonomous execution |
| Architecture question | oracle | Read-only consultation |
| Unfamiliar library | librarian | External docs/examples |
| Find existing code | explore | Codebase grep, pattern discovery |
| Plan creation | prometheus | Strategic planning |
| Plan review | momus + metis | Quality + intention analysis |
| Code review | momus | Expert review |
| Visual/UI work | visual-engineering | Domain-optimized model |

### Delegation Rules

1. **Always delegate** work to specialized agents rather than implementing directly
2. **Use background agents** (librarian, explore) for research - never block
3. **Session continuity** - always use `session_id` for follow-up questions
4. **Verify delegation results** - check outputs match expected outcomes

## MODEL CAPABILITIES

| Model | Strengths | Weaknesses |
|-------|-----------|------------|
| kimi-k2.5 | Claude-like, orchestration, multimodal | Slower than free tier |
| glm-5 | Deep reasoning, autonomy, coding | Less conversational |
| gemini-3-flash | Visual tasks, frontend, fast | Lighter reasoning |
| minimax-m2.5-free | Fast, free, simple tasks | Limited capabilities |