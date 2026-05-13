---
name: api-design
description: Review API design for consistency, versioning, error contracts, and resource modeling; use when designing or reviewing APIs, adding new endpoints, or evaluating third-party API integrations
metadata:
  author: imprivata-shared-tools
  version: "2.0.0"
---

# API Design Review

## What to look for

APIs that are inconsistent, hard to version, or leak implementation details. An API is a contract — inconsistency in that contract forces every consumer to handle special cases.

## Signals

1. Inconsistent naming across endpoints (camelCase mixed with snake_case, plural and singular nouns for the same concept)
2. Missing or inconsistent error response format — some endpoints return `{error: "msg"}`, others return `{message: "msg"}`, others return plain text
3. Version-breaking changes to existing endpoints without a versioning strategy
4. Resource URIs that expose implementation details (`/getUser`, `/fetchOrderById`) instead of resource-oriented paths (`/users/{id}`, `/orders/{id}`)
5. Collection endpoints that return unbounded results — no pagination, no limit
6. Overly broad responses returning entire objects when the caller needs a subset of fields
7. Inconsistent authentication or authorization patterns across endpoints
8. No idempotency guarantees on unsafe operations (POST, PUT, DELETE)

## Consistency checklist

| Aspect | What to check |
|--------|--------------|
| Naming | Consistent case convention, plural nouns for collections, no verbs in resource URIs |
| Errors | Standard error envelope on all endpoints — at minimum: code, message, details |
| Versioning | Explicit strategy (URL path, header, or query param) applied consistently |
| Pagination | Cursor-based or offset pagination on every collection endpoint |
| Idempotency | Unsafe operations are idempotent or document when they are not |
| Auth | Consistent authentication mechanism across all endpoints |
| Content type | Consistent request/response media types; explicit `Content-Type` headers |
| Status codes | Correct HTTP status codes — 201 for creation, 204 for no content, 404 for missing resources |

## Investigation workflow

1. **Inventory the surface area.** List all public endpoints from route definitions, controller files, or `openapi.yaml`. Record the HTTP method, path, request body shape, and response shape for each.

2. **Audit naming consistency.** Check every endpoint path against the naming convention. Flag mixed casing (`/getUserProfile` next to `/user-settings`), inconsistent pluralization (`/user/{id}` vs `/orders/{id}`), and verbs in resource URIs. Cross-reference with `requirements.md` or the domain glossary for correct resource names.

3. **Check error contracts.** Call or inspect each endpoint's error paths. Verify every endpoint returns the same error envelope structure. Flag endpoints that return plain strings, HTML error pages, or inconsistent JSON shapes on failure.

4. **Verify versioning strategy.** Check whether a versioning scheme exists (URL path `/v1/`, header `Accept-Version`, query param `?version=`). If it exists, verify every endpoint uses it. If it does not exist, flag this as a gap — any API with external consumers needs a versioning strategy before the first breaking change.

5. **Test pagination boundaries.** For every collection endpoint, verify pagination is implemented. Request without pagination parameters — the response must include pagination metadata (`next_cursor`, `total_count`, or equivalent). Flag unbounded responses.

6. **Validate idempotency.** For POST, PUT, and DELETE operations, check whether repeated calls produce the same result. Look for idempotency keys on creation endpoints. Flag operations where a retry could create duplicates or cause unintended side effects.

## Concrete example

**Before** — inconsistent error contract across endpoints:

```
GET /api/v1/users/999
  Response: 404  {"error": "User not found"}

POST /api/v1/orders
  Response: 400  {"message": "Invalid order", "code": "VALIDATION_ERROR"}

DELETE /api/v1/products/5
  Response: 500  "Internal Server Error"
```

Three endpoints, three different error shapes. Every consumer must handle each format separately.

**After** — unified error envelope following RFC 7807:

```
GET /api/v1/users/999
  Response: 404  {"type": "not_found", "title": "User not found",
                  "detail": "No user with id 999", "status": 404}

POST /api/v1/orders
  Response: 400  {"type": "validation_error", "title": "Invalid order",
                  "detail": "Field 'items' must not be empty", "status": 400}

DELETE /api/v1/products/5
  Response: 500  {"type": "internal_error", "title": "Internal server error",
                  "detail": "Request id: abc-123", "status": 500}
```

One envelope, one parsing path for all consumers. Machine-readable `type` field enables programmatic error handling.

## Decision guidance

| Decision | Guidance |
|----------|---------|
| REST vs RPC style | Use REST (resource-oriented) for CRUD-heavy domains with clear entities. Use RPC style (`/actions/send-invoice`) for operations that do not map to resource lifecycle. Most APIs are a mix — keep resources RESTful and use a dedicated `/actions` or `/commands` namespace for non-CRUD operations. |
| When to version | Version before the first external consumer. Internal-only APIs can defer versioning but must plan for it. Once a consumer exists, any field removal, type change, or semantic change requires a new version. |
| URL path vs header versioning | URL path (`/v1/`) is simpler to route, cache, and debug. Header versioning (`Accept-Version`) is cleaner semantically but harder to test in a browser. Default to URL path unless you have a specific reason not to. |
| When to paginate | Always paginate collection endpoints. There is no dataset that stays small forever. Default page size of 20-100, maximum of 1000. Cursor-based pagination is more stable than offset-based for datasets that change between requests. |
| Idempotency keys | Require idempotency keys on any creation endpoint (POST) that could be retried. Use a client-supplied `Idempotency-Key` header. Store the key and response for the deduplication window (typically 24 hours). |
| Additive changes only | Adding new fields, new endpoints, and new optional parameters are safe. Removing fields, renaming fields, and changing types are breaking. When in doubt, it is breaking. |

## Agent-friendly API design

APIs consumed by agents benefit from predictable patterns:
- Explicit, machine-readable error codes (not just human-readable messages)
- Stable field names across versions (agents break on renames)
- Schema documentation (OpenAPI / Protocol Buffers) that agents can read before making calls
- Consistent null handling — never mix `null`, empty string, and absent field for the same concept

## Output format

Report findings referencing the specific file and line range. For each finding, state: what the inconsistency or gap is, which endpoints are affected, and what the consistent pattern should be.
