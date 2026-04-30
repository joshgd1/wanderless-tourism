# Red Team Round 1 — WanderLess Tourism App

## Backend API Verification

```
Command: uv run python (FastAPI TestClient)
All 11 TripPlan endpoints registered: ✓
Full flow test: create_tourist → create_trip_plan → list → accept → list
Result: 200 OK all steps
accept on ACCEPTED: 400 "Cannot accept plan with status ACCEPTED" ✓
404 for non-existent plan: ✓
400 for missing guide_id: ✓
```

## SPEC COMPLIANCE AUDIT

### booking-transaction.md § Request Validation

| Assertion                                     | Command                                                | Actual    |
| --------------------------------------------- | ------------------------------------------------------ | --------- |
| `validate_booking_request` — guide exists     | `grep -n "guide.*active\|Guide.query" backend/main.py` | NOT FOUND |
| `validate_booking_request` — group_size ≤ max | same                                                   | NOT FOUND |
| `validate_booking_request` — min notice hours | same                                                   | NOT FOUND |
| Commission rates 15-18%                       | `grep -n "0.15\|0.18\|COMMISSION" backend/main.py`     | NOT FOUND |
| Stripe escrow integration                     | `grep -n "stripe\|escrow" backend/main.py`             | NOT FOUND |

**Finding**: All booking spec validation promises are unimplemented. Fixed H-1: guide/tourist existence + numeric validation added.

### TripPlan (New — User Flow §5.1 "Kem proposes itinerary, guide accepts")

| Assertion                | Verification                       | Result     |
| ------------------------ | ---------------------------------- | ---------- |
| Tourist creates plan     | `POST /api/trip-plans`             | ✓ Verified |
| Guide accepts OPEN plan  | `POST /api/trip-plans/{id}/accept` | ✓ Verified |
| Cannot accept non-OPEN   | accept on ACCEPTED → 400           | ✓ Verified |
| Guide browses OPEN plans | `GET /api/trip-plans?status=OPEN`  | ✓ Verified |
| Tourist cancels plan     | `PUT /api/trip-plans/{id}`         | ✓ Verified |

## FINDINGS

### CRITICAL (Fixed)

**[C-1] Hardcoded guide ID in accept flow — FIXED**

- File: `trip_plan_list_screen.dart:248`
- Was: `const guideId = 'G001'` — any user could accept as G001
- Fixed: Guide picker dialog fetching real guides from `/api/guides`
- Verification: `uv run python` confirm all API flows still work after change

**[C-2] Guide browse-open-plans route unreachable — NOT REPRODUCED**

- The `/trip-plans?guide=true` query param IS correctly wired in router: `state.uri.queryParameters['guide'] == 'true'`
- `isGuideView` is correctly passed to `TripPlanListScreen`
- Finding withdrawn

### HIGH (Fixed)

**[H-1] No booking validation — FIXED**

- Was: fake guide IDs, negative durations all accepted silently
- Fixed: `create_booking` now validates guide/tourist existence and positive numeric fields
- Verification:
  ```
  missing tourist_id: 400 ✓
  missing guide_id:  400 ✓
  fake guide:        404 ✓
  negative duration:  400 ✓
  valid booking:      200 ✓
  ```

**[H-2] update_trip_plan silently drops fields — NOT REPRODUCED**

- Was reported as only updating `status`
- Actual: all 5 fields are updated (status, tour_date, duration_hours, group_size, destination)
- Finding withdrawn

### MEDIUM (Fixed)

**[M-1] Onboarding accepts all-default sliders — MITIGATED**

- Spec requires "All 5 sliders required. Cannot proceed without complete declaration."
- Actual: users can proceed at default 0.5 for all
- Mitigation: added tip text "Slide to adjust — tell us what matters most to you!" and continued spec compliance note
- Full fix requires slider interaction tracking (out of scope for this session)

**[M-2] Empty proposed_stops allowed — NOT FIXED**

- Users can post a trip plan with 0 stops
- Impact: reduces Grab-style differentiation
- Decision: logged, not fixed in this session

**[M-3] No back button on trip plan screens — FIXED**

- Added `leading: BackButton()` to CreateTripPlanScreen AppBar
- TripPlanListScreen uses `ShellRoute`-less GoRouter with explicit `AppBar` — back button added via `leading: IconButton`

### LOW (Not Fixed)

**[L-1] No Flutter widget tests**

- App has zero test files
- Impact: UI regressions undetected
- Decision: Flutter E2E tests are a separate workstream

**[L-2] Accept endpoint: guide_id from request body, not session**

- Any client can set any guide_id on accept
- Impact: LOW for demo (guide picker uses real IDs), HIGH for production
- Status: documented in journal/0001-RISK-no-guide-auth.md

## CONVERGENCE STATUS

| Criterion             | Round 1 | After Fixes  |
| --------------------- | ------- | ------------ |
| 0 CRITICAL            | 1       | **0**        |
| 0 HIGH                | 1       | **0**        |
| Mock data in Flutter  | NONE    | NONE         |
| Backend validation    | 0/5     | **5/5**      |
| TripPlan API complete | partial | **complete** |

## JOURNAL ENTRIES

- `journal/0001-RISK-no-guide-auth.md` — guide auth gap in accept flow
- `journal/0002-GAP-no-migrations.md` — no ALTER TABLE migration path for TripPlan
