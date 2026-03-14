# API Template

## Overview

This template defines the structure for documenting API endpoints.
All endpoints should be discovered from actual code, not assumed.

---

## Output Template

````markdown
# API Documentation

> Generated: [DATE]
> Framework: [Express/FastAPI/Django/Spring/etc.]
> Base URL: [If applicable]

## Table of Contents

1. [Overview](#overview)
2. [API Architecture](#api-architecture)
3. [Endpoint Inventory](#endpoint-inventory)
4. [Authentication](#authentication)
5. [Middleware Chain](#middleware-chain)
6. [Endpoints by Resource](#endpoints-by-resource)
7. [Error Response Format](#error-response-format)
8. [Rate Limiting](#rate-limiting)
9. [Integration Points](#integration-points)
10. [Testing the API](#testing-the-api)

---

## Overview

**Total Endpoints**: [N]
**API Version**: [v1/v2/etc. if versioned]
**Authentication**: [Primary auth method]

---

## API Architecture

```mermaid
flowchart TB
    subgraph Gateway["API Gateway"]
        LB[Load Balancer]
    end

    subgraph Middleware["Middleware"]
        Auth[Auth]
        Rate[Rate Limiting]
        Log[Logging]
    end

    subgraph Routes["Routes"]
        direction LR
        R1[/users]
        R2[/products]
        R3[/orders]
    end

    subgraph Services["Services"]
        direction LR
        S1[UserService]
        S2[ProductService]
        S3[OrderService]
    end

    LB --> Auth
    Auth --> Rate
    Rate --> Log
    Log --> R1
    Log --> R2
    Log --> R3
    R1 --> S1
    R2 --> S2
    R3 --> S3
```

---

## Endpoint Inventory

| Method | Path | Handler | Auth | Description |
|--------|------|---------|------|-------------|
| GET | /users | [UserController.kt](../src/main/kotlin/com/example/UserController.kt) (Line 25) | Required | List all users |
| POST | /users | [UserController.kt](../src/main/kotlin/com/example/UserController.kt) (Line 45) | Required | Create user |
| GET | /users/:id | [UserController.kt](../src/main/kotlin/com/example/UserController.kt) (Line 67) | Required | Get user by ID |
| PUT | /users/:id | [UserController.kt](../src/main/kotlin/com/example/UserController.kt) (Line 89) | Required | Update user |
| DELETE | /users/:id | [UserController.kt](../src/main/kotlin/com/example/UserController.kt) (Line 112) | Admin | Delete user |

---

## Authentication

### Method: [JWT/Session/API Key/OAuth]

**Configuration**: [AuthConfig.kt](../src/main/kotlin/com/example/AuthConfig.kt) (Line XX)

**How It Works**:
[Brief explanation of auth flow]

**Header Format**:
```
Authorization: Bearer <token>
```

### Permission Levels

| Level | Description | Endpoints |
|-------|-------------|-----------|
| Public | No auth required | GET /health, GET /docs |
| Authenticated | Valid token required | GET /users, POST /orders |
| Admin | Admin role required | DELETE /users/:id |

---

## Middleware Chain

Request flows through middleware in this order:

1. **[Middleware Name]** - [Middleware.kt](../src/main/kotlin/com/example/Middleware.kt) (Line XX)
   - Purpose: [What it does]
   - Modifies: [Request/Response changes]

2. **[Middleware Name]** - [Middleware.kt](../src/main/kotlin/com/example/Middleware.kt) (Line XX)
   - Purpose: [What it does]
   - Modifies: [Request/Response changes]

---

## Endpoints by Resource

### Users (`/users`)

#### GET /users

**Handler**: [UserController.kt](../src/main/kotlin/com/example/UserController.kt) (Line 25)

**Description**: [What this endpoint does]

**Authentication**: Required

**Query Parameters**:

- `page` (number, optional) - Default: `1`. Page number for pagination.
- `limit` (number, optional) - Default: `20`. Items per page.
- `search` (string, optional) - Filter results by search term.

**Response** (200):

```json
{
  "data": [
    {
      "id": "string",
      "email": "string",
      "name": "string",
      "createdAt": "ISO8601"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

**Status Codes**:

- `200` - Success
- `401` - Unauthorized - missing or invalid token
- `500` - Server error

---

#### POST /users

**Handler**: [UserController.kt](../src/main/kotlin/com/example/UserController.kt) (Line 45)

**Description**: [What this endpoint does]

**Authentication**: Required

**Request Body**:

```json
{
  "email": "string (required)",
  "password": "string (required, min 8 chars)",
  "name": "string (optional)"
}
```

**Validation**: [UserValidator.kt](../src/main/kotlin/com/example/UserValidator.kt) (Line XX)

**Response** (201):

```json
{
  "id": "string",
  "email": "string",
  "name": "string",
  "createdAt": "ISO8601"
}
```

**Error Responses**:

*400 - Validation Error*:
```json
{
  "error": "validation_error",
  "details": [
    {"field": "email", "message": "Invalid email format"}
  ]
}
```

*409 - Conflict*:
```json
{
  "error": "conflict",
  "message": "Email already exists"
}
```

---

#### GET /users/:id

**Handler**: [UserController.kt](../src/main/kotlin/com/example/UserController.kt) (Line 67)

**Description**: [What this endpoint does]

**Authentication**: Required

**Path Parameters**:

- `id` (string, required) - User ID in UUID format.

**Response** (200):

```json
{
  "id": "string",
  "email": "string",
  "name": "string",
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

**Error Responses**:

*404 - Not Found*:
```json
{
  "error": "not_found",
  "message": "User not found"
}
```

---

### [Next Resource] (`/resource`)

[Continue for all resources...]

---

## Error Response Format

All errors follow this structure:

```json
{
  "error": "error_code",
  "message": "Human readable message",
  "details": []
}
```

**Standard Error Codes**:

| Code | HTTP Status | Meaning |
|------|-------------|---------|
| validation_error | 400 | Request validation failed |
| unauthorized | 401 | Authentication required |
| forbidden | 403 | Insufficient permissions |
| not_found | 404 | Resource not found |
| conflict | 409 | Resource already exists |
| internal_error | 500 | Server error |

*Error handling defined in*: [ErrorHandler.kt](../src/main/kotlin/com/example/ErrorHandler.kt) (Line XX)

---

## Rate Limiting

**Configuration**: [RateLimitConfig.kt](../src/main/kotlin/com/example/RateLimitConfig.kt) (Line XX)

| Endpoint Pattern | Limit | Window |
|------------------|-------|--------|
| /auth/* | 10 | 1 minute |
| /api/* | 100 | 1 minute |
| * | 1000 | 1 hour |

---

## Integration Points

### External Services Called

| Service | Endpoints Using It | Purpose |
|---------|-------------------|---------|
| [Service Name] | POST /users, POST /orders | [What it does] |
| [Service Name] | GET /products | [What it does] |

### Webhooks Sent

| Event | Endpoint | Payload |
|-------|----------|---------|
| user.created | [Configurable] | `{userId, email, timestamp}` |
| order.completed | [Configurable] | `{orderId, amount, timestamp}` |

*Webhook dispatch*: [WebhookService.kt](../src/main/kotlin/com/example/WebhookService.kt) (Line XX)

---

## Testing the API

### With cURL

```bash
# Get all users
curl -X GET "http://localhost:3000/users" \
  -H "Authorization: Bearer <token>"

# Create user
curl -X POST "http://localhost:3000/users" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"email": "test@example.com", "password": "password123"}'
```

### Test Files

- **Users**: [UserControllerTest.kt](../src/test/kotlin/com/example/UserControllerTest.kt)
- **Products**: [ProductControllerTest.kt](../src/test/kotlin/com/example/ProductControllerTest.kt)

---

*This documentation is generated from code analysis. All handlers and schemas are verified against source.*
````

---

## Guidelines

- Discover endpoints from route definitions, don't assume they exist
- Request/response schemas should come from actual code (types, validators)
- Group endpoints by resource for readability
- Include actual file references for all handlers: [File.kt](../path/to/File.kt) (Line XX)
- Document error responses, not just success cases
- If OpenAPI/Swagger exists, cross-reference but verify against code

**Tables vs Lists:**
- **Tables for**: Endpoint Inventory, Permission Levels, Error Codes, Rate Limits, Integration Points
- **Lists for**: Query Parameters, Path Parameters, Status Codes, Test Files

---

## Success Criteria

API document is complete when:

- Table of Contents present
- API framework and routing pattern identified
- Endpoint inventory table complete with all endpoints
- Each endpoint has handler file reference: [File.kt](../path) (Line XX)
- Request/response schemas documented for each endpoint
- Query/Path parameters as lists (not tables)
- Status codes as lists (not tables)
- Authentication requirements documented per endpoint
- Middleware chain traced with execution order
- Error response format documented
- Testing examples (curl commands) included
- Diagrams rendered to images
