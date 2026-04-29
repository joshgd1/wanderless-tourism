# Phase 3 — Feature Framing: WanderLess Matching Risk Model

**Date**: 2026-04-26
**Phase**: Frame (no data — features enumerated from spec files)
**Target**: Poor experience prediction (post-tour rating 1-2 stars OR cancellation within 48h of tour start), per booking, 30-day window
**Prediction moment**: Before booking is confirmed

---

## Feature Classification Table

### Tourist-Side Features

| #   | Feature Name                       | Source                                            | Available at Pred. Time | Leakage Risk                                           | Ethical / Regulatory Flag                                                           | Raw / Engineered                                    | Recommendation | Reason                                                                                                                         |
| --- | ---------------------------------- | ------------------------------------------------- | ----------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------------------- | --------------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `tourist.food`                     | `tourist-profile.md` §primary_interests.food      | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Core matching dimension, stated at signup                                                                                      |
| 2   | `tourist.culture`                  | `tourist-profile.md` §primary_interests.culture   | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Core matching dimension                                                                                                        |
| 3   | `tourist.adventure`                | `tourist-profile.md` §primary_interests.adventure | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Core matching dimension                                                                                                        |
| 4   | `tourist.pace`                     | `tourist-profile.md` §primary_interests.pace      | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Core matching dimension                                                                                                        |
| 5   | `tourist.budget`                   | `tourist-profile.md` §primary_interests.budget    | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Budget alignment with guide pricing                                                                                            |
| 6   | `tourist.age_group`                | `tourist-profile.md` §age_group                   | Y                       | N                                                      | **PDPA §13 / GDPR Art. 9** — age band derived from raw age                          | Raw                                                 | OUT            | Age-derived proxy; proxy-drop test required before IN decision; regulatory sensitivity outweighs predictive value at Phase 1   |
| 7   | `tourist.travel_style`             | `tourist-profile.md` §travel_style                | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Group composition signal; no protected class                                                                                   |
| 8   | `tourist.primary_language`         | `tourist-profile.md` §primary_language            | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Language compatibility with guide                                                                                              |
| 9   | `tourist.acceptable_languages`     | `tourist-profile.md` §acceptable_languages        | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Expanded matching flexibility                                                                                                  |
| 10  | `tourist.mobility`                 | `tourist-profile.md` §mobility                    | Y                       | N                                                      | **GDPR Art. 9 / PDPA §13** — disability indicator                                   | Raw                                                 | FLAG           | Accessibility need; use only as hard constraint (guide capability match), not as predictive feature; explicit consent required |
| 11  | `tourist.dietary_restrictions`     | `tourist-profile.md` §dietary_restrictions        | Y                       | N                                                      | **GDPR Art. 9** — may imply religion (halal, kosher) or health (diabetes); PDPA §13 | Raw                                                 | FLAG           | Dietary data is health/religion-adjacent; use only as hard constraint for guide capability matching; never as prediction input |
| 12  | `tourist.accessibility_needs`      | `tourist-profile.md` §accessibility_needs         | Y                       | N                                                      | **GDPR Art. 9 / PDPA §13** — disability                                             | Raw                                                 | FLAG           | Same as mobility; hard constraint only                                                                                         |
| 13  | `tourist.preferred_start_time`     | `tourist-profile.md` §preferred_start_time        | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Temporal preference for scheduling                                                                                             |
| 14  | `tourist.tour_duration_preference` | `tourist-profile.md` §tour_duration_preference    | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Duration signal; used in itinerary optimization                                                                                |
| 15  | `tourist.completed_tours`          | `tourist-profile.md` §completed_tours             | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Engagement signal; shows repeat tendency                                                                                       |
| 16  | `tourist.viewed_guides`            | `tourist-profile.md` §viewed_guides               | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Engagement depth signal; not label-leaky                                                                                       |
| 17  | `tourist.search_queries`           | `tourist-profile.md` §search_queries              | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Intent signal; interest declaration proxy                                                                                      |
| 18  | `tourist.booking_frequency`        | `tourist-profile.md` §booking_frequency           | Y                       | N                                                      | N                                                                                   | Raw                                                 | IN             | Platform engagement signal                                                                                                     |
| 19  | `tourist.interest_vector`          | `tourist-profile.md` §interest_vector             | Y                       | N                                                      | N                                                                                   | Engineered: embed(primary_interests + demographics) | IN             | 64-dim embedding; primary matching representation                                                                              |
| 20  | `tourist.segment`                  | `tourist-profile.md` §segment                     | Y                       | N                                                      | N                                                                                   | Engineered: K-Means cluster ID                      | IN             | Tourist segment for group formation                                                                                            |
| 21  | `tourist.confidence_score`         | `tourist-profile.md` §confidence_score            | Y                       | N                                                      | N                                                                                   | Engineered: profile completeness formula            | IN             | Low-confidence profiles get lower matching priority                                                                            |
| 22  | `tourist.guide_ratings`            | `tourist-profile.md` §guide_ratings               | **N**                   | **LABEL LEAKAGE** — post-tour ratings given by tourist | N                                                                                   | Raw                                                 | **OUT**        | Post-booking outcome; cannot be used as input at prediction time                                                               |

