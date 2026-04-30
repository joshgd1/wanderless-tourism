---
name: no-guide-authentication
description: TripPlan accept flow has no real guide authentication — any client can impersonate any guide
type: RISK
---

## RISK: No Guide Authentication in TripPlan Accept Flow

**File**: `app/lib/features/trip_plan/screens/trip_plan_list_screen.dart:427`

The `POST /api/trip-plans/{id}/accept` endpoint accepts `guide_id` from the request body with no authentication check:

```python
guide_id = data.get("guide_id")  # No auth validation
```

In the Flutter app, the demo uses a guide picker dialog (uses real guide IDs from `/api/guides`) — so while guide identity isn't properly authenticated, the demo doesn't let you fake a non-existent guide ID.

**Production requirement**: Guide auth via JWT/session that verifies the guide_id matches the authenticated session.

**Status**: Known MVP limitation, documented in red team findings.
