---
name: no-schema-migrations
description: TripPlan table requires reseed to create — no ALTER TABLE migration path
type: GAP
---

## GAP: No Schema Migration Path for TripPlan

**File**: `backend/database.py`

The `reseed` function drops all tables and re-seeds from CSV. Adding the TripPlan table to an existing `wanderless.db` requires either:

1. Dropping and reseeding (loses all existing data — bookings, itineraries)
2. An ALTER TABLE migration that adds the `trip_plans` table

For MVP demo, reseed is acceptable. For production: need numbered migration files.

**Status**: MVP acceptable, production requires proper migration framework.
