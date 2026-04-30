# Business Partner (BusinessOwner)

BusinessOwner is the business-facing portal for operators who own or manage groups of tour guides. A BusinessOwner can register guides under their organization, view a consolidated dashboard of all their guides' bookings and earnings, and manage guide assignments.

## Data Model

### BusinessOwner

| Field         | Type   | Constraints                         |
|---------------|--------|-------------------------------------|
| id            | String | Primary key, format: `B` + 8 hex (e.g., `B0A3F2C1`) |
| email         | String | Unique, non-null |
| password_hash | String | bcrypt hash, non-null |
| business_name | String | Display name, non-null |
| phone         | String | Optional |
| created_at    | DateTime | Auto-set on creation |

### Guide — Business Owner Relationship

| Field     | Type   | Constraints                                    |
|-----------|--------|------------------------------------------------|
| owner_id  | String | FK → `business_owners.id`, nullable. Null = independent guide (no business owner) |

A guide is **independent** when `owner_id IS NULL`. An independent guide is not visible to any BusinessOwner.

## Authentication

### POST /api/business/register

Register a new BusinessOwner account.

**Request body:**
```json
{
  "email": "string",
  "password": "string",
  "business_name": "string",
  "phone": "string (optional)"
}
```

**Response 201:**
```json
{
  "business_owner_id": "B0A3F2C1",
  "email": "...",
  "business_name": "...",
  "token": "JWT"
}
```

### POST /api/business/login

**Request body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response 200:**
```json
{
  "business_owner_id": "B0A3F2C1",
  "email": "...",
  "business_name": "...",
  "token": "JWT"
}
```

### GET /api/business/me

Requires: `Authorization: Bearer <token>`

**Response 200:**
```json
{
  "id": "B0A3F2C1",
  "email": "...",
  "business_name": "...",
  "phone": "..."
}
```

## Dashboard

### GET /api/business/dashboard

Requires: `Authorization: Bearer <token>` (BusinessOwner JWT)

Returns aggregate statistics for all guides owned by this BusinessOwner.

**Response 200:**
```json
{
  "business_owner_id": "B0A3F2C1",
  "business_name": "...",
  "total_guides": 3,
  "total_bookings": 12,
  "total_earnings": 4520.00,
  "guides": [
    {
      "guide_id": "G...",
      "name": "...",
      "email": "...",
      "total_bookings": 5,
      "total_earnings": 1800.00
    }
  ]
}
```

## Guide Management

### GET /api/business/guides

Requires: `Authorization: Bearer <token>` (BusinessOwner JWT)

Returns all guides owned by this BusinessOwner.

**Response 200:**
```json
[
  {
    "guide_id": "G...",
    "name": "...",
    "email": "...",
    "license_verified": true,
    "rating_count": 23,
    "rating": 4.7
  }
]
```

## Guide Assignment

A guide is **assigned** to a BusinessOwner by setting `guide.owner_id` to the BusinessOwner's `id`. This is done during guide creation or by an admin. The assignment is permanent unless reset to `NULL` (returning the guide to independent status).

**Note:** Commission tracking and referral rate (`PARTNER_REFERRAL_RATE`) is not yet implemented. This spec section is reserved for future commission logic.

## Security

- BusinessOwner JWT tokens are separate from Tourist and Guide JWT tokens.
- A BusinessOwner can only access their own `owner_id` scope — cross-owner access returns 401.
- Guide `owner_id` assignment requires admin-level auth (not implemented in the current version).
