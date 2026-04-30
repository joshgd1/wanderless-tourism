# Red Team Round 2 — Authentic Local Guide Promise

**Focus**: Does the app genuinely match tourists to **authentic local guides** for real experiences — not just tourist-friendly generic guides?

---

## CORE PROMISE ANALYSIS

The pitch deck and user flows make a specific promise: _"Find your ideal local guide — matched by who they are, not just where they work."_ The product must distinguish **authentic local expertise** from **tourist-oriented generic guiding**.

**Authentic local guide** = Someone with genuine local knowledge (born/lived there, deep neighborhood-level expertise, off-the-beaten-path access) vs. a **tourist guide** = Someone who knows the standard tourist spots and can communicate in the tourist's language.

---

## SPEC COMPLIANCE: AuthENTICITY SIGNALS IN MATCHING

| Assertion                                                 | Verification                                | Result    |
| --------------------------------------------------------- | ------------------------------------------- | --------- |
| `bio` field used in matching                              | `grep -n "bio" backend/matching.py`         | NOT FOUND |
| `photo_url` used in matching                              | same                                        | NOT FOUND |
| `rating_history` used in scoring                          | same                                        | NOT FOUND |
| `location_coverage` used in matching                      | same                                        | NOT FOUND |
| `license_verified` checked                                | same                                        | NOT FOUND |
| Guide locality/authenticity scored                        | same                                        | NOT FOUND |
| `specialties` field used (distinct from `expertise_tags`) | `grep -n "specialties" backend/matching.py` | NOT FOUND |

**Finding**: 7 authenticity-related guide fields are stored in `models.py` but **completely absent from `matching.py`**. The matching algorithm never reads them.

---

## MATCHING ALGORITHM GAP ANALYSIS

### What the Algorithm Scores (matching.py:49-84)

```
score = normalized_dot(interest_vec · expertise_vec) * 6.5 + 1.2
      + (lang_match * 0.30)
      + ((budget_compat - 0.8) * 0.15)
      + ((pace_compat - 0.8) * 0.15)
```

The algorithm matches:

1. Tourist interest vector (food/culture/adventure) → Guide expertise tags
2. Language match bonus (+0.30 flat bonus)
3. Budget alignment (clamped 0.6–1.0)
4. Pace alignment (clamped 0.6–1.0)

### What the Algorithm IGNORES

| Field               | Stored in Guide model? | Used in matching? | Authenticity signal?                                                            |
| ------------------- | ---------------------- | ----------------- | ------------------------------------------------------------------------------- |
| `bio`               | YES                    | **NO**            | "Born/lived here 30 years" vs "Certified guide since 2015" — completely ignored |
| `years_experience`  | YES (via rating_count) | **NO**            | Would distinguish third-generation local from 6-month certified                 |
| `rating_history`    | YES                    | **NO**            | Quality signal not used in scoring                                              |
| `rating_count`      | YES                    | **NO**            | Volume signal not used                                                          |
| `location_coverage` | YES                    | **NO**            | "Old city neighborhoods" vs "All tourist zones" — ignored                       |
| `license_verified`  | YES                    | **NO**            | No distinction between verified local vs unverified                             |
| `specialties`       | YES                    | **NO**            | Duplicate of expertise_tags                                                     |
| `photo_url`         | YES                    | **NO**            | No visual authenticity signal                                                   |

---

## CRITICAL FINDINGS

### [C-A1] No Guide Locality/Authenticity Signal in Matching — HIGH

**File**: `backend/matching.py`

The algorithm produces identical scores for two fundamentally different guide profiles:

**Guide A** (truly local):

```
name: "Kem S."
bio: "I grew up in Chiang Mai's old city, third-generation guide.
      My family has lived here for 80 years — I know every neighborhood."
expertise_tags: "food|culture|temples"
rating_history: 4.9
rating_count: 127
```

**Guide B** (tourist-oriented):

```
name: "Mike T."
bio: "Certified guide, 5 years experience, specializing in
      tours for international travelers. Speaks English and German."
expertise_tags: "food|culture|temples"
rating_history: 4.8
rating_count: 43
```

