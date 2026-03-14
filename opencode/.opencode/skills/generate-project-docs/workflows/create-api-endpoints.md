# Create API Endpoints Workflow

## Required Reading

**Read these reference files NOW:**
1. `references/api-template.md`
2. `references/mermaid-best-practices.md`

## Critical Principle

**ALL content must be based on actual code.**
- Never make up endpoints, schemas, or behaviors
- If something doesn't exist in the code, don't include it
- Only document what you can verify by reading the source

## Formatting Rules

**Tables vs Lists:**
- **Tables for**: Endpoint Inventory, Permission Levels, Error Codes, Rate Limits, Integration Points
- **Lists for**: Query Parameters, Path Parameters, Status Codes, Test Files

**File Links:**
- Use format: `[FileName.kt](../src/main/kotlin/path/to/FileName.kt) (Line XX)`
- NOT: `/src/main/kotlin/path/to/FileName.kt#L28` (doesn't work)

---

## Process

### Step 1: Setup and Confirm Scope

```bash
mkdir -p claude-docs/diagrams
```

Ask user about scope:
- "Should I document all API endpoints or focus on a specific area (e.g., user endpoints, admin endpoints)?"
- "Does this project have multiple API versions to consider?"

Check for existing API documentation:
```bash
ls -la claude-docs/API_*.md 2>/dev/null
```

---

### Step 2: Identify API Framework

Determine how routes are defined:

**Express.js:**
- Look for `app.get/post/put/delete` or `router.*`
- Check for route files in `routes/` or `api/`

**FastAPI:**
- Look for `@app.get/post` decorators
- Check `routers/` directory

**Django/DRF:**
- Check `urls.py` for URL patterns
- Look for ViewSets and routers

**Spring:**
- Look for `@RestController`, `@RequestMapping`
- Check `*Controller.java` files

**NestJS:**
- Look for `@Controller`, `@Get`, `@Post` decorators
- Check `*.controller.ts` files

Document the framework and routing pattern used.

---

### Step 3: Discover All Endpoints

Systematically find all endpoints:

1. **Search for route definitions** using framework-specific patterns
2. **Build inventory** of all endpoints found
3. **Group by resource** (users, products, orders, etc.)
4. **Note HTTP methods** for each path

For each endpoint, record:
- HTTP method (GET, POST, PUT, DELETE, PATCH)
- Path pattern (including path parameters)
- Handler file reference: [ControllerName.kt](../src/main/kotlin/path/to/ControllerName.kt) (Line XX)

---

### Step 4: Analyze Each Endpoint

For each endpoint, document:

1. **Handler function**: Read the implementation
   - File reference: [Controller.kt](../src/main/kotlin/path/to/Controller.kt) (Line XX)

2. **Request schema** (use LISTS, not tables):
   - Path parameters: `paramName` (type, required/optional) - Description
   - Query parameters: `paramName` (type, optional) - Default: `value`. Description
   - Request body structure as JSON

3. **Response schema**:
   - Success response as JSON
   - Status codes as LIST: `200` - Success, `401` - Unauthorized
   - Error responses as JSON examples

4. **Validation**: Link to validator file if exists

Use TypeScript types, Pydantic models, or schema definitions if available.

---

### Step 5: Document Authentication/Authorization

Find how endpoints are protected:

1. **Auth middleware**: What guards the routes
2. **Auth methods**: JWT, session, API key, OAuth
3. **Permission levels**: Public, authenticated, admin, specific roles
4. **Per-endpoint requirements**: Which endpoints need what auth

Look for:
- Middleware attached to routes
- Decorators (`@authenticated`, `@requires_permission`)
- Guards or interceptors

---

### Step 6: Trace Middleware Chain

Document what middleware runs before handlers:

1. **Global middleware**: Applied to all routes
2. **Route-specific middleware**: Applied to specific paths
3. **Order of execution**: Sequence middleware runs in

For each middleware:
- Purpose (logging, auth, rate limiting, etc.)
- Configuration options
- How it modifies request/response

---

### Step 7: Identify External Integrations

Find which endpoints call external services:

1. **Outbound HTTP calls**: Other APIs consumed
2. **Database operations**: Which tables/collections
3. **Message queue publishing**: Events emitted
4. **Third-party services**: Payment, email, storage, etc.

Create an integration map showing connections.

---

### Step 8: Create API Architecture Diagram

**Follow `references/mermaid-best-practices.md` for clean, non-overlapping diagrams.**

Create a diagram showing:
- API structure/groupings
- Authentication flow
- Major integration points

**Example API architecture diagram:**
```mermaid
flowchart TB
    %% === NODES ===
    subgraph Clients["Clients"]
        direction LR
        Web[Web App]
        Mobile[Mobile App]
        External[External Services]
    end

    subgraph Gateway["API Gateway"]
        Auth[Authentication]
        RateLimit[Rate Limiting]
    end

    subgraph API["API Endpoints"]
        direction LR
        Users[/users]
        Products[/products]
        Orders[/orders]
    end

    subgraph Services["Backend Services"]
        direction LR
        UserSvc[User Service]
        ProductSvc[Product Service]
        OrderSvc[Order Service]
    end

    subgraph Data["Data Layer"]
        direction LR
        DB[(Database)]
        Cache[(Cache)]
    end

    %% === EDGES ===
    Web --> Auth
    Mobile --> Auth
    External --> Auth
    Auth --> RateLimit
    RateLimit --> Users
    RateLimit --> Products
    RateLimit --> Orders
    Users --> UserSvc
    Products --> ProductSvc
    Orders --> OrderSvc
    UserSvc --> DB
    ProductSvc --> Cache
    OrderSvc --> DB
```

---

### Step 9: Write the Document

Using the template from `references/api-template.md`:

1. **Table of Contents** at the top
2. **Endpoint Inventory** as table (Method | Path | Handler | Auth | Description)
3. **Each endpoint** with:
   - Handler file link: [Controller.kt](../path) (Line XX)
   - Query/Path parameters as LISTS
   - Status codes as LISTS
   - Request/Response as JSON
4. **Auth requirements** per endpoint
5. **Middleware chain** as numbered list
6. **Integration map** as table

Save to `claude-docs/API_Endpoints.md`

---

### Step 10: Render Diagrams

```bash
python3 ~/.claude/skills/generate-project-docs/scripts/render_mermaid.py claude-docs/API_Endpoints.md
```

---

## Success Criteria

API documentation is complete when:

- [ ] Table of Contents at top
- [ ] API framework identified with routing pattern
- [ ] All endpoints discovered and inventoried (as table)
- [ ] Each endpoint has:
  - [ ] Handler file link: [Controller.kt](../path) (Line XX)
  - [ ] Query/Path parameters as LISTS
  - [ ] Status codes as LISTS
  - [ ] Request/Response as JSON
- [ ] Authentication requirements documented per endpoint
- [ ] Middleware chain traced (as numbered list)
- [ ] External integrations mapped (as table)
- [ ] API architecture diagram created
- [ ] Diagrams rendered to images