### Guide-Side Features

| #   | Feature Name                     | Source                                           | Available at Pred. Time | Leakage Risk                                                      | Ethical / Regulatory Flag | Raw / Engineered                                        | Recommendation | Reason                                                                        |
| --- | -------------------------------- | ------------------------------------------------ | ----------------------- | ----------------------------------------------------------------- | ------------------------- | ------------------------------------------------------- | -------------- | ----------------------------------------------------------------------------- |
| 23  | `guide.expertise.food`           | `guide-profile.md` §expertise_vector.food        | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Core matching dimension                                                       |
| 24  | `guide.expertise.culture`        | `guide-profile.md` §expertise_vector.culture     | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Core matching dimension                                                       |
| 25  | `guide.expertise.adventure`      | `guide-profile.md` §expertise_vector.adventure   | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Core matching dimension                                                       |
| 26  | `guide.expertise.nightlife`      | `guide-profile.md` §expertise_vector.nightlife   | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Matching dimension if tourist interested                                      |
| 27  | `guide.expertise.nature`         | `guide-profile.md` §expertise_vector.nature      | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Matching dimension                                                            |
| 28  | `guide.expertise.shopping`       | `guide-profile.md` §expertise_vector.shopping    | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Matching dimension                                                            |
| 29  | `guide.expertise.wellness`       | `guide-profile.md` §expertise_vector.wellness    | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Matching dimension                                                            |
| 30  | `guide.expertise.photography`    | `guide-profile.md` §expertise_vector.photography | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Matching dimension                                                            |
| 31  | `guide.languages_spoken`         | `guide-profile.md` §languages_spoken             | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Language compatibility                                                        |
| 32  | `guide.translation_available`    | `guide-profile.md` §translation_available        | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Cross-language matching signal                                                |
| 33  | `guide.tour_types`               | `guide-profile.md` §tour_types                   | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Service offering match                                                        |
| 34  | `guide.max_group_size`           | `guide-profile.md` §max_group_size               | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Group capacity constraint                                                     |
| 35  | `guide.min_booking_notice_hours` | `guide-profile.md` §min_booking_notice_hours     | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Booking friction signal                                                       |
| 36  | `guide.cancellation_policy`      | `guide-profile.md` §cancellation_policy          | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Guide reliability signal                                                      |
| 37  | `guide.average_tour_price`       | `guide-profile.md` §average_tour_price           | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Budget alignment with tourist                                                 |
| 38  | `guide.price_tier`               | `guide-profile.md` §price_tier                   | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Price segment                                                                 |
| 39  | `guide.total_tours_completed`    | `guide-profile.md` §total_tours_completed        | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Guide experience signal; cold-start flag if <3                                |
| 40  | `guide.average_rating`           | `guide-profile.md` §average_rating               | **N**                   | **LABEL LEAKAGE** — derived from post-tour ratings                | N                         | Engineered: weighted_mean(ratings)                      | **OUT**        | Label-derived; will be predicted outcome; use `rating_count` as proxy instead |
| 41  | `guide.rating_count`             | `guide-profile.md` §rating_count                 | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Guide experience breadth; surrogate for quality without being label           |
| 42  | `guide.response_rate`            | `guide-profile.md` §response_rate                | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Guide responsiveness signal; behavioral, not label                            |
| 43  | `guide.response_time_minutes`    | `guide-profile.md` §response_time_minutes        | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Communication quality signal                                                  |
| 44  | `guide.cancellation_rate`        | `guide-profile.md` §cancellation_rate            | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Guide reliability signal                                                      |
| 45  | `guide.repeat_tourist_rate`      | `guide-profile.md` §repeat_tourist_rate          | **N**                   | **FUTURE-DATA LEAKAGE** — computed from post-tour repeat behavior | N                         | Raw                                                     | **OUT**        | Outcome of past tours; not available at prediction time                       |
| 46  | `guide.verified_badges`          | `guide-profile.md` §verified_badges              | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Quality signal; rule-based, not model-derived                                 |
| 47  | `guide.tier`                     | `guide-profile.md` §tier                         | Y                       | N                                                                 | N                         | Engineered: derived from tour_count + rating thresholds | IN             | Guide tier (free/professional/expert); platform signal                        |
| 48  | `guide.expertise_embedding`      | `guide-profile.md` §expertise_embedding          | Y                       | N                                                                 | N                         | Engineered: embed(expertise_vector)                     | IN             | 64-dim embedding; primary matching representation                             |
| 49  | `guide.tat_license`              | `guide-profile.md` §tat_license                  | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Regulatory compliance signal                                                  |
| 50  | `guide.license_verified`         | `guide-profile.md` §license_verified             | Y                       | N                                                                 | N                         | Raw                                                     | IN             | Verification status; trust signal                                             |

