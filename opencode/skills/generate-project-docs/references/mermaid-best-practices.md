# Mermaid Best Practices

Best practices for generating clean, readable Mermaid architecture diagrams with non-overlapping arrows and proper layouts.

---

## Rules

### Use `flowchart` instead of `graph`

`flowchart` has better edge routing algorithms than `graph`.

```mermaid
flowchart TB
    A --> B
```

Not:
```mermaid
graph TB
    A --> B
```

---

### Set explicit direction for subgraphs

Use `direction LR` for horizontal layouts within vertical (TB) diagrams when you have multiple parallel components:

```mermaid
flowchart TB
    subgraph Layer["Layer Name"]
        direction LR
        A[Component1]
        B[Component2]
        C[Component3]
    end
```

This prevents components from stacking vertically and causing arrow overlaps.

---

### Fan-out pattern for multiple connections

When one component connects to multiple targets, ensure targets are in a subgraph with `direction LR` so arrows fan out cleanly rather than overlap:

```mermaid
flowchart TB
    Source[Source Component]

    subgraph Targets["Target Layer"]
        direction LR
        T1[Target1]
        T2[Target2]
        T3[Target3]
    end

    Source --> T1
    Source --> T2
    Source --> T3
```

---

### Keep related nodes in the same subgraph

Group nodes that share many connections to minimize edge crossings. Nodes in the same subgraph have shorter, cleaner connections.

---

### Order connection definitions logically

Define edges in visual order (left-to-right, top-to-bottom) as Mermaid sometimes uses definition order for layout hints:

```mermaid
flowchart TB
    %% Define left-to-right, top-to-bottom
    A --> B
    A --> C
    B --> D
    C --> D
```

---

### Avoid deep subgraph nesting

Maximum 2 levels of nesting. Flatten when possible.

**Bad:**
```mermaid
subgraph L1
    subgraph L2
        subgraph L3
            A
        end
    end
end
```

**Good:**
```mermaid
subgraph L1
    subgraph L2
        A
    end
end
```

---

### Move "bridge" components strategically

If a component connects two layers (like an API client or config), place it in the layer where it has fewer connections, or create a dedicated config/integration subgraph:

```mermaid
flowchart TB
    subgraph Application
        Service
    end

    subgraph Integration["Integration Layer"]
        direction LR
        APIClient[API Client]
        Config[Configuration]
    end

    subgraph External
        ExternalAPI
    end

    Service --> APIClient
    APIClient --> ExternalAPI
    Config --> Service
```

---

### Use invisible links for alignment when needed

```mermaid
flowchart TB
    A ~~~ B  %% invisible link to align A and B horizontally
```

This forces nodes to be on the same rank without a visible connection.

---

### Declare nodes before edges

Define all nodes in subgraphs first, then define all edges at the bottom of the diagram:

```mermaid
flowchart TB
    %% === NODES ===
    subgraph External["External"]
        Client[Client]
    end

    subgraph App["Application"]
        direction LR
        API[API]
        Service[Service]
    end

    subgraph Data["Data Layer"]
        DB[(Database)]
    end

    %% === EDGES ===
    Client --> API
    API --> Service
    Service --> DB
```

---

## Recommended Template

**Recommended architecture diagram structure:**

```mermaid
flowchart TB
    %% === EXTERNAL SYSTEMS ===
    subgraph External["External Systems"]
        direction LR
        Client[Client/Browser]
        ExtAPI[External APIs]
    end

    %% === APPLICATION LAYERS ===
    subgraph App["Application"]
        subgraph Controllers["Controller Layer"]
            direction LR
            REST[REST API]
            GQL[GraphQL]
        end

        subgraph Services["Service Layer"]
            direction LR
            SVC1[Service A]
            SVC2[Service B]
        end

        subgraph Processors["Processing Layer"]
            direction LR
            P1[Processor 1]
            P2[Processor 2]
            P3[Processor 3]
        end
    end

    %% === INFRASTRUCTURE ===
    subgraph Infra["Infrastructure"]
        direction LR
        DB[(Database)]
        Cache[(Cache)]
        Queue[Message Queue]
    end

    %% === EDGES (defined after all nodes) ===
    Client --> REST
    Client --> GQL
    REST --> SVC1
    GQL --> SVC2
    SVC1 --> P1
    SVC1 --> P2
    SVC1 --> P3
    SVC2 --> ExtAPI
    P1 --> DB
    P2 --> Cache
    P3 --> Queue
```