Both guides get **identical compatibility scores** because:

- Same expertise_tags map to the same expertise_vec → same dot product
- Same language pairs → same lang_match bonus
- Same budget_tier and pace_style → same compat bonus

The `bio` field — the most authentic signal of local knowledge — is stored but never read.

**Impact**: Tourists explicitly seeking "authentic local" experiences get the same match score for generic tourist-oriented guides. The core value proposition is broken at the algorithm level.

**Recommendation**: Add authenticity signals to matching:

1. Parse `bio` for locality indicators ("born here", "grew up", "local family", "neighborhood")
2. Weight `rating_count` as a proxy for sustained local practice
3. Add `is_locally_verified` flag (TAT license + local residency verification)
4. Distinguish `expertise_tags` that indicate authentic local ("markets", "rural", "cooking") from tourist-oriented ("nightlife", "shopping")

---

### [C-A2] Language Match Bonus Incentivizes Tourist-Oriented Guides — HIGH

**File**: `backend/matching.py:73`

```python
lang_match = 1.0 if tourist.language in [lp.split("→")[0] ...] else 0.0
bonus = lang_match * 0.30 + (compat - 0.8) * 0.15
```

The +0.30 flat bonus for language match means:

**A guide with**:

- `language_pairs = "en→th|ru→th|de→th"`
- Generic tourist-oriented expertise

**Gets the same +0.30 bonus as**:

- A guide with `language_pairs = "en→th"` who is a third-generation local with deep local expertise

The language bonus doesn't account for **how the guide acquired the language**. A local who learned English serving tourists gets the same bonus as a local who grew up bilingual. An international guide who learned Thai from books gets the same bonus as someone who has lived in Thailand for 30 years.

**Inverted incentive**: Guides are rewarded for adding more language pairs (to capture the bonus) rather than deepening local expertise. A guide who speaks 5 languages and caters to tourists gets a higher language bonus than a guide who speaks 1 language fluently and has authentic local knowledge.

**Impact**: The matching algorithm may systematically favor multilingual tourist-oriented guides over authentically local mono-lingual guides.

---

### [C-A3] Rating History Not Used in Match Scoring — HIGH

**File**: `backend/matching.py`

`rating_history` (4.9 stars) and `rating_count` (127 reviews) are stored in the Guide model but never used in `compatibility_score()`.

**Guide A**: 127 reviews, 4.9 avg — well-established, consistent quality
**Guide B**: 12 reviews, 4.9 avg — new guide, same score

Both get the same score because the algorithm doesn't differentiate on quality or volume. The user flow says "★ 4.9 (127 reviews)" is displayed as a key signal on the match card (01-user-flows.md:118), but the matching algorithm itself ignores this signal.

**Impact**:

1. Established local guides with long track records aren't prioritized
2. New guides (even potentially better matches) get same visibility as established ones
3. The displayed rating/review count creates expectation of quality sorting that the algorithm doesn't deliver

---

## HIGH FINDINGS

### [H-A1] Guide Authenticity Not Verified at Accept Time — MEDIUM

**File**: `backend/main.py` (accept endpoint)

The accept flow (POST `/api/trip-plans/{id}/accept`) accepts any guide_id from the request body. A guide with zero local authenticity credentials can accept any trip plan. No check for:

- `license_verified` flag
- `rating_count` minimum threshold
- Local residency / coverage area

The user flow spec (01-user-flows.md:621) requires TAT license verification for guide onboarding, but this is never checked at accept time.

**Status**: Documented in journal `0001-RISK-no-guide-auth.md` as known MVP limitation.

---

### [H-A2] Onboarding Doesn't Surface Local Authenticity — MEDIUM

**File**: `app/lib/features/onboarding/screens/interests_screen.dart`

The 3 onboarding sliders (Food, Culture, Adventure) capture tourist preferences but don't distinguish:

- "I want authentic local food" (neighborhood markets, family kitchens) vs
- "I want good local food" (popular tourist-rated restaurants)
- "I want local cultural immersion" vs "I want to see famous cultural sites"