### Booking / Request Features

| #   | Feature Name                   | Source                                                         | Available at Pred. Time | Leakage Risk | Ethical / Regulatory Flag | Raw / Engineered | Recommendation | Reason                                                        |
| --- | ------------------------------ | -------------------------------------------------------------- | ----------------------- | ------------ | ------------------------- | ---------------- | -------------- | ------------------------------------------------------------- |
| 51  | `booking.requested_date`       | `booking-transaction.md` §booking_request.requested_date       | Y                       | N            | N                         | Raw              | IN             | Temporal context                                              |
| 52  | `booking.requested_start_time` | `booking-transaction.md` §booking_request.requested_start_time | Y                       | N            | N                         | Raw              | IN             | Scheduling feasibility                                        |
| 53  | `booking.duration_hours`       | `booking-transaction.md` §booking_request.duration_hours       | Y                       | N            | N                         | Raw              | IN             | Tour scope signal                                             |
| 54  | `booking.group_size`           | `booking-transaction.md` §booking_request.group_size           | Y                       | N            | N                         | Raw              | IN             | Group composition; affects matching                           |
| 55  | `booking.primary_interest`     | `booking-transaction.md` §booking_request.primary_interest     | Y                       | N            | N                         | Raw              | IN             | Booking intent signal                                         |
| 56  | `booking.special_requests`     | `booking-transaction.md` §booking_request.special_requests     | Y                       | N            | N                         | Raw              | IN             | Customization needs; dietary/accessibility handled separately |
| 57  | `booking.budget_range`         | `booking-transaction.md` §booking_request.budget_range         | Y                       | N            | N                         | Raw              | IN             | Price alignment signal                                        |
| 58  | `booking.date_flexible`        | `booking-transaction.md` §booking_request.date_flexible        | Y                       | N            | N                         | Raw              | IN             | Scheduling flexibility                                        |
| 59  | `booking.time_flexible`        | `booking-transaction.md` §booking_request.time_flexible        | Y                       | N            | N                         | Raw              | IN             | Scheduling flexibility                                        |

