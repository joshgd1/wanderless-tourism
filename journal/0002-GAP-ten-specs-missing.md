---
name: ten-specs-missing
description: 10 of 17 spec files listed in _index.md do not exist — including business-partner and review-rating
type: gap
---

# GAP: 10 of 17 Spec Files Missing

## Finding

`04-specs/_index.md` declares 17 total requirements but only 8 spec files exist. 10 spec files are referenced in the \_index but do not exist on disk.

## Missing Specs

### Core Domain (2)

- `business-partner.md` — listed as Complete in \_index but file does not exist
- `review-rating.md` — listed as Complete but file does not exist

### Platform Infrastructure (6)

- `auth-identity.md`
- `payment-escrow.md`
- `messaging-translation.md`
- `safety-trust.md`
- `data-pipeline.md`
- `commission-settlement.md`

### Business Operations (2)

- `tier-premium-tools.md`
- `quality-intervention.md`

### Growth (2)

- `city-playbook.md`
- `viral-growth.md`

### ML (1)

- `interest-vector.md`

## Why It Matters

The `business-partner.md` is operationally critical — the Guide model has `owner_id FK` to `business_owners` and matching engine uses `PARTNER_REFERRAL_RATE = 0.07` for commission deductions, but the partner portal flow is unspecified.

## Disposition

DEFER — spec authoring is a human-gated planning activity, not an autonomous implementation task.
