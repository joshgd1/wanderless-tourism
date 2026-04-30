---
name: no-authenticity-signal-in-matching
description: Guide bio, locality, years experience, license_verified all stored but never used in matching algorithm — core authentic-local promise not implemented
type: GAP
---

## GAP: Matching Algorithm Ignores All Authenticity Signals

**File**: `backend/matching.py`

The Guide model stores 7 fields that directly signal authentic local knowledge:

- `bio` — "I grew up in Chiang Mai's old city" vs "Certified international guide"
- `rating_history` — quality consistency over time
- `rating_count` — volume of authentic local practice (127 reviews = trusted by many tourists)
- `location_coverage` — "old city neighborhoods" vs "all tourist zones"
- `license_verified` — TAT-licensed local vs unverified
- `years_experience` — proxy for depth of local knowledge
- `specialties` — same as expertise_tags, redundant

**None of these are read by `compatibility_score()`.** The algorithm only uses:

- `expertise_tags` → expertise_vec → dot product with tourist interest vector
- `language_pairs` → flat +0.30 bonus for match
- `budget_tier` and `pace_style` → clamped compat bonuses

**Impact on core promise**: "Find a local guide who'll give you an authentic experience" is the #1 product differentiator. The matching algorithm cannot deliver it — identical scores for a third-generation local guide and a certified tourist guide with the same expertise tags.

**Fix options**:

1. Parse `bio` for locality keywords ("born here", "grew up", "local family", "third generation") → authenticity score
2. Use `rating_count` as a trust/reliability multiplier on the base score
3. Add `license_verified` as a filter or boost
4. Weight `expertise_tags` that indicate authentic local ("markets", "rural", "cooking") higher than tourist-oriented ("nightlife", "shopping")
5. Use `location_coverage` to match guide's actual locality to tourist's destination area

**Status**: GAP identified, not fixed in this session. MVP uses interest-tag matching only.