### Contextual Features

| #   | Feature Name               | Source                                                  | Available at Pred. Time | Leakage Risk | Ethical / Regulatory Flag | Raw / Engineered | Recommendation | Reason                                  |
| --- | -------------------------- | ------------------------------------------------------- | ----------------------- | ------------ | ------------------------- | ---------------- | -------------- | --------------------------------------- |
| 60  | `context.time_of_day`      | `matching-engine.md` §context_features.time_of_day      | Y                       | N            | N                         | Raw              | IN             | Contextual matching signal              |
| 61  | `context.day_of_week`      | `matching-engine.md` §context_features.day_of_week      | Y                       | N            | N                         | Raw              | IN             | Day pattern signal                      |
| 62  | `context.weather_forecast` | `matching-engine.md` §context_features.weather_forecast | Y                       | N            | N                         | Raw              | IN             | Weather suitability for guide expertise |
| 63  | `context.seasonal_factor`  | `matching-engine.md` §context_features.seasonal_factor  | Y                       | N            | N                         | Raw              | IN             | Peak/off-peak demand signal             |
| 64  | `context.city_demand`      | `matching-engine.md` §context_features.city_demand      | Y                       | N            | N                         | Raw              | IN             | Supply/demand ratio in city             |

### Engineered Interaction Features

| #   | Feature Name      | Source                                            | Available at Pred. Time | Leakage Risk | Ethical / Regulatory Flag | Raw / Engineered                                                        | Recommendation | Reason                                            |
| --- | ----------------- | ------------------------------------------------- | ----------------------- | ------------ | ------------------------- | ----------------------------------------------------------------------- | -------------- | ------------------------------------------------- |
| 65  | `food_align`      | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: tourist.food × guide.expertise.food                         | IN             | Core interest-expertise alignment                 |
| 66  | `culture_align`   | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: tourist.culture × guide.expertise.culture                   | IN             | Core alignment                                    |
| 67  | `adventure_align` | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: tourist.adventure × guide.expertise.adventure               | IN             | Core alignment                                    |
| 68  | `pace_diff`       | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: \|tourist.pace − guide.avg_tour_pace\|                      | IN             | Compatibility metric                              |
| 69  | `pace_score`      | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: 1 − pace_diff                                               | IN             | Normalized pace fit                               |
| 70  | `budget_match`    | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: calculate_budget_overlap(tourist.budget, guide.price_tier)  | IN             | Budget alignment                                  |
| 71  | `language_score`  | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: Jaccard(tourist.languages, guide.languages)                 | IN             | Language overlap                                  |
| 72  | `group_size_fit`  | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: 1 − \|tourist.group_size − guide.preferred_group_size\| / 8 | IN             | Group compatibility                               |
| 73  | `new_guide_bonus` | `satisfaction-predictor.md` §interaction_features | Y                       | N            | N                         | Engineered: 1.0 if guide.total_tours_completed < 10 else 0              | IN             | Cold-start incentive; exploration signal          |
| 74  | `content_score`   | `matching-engine.md` §cosine_similarity           | Y                       | N            | N                         | Engineered: cosine_similarity(tourist_vector, guide_vector)             | IN             | Content-based matching score; primary feature     |
| 75  | `cold_start_flag` | Derived: guide.total_tours_completed < 3          | Y                       | N            | N                         | Engineered: binary threshold                                            | IN             | Cold-start flag; gates collaborative score weight |

---

## Features Excluded (Leakage / Future Data)

