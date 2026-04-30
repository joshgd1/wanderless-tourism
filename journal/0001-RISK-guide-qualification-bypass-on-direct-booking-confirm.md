---
name: guide-qualification-bypass-direct-booking
description: Guide can confirm booking without license_verified or rating_count check on PUT /api/bookings/{id}/status
type: risk
---

# RISK: Guide Qualification Bypass on Direct Booking Confirm

## Finding

`PUT /api/bookings/{booking_id}/status` with `{"status": "CONFIRMED"}` allows any guide with a valid JWT to confirm a booking without checking `license_verified` or `rating_count >= 5`.

## Location

`backend/main.py:1027-1093` (`update_booking_status` endpoint)

## Spec Basis

`04-specs/guide-profile.md` § Active Requirements: TAT license current required for active guiding.

Prior session (session notes) explicitly listed "Guide impersonation on accept — added `license_verified` + `rating_count>=5` check" as a critical finding that was supposedly fixed. The checks exist in TripPlan accept (`main.py:1275-1278`) but NOT in the direct booking status endpoint.

## Attack Scenario

1. Guide registers, gets JWT, `license_verified=False`, `rating_count=0`
2. Tourist requests booking with this guide
3. Guide calls `PUT /api/bookings/{id}/status` with `{"status": "CONFIRMED"}`
4. Booking transitions to CONFIRMED without guide meeting qualification门槛

## Fix

Add before allowing `REQUESTED→CONFIRMED` transition by a guide:

```python
if new_status == "CONFIRMED" and is_guide:
    guide = db.query(models.Guide).filter_by(id=guide_id).first()
    if not guide.license_verified:
        raise HTTPException(status_code=400, detail="Guide license not verified")
    if (guide.rating_count or 0) < 5:
        raise HTTPException(status_code=400, detail="Guide rating below minimum")
```
