# DISCOVERY: FastAPI Route Ordering Silently Blocked Guide Request Flow

## Problem

Guide login succeeded (JWT returned with `role: "guide"`), but calling `GET /api/guides/open-requests` returned `{"detail":"Guide not found"}`. The guide's own open-requests endpoint was returning "Guide not found" because FastAPI was matching the request against `/{guide_id}` instead.

## Root Cause

FastAPI matches routes in declaration order. The `/{guide_id}` wildcard route was declared BEFORE `/open-requests`. When the request `GET /api/guides/open-requests` arrived, FastAPI matched it against `{guide_id}` with `guide_id = "open-requests"`. The database had no guide with ID "open-requests", so the response was `{"detail":"Guide not found"}`.

## Fix

Moved `/{guide_id}` to after all specific guide routes in `backend/main.py`:

```python
# BEFORE (line 599): /{guide_id} was declared early
@app.get("/api/guides/{guide_id}")   # ← matched "open-requests" as guide_id
...

# AFTER: /{guide_id} is last (line 859)
@app.get("/api/guides/auth/me")
@app.get("/api/guides/open-requests")
@app.post("/api/guides/open-requests/{plan_id}/accept")
@app.get("/api/guides/{guide_id}")   # ← greedy, only matches actual guide IDs
```

## Correct Guide Auth Endpoints (verified)

| Action              | Endpoint                                          | Auth               |
| ------------------- | ------------------------------------------------- | ------------------ |
| Guide login         | `POST /api/guides/login`                          | None               |
| Guide profile       | `GET /api/guides/{guide_id}`                      | Bearer JWT         |
| Guide's own profile | `GET /api/guides/auth/me`                         | Bearer JWT         |
| Open requests       | `GET /api/guides/open-requests`                   | Bearer JWT (guide) |
| Accept request      | `POST /api/guides/open-requests/{plan_id}/accept` | Bearer JWT (guide) |

## Two Accept Endpoints

There are TWO accept endpoints:

1. **`POST /api/guides/open-requests/{plan_id}/accept`** (line 765) — Accepts OPEN or PENDING_ACCEPTANCE plan, creates a Booking, sets status to CONFIRMED
2. **`POST /api/trip-plans/{plan_id}/accept`** (line 2008) — Accepts OPEN plan only, sets status to ACCEPTED, requires guide license verified + rating >= 5

Both use `guide_id: str = Depends(_get_guide_id)` — guide ID comes from the JWT, not request body.

## Trip Plan State Machine

```
OPEN → PENDING_ACCEPTANCE (tourist requests specific guide via POST /trip-plans/{id}/request-guide?guide_id=G)
     → ACCEPTED (guide accepts via POST /trip-plans/{id}/accept)
```

## Why This Wasn't Caught Earlier

1. Guide login endpoint (`/api/guides/login`) uses the same `POST` as tourist login, so it appeared to work
2. The error "Guide not found" seemed like a database seeding issue, not a routing issue
3. The route order was a silent, non-obvious bug — the server started fine, individual endpoints worked

## Pattern: Specific Routes Must Precede Greedy Path Parameter Routes

This is a general FastAPI/ Starlette pattern. Any wildcard path parameter (`/{id}`, `/{guide_id}`) will match any string, including literal route segments like "open-requests", "auth", "me", etc.

**Rule of thumb**: Always define specific routes BEFORE routes with path parameters.

## Files Changed

- `backend/main.py` — moved `/{guide_id}` route to after guide auth routes

## Verification

```bash
# Guide login
curl -X POST https://wanderless-tourism.onrender.com/api/guides/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guide@wanderless.com","password":"wanderless123"}'

# Guide open requests (should return list, not "Guide not found")
curl https://wanderless-tourism.onrender.com/api/guides/open-requests \
  -H "Authorization: Bearer <token>"
```

Expected: JSON array of open trip plans. Before fix: `{"detail":"Guide not found"}`.