| Feature Name                | Source                                            | Exclusion Reason                                              | Type                |
| --------------------------- | ------------------------------------------------- | ------------------------------------------------------------- | ------------------- |
| `tourist.guide_ratings`     | `tourist-profile.md` §guide_ratings               | Post-tour outcome; label                                      | LABEL LEAKAGE       |
| `guide.average_rating`      | `guide-profile.md` §average_rating                | Derived from post-tour ratings; label proxy                   | LABEL LEAKAGE       |
| `guide.repeat_tourist_rate` | `guide-profile.md` §repeat_tourist_rate           | Post-tour outcome; future-data                                | FUTURE-DATA LEAKAGE |
| `repeat_guide_bonus`        | `satisfaction-predictor.md` §interaction_features | Depends on `tourist.rating_for_guide(guide)` — post-tour data | LABEL LEAKAGE       |
| `repeat_guide_rating`       | `satisfaction-predictor.md` §interaction_features | Tourist's past rating of this guide — post-tour               | LABEL LEAKAGE       |
| `collaborative_score`       | `matching-engine.md` §collaborative_score         | Requires tourist-guide-rating tuples (rating = label)         | LABEL LEAKAGE       |

---

## Proxy-Drop Test Results

> Cannot execute — no data present. Requires pilot dataset to run A/B model comparison.
>
> **Two strongest demographic candidate features** (identified for proxy-drop test):
>
> 1. `tourist.age_group` — proxy-drop reassignment %: **REQUIRES DATA**
> 2. `tourist.travel_style` — proxy-drop reassignment %: **REQUIRES DATA**

**Required to run proxy-drop test:**

- Pilot dataset with minimum 500 bookings
- Labels: poor_experience (1-2 stars or cancellation within 48h)
- Features: all IN features listed above

---

## Missing Inputs Required Before Modeling

| Input                                                       | Required For                    | Status                       |
| ----------------------------------------------------------- | ------------------------------- | ---------------------------- |
| Pilot booking dataset (500+ records)                        | Proxy-drop test, model training | MISSING                      |
| Label definition validation (1-2 stars OR 48h cancellation) | Target definition               | CONFIRMED from Phase 1 Frame |
| Chiang Mai average booking price                            | Dollar exposure calculation     | MISSING                      |
| Poor experience baseline rate                               | Model calibration               | MISSING                      |
| Age group distribution in pilot data                        | Proxy-drop interpretation       | MISSING                      |

---

## Recommended IN Feature Set (Pending Approval)

**Count: 65 features**

**Core matching features (18):**

- Tourist interest dimensions: food, culture, adventure, pace, budget (5)
- Guide expertise dimensions: food, culture, adventure, nightlife, nature, shopping, wellness, photography (8)
- Language match (1)
- Travel style (1)
- Booking group size (1)
- Budget alignment (1)
- Interest expertise alignments: food_align, culture_align, adventure_align (3)
- Pace compatibility: pace_diff, pace_score (2)
- Budget match (1)
- Language score (1)
- Group size fit (1)
- content_score (1)
- cold_start_flag (1)

**Guide quality/proxy features (12):**

- total_tours_completed, rating_count, response_rate, response_time_minutes, cancellation_rate (5)
- average_tour_price, price_tier, tier (3)
- tour_types, max_group_size, min_booking_notice_hours, cancellation_policy (4)

**Contextual features (8):**

- time_of_day, day_of_week, weather_forecast, seasonal_factor, city_demand (5)
- requested_date, requested_start_time, duration_hours (3)

**Engagement signals (6):**

- completed_tours, viewed_guides, search_queries, booking_frequency (4)
- viewed_guides_count, search_depth (2, derived)

**Embedding features (4):**

- tourist.interest_vector (64-dim), guide.expertise_embedding (64-dim) — treated as 2 features
- tourist.segment, guide.segment (2)

**Hard-constraint features (3, flagged):**

- tourist.mobility, tourist.dietary_restrictions, tourist.accessibility_needs — FLAG only, not predictive inputs

**Explicitly OUT (6):**

- tourist.age_group — regulatory sensitivity
- tourist.guide_ratings — label leakage
- guide.average_rating — label leakage
- guide.repeat_tourist_rate — future-data leakage
- repeat_guide_bonus — label leakage
- collaborative_score — label leakage

---

**Status**: COMPLETE — Awaiting per-feature approval