A tourist who specifies high Food interest and says they want authentic local experiences gets the same matches as a tourist who wants standard tourist food experiences. The interest declaration doesn't capture **depth** of authenticity seeking.

**Impact**: Tourists can't explicitly signal they want genuinely local guides vs. tourist-friendly guides.

---

### [H-A3] Guide Profile Shows Bio But Bio Doesn't Influence Matching — MEDIUM

**Files**: `01-user-flows.md:172-177`, `backend/matching.py`

The user flow spec shows the guide profile displaying the bio prominently:

> "I grew up in Chiang Mai's old city and have been guiding for 8 years. I specialize in food tours that take you beyond the night market — into family kitchens and local morning markets."

But `matching.py` never reads the `bio` field. A guide with "I grew up here" in their bio gets the same match score as a guide with "Certified international guide" — if their expertise_tags are the same.

**The bio is used for marketing display but not algorithmic differentiation.**

---

## VERIFICATION

### Round 1 fixes confirmed still working:

| Test                                                | Command                                                   | Result    |
| --------------------------------------------------- | --------------------------------------------------------- | --------- |
| All 11 endpoints registered                         | `uv run python` (TestClient)                              | ✓         |
| Booking validation (guide exists, positive nums)    | manual test                                               | ✓         |
| Hardcoded guide ID removed from Flutter accept flow | `grep "G001" app/`                                        | NOT FOUND |
| Back button on CreateTripPlanScreen                 | `grep "leading.*BackButton" create_trip_plan_screen.dart` | ✓ FOUND   |

### Round 1 status unchanged:

| Finding                             | Status                          |
| ----------------------------------- | ------------------------------- |
| C-1: Hardcoded guide ID             | FIXED ✓                         |
| C-2: Guide browse route unreachable | WITHDRAWN (route works)         |
| H-1: No booking validation          | FIXED ✓                         |
| H-2: update_trip_plan drops fields  | WITHDRAWN (all fields updated)  |
| M-1: All-default sliders accepted   | MITIGATED (tip text added)      |
| M-2: Empty proposed_stops allowed   | NOT FIXED (logged)              |
| M-3: No back button on trip screens | FIXED ✓                         |
| L-1: No Flutter widget tests        | NOT FIXED (separate workstream) |
| L-2: Guide ID from body not session | KNOWN RISK (journaled)          |

---

## CONVERGENCE STATUS

| Criterion                          | R1  | R2                  | Delta   |
| ---------------------------------- | --- | ------------------- | ------- |
| 0 CRITICAL                         | 0   | 2                   | +2 new  |
| 0 HIGH                             | 0   | 2                   | +2 new  |
| Authentic local signal in matching | N/A | **0/7 fields used** | BLOCKER |
| Language bonus reflects locality   | N/A | **No**              | BLOCKER |
| Rating used in match scoring       | N/A | **No**              | BLOCKER |
| Bio influences matching            | N/A | **No**              | BLOCKER |

**Round 2 introduces 3 new CRITICAL/HIGH findings** around the authentic local value proposition that Round 1 did not address.

---

## JOURNAL ENTRIES NEEDED

1. **`journal/0003-GAP-no-authenticity-signal-in-matching.md`** — Guide bio, locality, years experience all stored but never used in scoring algorithm
2. **`journal/0004-GAP-language-bonus-inverts-local-guide-incentive.md`** — Flat language match bonus incentivizes multilingual tourist guides over authentic mono-lingual locals

---

## RED TEAM VERDICT

The app **stores** the right data (bio, local credentials, years experience) but **never uses it** in the matching algorithm. The core promise — _"find a local guide who'll give you an authentic experience"_ — is **not implemented in code**. The algorithm is interest-tag matching with language/budget/pace bonuses. It does not distinguish:

- Third-generation local guide from certified tourist guide
- Neighborhood-level expertise from tourist-zone expertise
- Deep local knowledge from multilingual communication skill

**This is the most significant gap in the product.** The data model is correct; the algorithm is incomplete.
