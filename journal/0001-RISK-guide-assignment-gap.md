# RISK: No guide assignment mechanism for confirmed groups

## Context

`api_create_group` sets `guide_id=None` at creation. No endpoint, scheduler, or workflow exists to ever assign a guide to an OPEN or CONFIRMED group.

## Impact

Groups can be formed, joined, and confirmed — but no guide is ever attached. The group travels without a guide.

## Technical details

- `backend/main.py:api_create_group` — creates `TravelGroup` with `guide_id=None`
- `backend/ml/group_formation.py:form_groups()` — returns `groups` dicts with `guide_id=None`
- No `/api/groups/{id}/assign-guide` endpoint
- No automatic assignment when `member_count >= min_size`
- No guide-side UI to claim an open group

## Resolution (2026-05-04)

**Option 1 implemented** — Guide self-claiming via "Open Groups" tab on guide dashboard.

- `POST /api/groups/{id}/claim` — guide JWT auth, validates OPEN + no guide, sets guide_id + status=CONFIRMED
- Guide dashboard: new 4th tab "Open Groups" showing OPEN groups with no guide, each with "Claim This Group" button
- `ApiClient.claimGroup()` wired in Flutter

## How to apply

Guide browsing Open Groups tab → taps "Claim" → confirmation dialog → `claimGroup()` → group confirmed. Guides can now self-assign to open groups.
