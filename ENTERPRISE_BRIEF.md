# WanderLess Enterprise Brief

**WanderLess is a compatibility intelligence layer for local tourism — using ML to match tourists with compatible guides, form optimal travel groups, and generate personalized itineraries.**

Unlike catalog-first platforms (Klook, Viator, GetYourGuide) where travelers browse pre-packaged offerings, WanderLess builds a multi-dimensional profile of each tourist and guide and uses machine learning to surface the right match before browsing begins.

---

## 1. Executive Thesis

Travel remains more catalog-first than compatibility-first at the guide-matching layer. Every major OTA lets you search "tours in Luang Prabang" and sort by popularity. WanderLess asks: _who are you, where have you been, how do you travel_ — and shows you the guides who are most likely to deliver an exceptional experience for someone like you.

The core insight: **compatibility matching has been proven in other consumer domains but remains largely uncaptured in travel**, particularly for local guide matching. WanderLess closes that gap.

---

## 2. Problem Statement

### Catalog-First Platforms Have Three Fundamental Failures

**1. Time waste.** Travelers spend 3–5 hours researching and still end up disappointed. Browsing 200 tour options across 10 platforms with no personalization produces decision fatigue, not good matches.

**2. Guide invisibility.** Booking "an experience" hides the guide's personality, expertise, and communication style until the tour starts. A 4.9-star guide who specializes in history may be a poor match for a traveler who wants food and adventure.

**3. Compatibility gap.** No platform matches by _who you are_ — only _where you're going_. This is the same gap that Netflix, Spotify, and Amazon closed with collaborative filtering 15 years ago. Travel has not closed it.

**Compatibility gap impact:** A guide with a 4.9-star aggregate rating may still be a poor fit for a traveler seeking food and adventure — the rating averages across all guide-tourist combinations and hides individual mismatch patterns. Poor matches reduce satisfaction, increase cancellations, and weaken repeat/referral potential for operators.

---

## 3. Why Catalog-First Tourism Platforms Fail

| Platform Behavior       | Tourist Behavior               | Failure Mode                 |
| ----------------------- | ------------------------------ | ---------------------------- |
| Sort by popularity      | Most popular ≠ best for you    | Compatibility ignored        |
| Filter by destination   | Destination-first              | Guide expertise ignored      |
| Show star ratings       | Aggregate scores hide variance | Individual fit invisible     |
| No personality matching | Can't assess fit pre-booking   | Mismatch discovered mid-tour |

Travel platforms optimize for _catalog coverage_ (more tours, more destinations) and _conversion_ (lower friction checkout). Neither objective produces better _matches_. Compatibility is a negative engineering problem — the platform has to actively solve for it, and none of the major OTAs do.

---

## 4. WanderLess Positioning: Compatibility Intelligence Layer

**Positioning statement:** WanderLess is a _compatibility intelligence layer_ for local tourism marketplaces. The platform's ML layer sits between tourists and guides, learning compatibility patterns from rating data and surfacing the right guide for each tourist before they start browsing.

**Not a generic AI travel planner.** WanderLess does not generate itineraries with LLMs, do natural-language trip planning, or act as an AI concierge. The ML is specifically trained on tourist-guide compatibility signals — not general travel knowledge.

**Three ML subsystems, each solving a specific problem:**

1. **Interest-Compatibility Matching** — Scores tourist-guide pairs (0–100%) using a hybrid recommender that combines content-based preference matching with collaborative filtering on rating patterns.

2. **Group Formation Engine** — Clusters compatible tourists into groups of 3–8 using K-Means + DBSCAN, ensuring demographic and interest coherence while identifying solo-preferred travelers.

3. **Itinerary Optimization** — Constructs day itineraries using greedy construction + 2-opt local search, respecting time windows, budgets, meal breaks, and travel distances.

---

## 5. Three-Sided Marketplace

WanderLess serves three participant types:

### Tourists

- Complete a preference profile (interests, pace, budget, dietary, language)
- Receive ranked guide recommendations personalized to their profile
- Can browse curated destinations or receive ML-suggested destinations
- Book guides, join groups, receive generated itineraries

### Guides

- Create profiles with expertise tags, languages, license information, pace style
- Receive inbound match requests from compatible tourists
- Can broadcast availability and accept/reject match requests
- Access dashboard with earnings, tourist history, and satisfaction metrics

### Business Partners

- Local operators (restaurants, venues, activity providers) listed as POIs in the itinerary engine
- Receive referral traffic from guided tourists
- Can update pricing, hours, and crowd-level data
- Pay per-visited-referral commission (5–10%)

---

## 6. AI/ML Decision-Support Layer

### What the ML Actually Does

The ML layer is a **recommendation and optimization engine** — not a generative AI or LLM-based system. It does not produce natural-language itineraries or engage in conversational trip planning.

**Implemented ML capabilities:**

| Capability             | Algorithm                                                        | Status      | Notes                                                        |
| ---------------------- | ---------------------------------------------------------------- | ----------- | ------------------------------------------------------------ |
| Tourist-Guide Matching | Hybrid: cosine similarity + TruncatedSVD collaborative filtering | Implemented | 45% content / 45% collab / 10% destination boost             |
| Group Formation        | K-Means clustering + DBSCAN outlier detection                    | Implemented | 3–8 tourists per group, silhouette-score optimal k           |
| Itinerary Construction | Greedy construction + 2-opt local search                         | Implemented | Respects time windows, budgets, meal breaks                  |
| Cold-Start Handling    | Global mean fallback + content-only mode                         | Implemented | Tourists/guides with <5 ratings get content-weighted scoring |

**ML capabilities described in documentation but not yet wired to production endpoints:**

| Capability              | Algorithm                | Status           | Production Readiness                                                                               |
| ----------------------- | ------------------------ | ---------------- | -------------------------------------------------------------------------------------------------- |
| Satisfaction Prediction | XGBoost regression       | Not wired to API | Prototype model in `backend/ml/review_intelligence.py`; not yet exposed as a recommendation signal |
| Itinerary Optimization  | CP-SAT constraint solver | Not implemented  | Described in architecture doc; `backend/ml/itinerary.py` uses greedy+2-opt instead                 |

**Key constraint:** The hybrid recommender weights (45/45/10) are fixed at implementation time. A production system would expose these as tunable A/B test parameters.

**Cold-start synthetic data:** Launch uses synthetic tourist-guide ratings (600 tuples, 88% genuine signal + 12% calibrated noise) to bootstrap the collaborative filtering model before real rating data accumulates.

---

## 7. Business Model

### Revenue Streams

| Revenue Stream            | Rate         | Trigger                             |
| ------------------------- | ------------ | ----------------------------------- |
| Booking commission        | 15–18%       | Tourist completes booking           |
| Guide premium tools       | $14.99/month | Guide exceeds 20 lifetime bookings  |
| Business partner referral | 5–10%        | Tourist visits listed partner venue |

### Unit Economics

**Tourist side:**

- CAC: $5–15 (paid acquisition channels)
- LTV: $45–90 (1–2 repeat bookings/year at $45 average booking value)
- Payback: 1 trip

**Guide side:**

- CAC: $0 (organic inbound; guides self-register)
- LTV: $600–1,200/year (estimated from $50–100 average tour value × 12 bookings/year)
- Payback: 1–2 tours

### Three-Sided Marketplace Dynamics

The platform must balance two sides: tourists want more guide choice; guides want more tourist volume. Commission rate (15–18%) is calibrated against comparable platforms (Viator ~25%, GetYourGuide ~20%). At equilibrium, the platform takes 16–17% of gross booking value with minimal disintermediation risk (estimated 20–30% of tourists would attempt direct guide contact without the platform — consistent with industry benchmarks for agency-model platforms).

**Disintermediation note:** Some tourists and guides will attempt to transact outside the platform after initial contact. This is accepted as a marketplace tax; the platform's value shifts from "transactional" to "discovery and verification" over time.

---

## 8. Risks and Mitigations

| Risk                                              | Likelihood | Impact | Mitigation                                                                    |
| ------------------------------------------------- | ---------- | ------ | ----------------------------------------------------------------------------- |
| Guide quality misrepresentation                   | Medium     | High   | Post-tour rating divergence detection; profile re-verification flow           |
| Cold-start new guides get no matches              | High       | Medium | Probationary boost for new guides; synthetic rating prior                     |
| Group formation produces awkward clusters         | Medium     | Medium | Silhouette-score guard; solo-traveler override option                         |
| Itinerary optimization produces suboptimal routes | Medium     | Low    | 2-opt local search provides good-enough solutions; CP-SAT upgrade path exists |
| Collaborative filtering popularity bias           | Low        | Medium | Inverse-frequency regularization; diversity floor in recommendations          |
| Data moat takes too long to build                 | Medium     | High   | Launch with synthetic data; 10K tour milestone needed for full CF uplift      |

---

## 9. Prototype Limitations

This is an academic team project demonstrating ML system design for a local tourism marketplace. The following limitations are explicitly acknowledged:

**ML model maturity:** The satisfaction prediction (XGBoost) and advanced itinerary optimization (CP-SAT) are described in the architecture documentation but not fully implemented. The implemented ML system consists of the hybrid recommender (content + collaborative) and the group formation engine.

**Training data:** Real tourist-guide compatibility data does not yet exist. The collaborative filtering model is trained on synthetic ratings generated to match distributions observed in comparable platforms. Model accuracy metrics reported in documentation are extrapolated from similar-domain research, not from WanderLess-specific validation.

**Rating model:** Synthetic ratings use an 88% genuine compatibility signal + 12% irreducible noise model, calibrated against a 1–5 scale. Real user ratings will have different noise characteristics.

**Scale:** The system has been tested with synthetic data (400 tourists, 60 guides, 600 ratings) and in-memory processing. No production-scale infrastructure has been deployed.

**Regulatory:** Laos has a formal tourism administration under the Ministry of Information, Culture and Tourism (MICT). Credential tiers are modeled in the data schema but no actual MICT license verification is implemented. Any commercial deployment in Laos would require genuine licensing compliance with applicable Lao PDR tourism regulations.

**Not a production system:** This prototype demonstrates ML architecture and system design. It has not been security-audited, load-tested, or validated for commercial deployment.

---

## 10. Commercial Viability

The $300B local tourism market is underserved by existing recommendation technology. WanderLess's compatibility-first approach is viable if:

1. **Compatibility lift is real.** Early evidence from comparable recommendation systems (Spotify for travel, Airbnb for experiences) suggests that ML-guided matching produces 15–25% higher satisfaction scores vs. popularity-sorted baselines. WanderLess's TAM calculation assumes this lift is achievable and sustainable.

2. **Group formation creates network effects.** When tourists join groups, each additional tourist improves the group formation model's calibration. Network effects in group matching create a data flywheel that improves with scale.

3. **Guide supply scales with demand.** The platform's marketplace dynamics depend on sufficient guide density in each destination. Geographic expansion requires dedicated guide recruitment in each new market.

4. **Commission rate is defensible.** At 15–18%, WanderLess takes less than Viator (~25%) and GetYourGuide (~20%). The platform must justify this rate through superior match quality, not just transaction facilitation.

**Key assumption:** The platform's value proposition (better matches, higher satisfaction) supports premium commission relative to catalog-first competitors. If tourists consistently book the cheapest or most-popular option regardless of compatibility, the ML layer provides no defensible differentiation.

---

## Appendix: Synthetic Data Summary

| Dataset                 | Records | Purpose                                                                         |
| ----------------------- | ------- | ------------------------------------------------------------------------------- |
| `tourist_profiles.csv`  | 400     | Tourist feature vectors (interests, pace, budget, language)                     |
| `guide_profiles.csv`    | 60      | Guide profiles (expertise, personality, licensing tier for Laos MICT framework) |
| `synthetic_ratings.csv` | 600     | Tourist-guide-rating tuples for collaborative filtering bootstrap               |

Synthetic rating model: `4.2 mean, 0.8 std, 0.65 guide-rating correlation, log nonlinear interest match`

---

_WanderLess is a MGMT655 Machine Learning for Decision Making team project. Not a commercial product. Not for deployment without further development and validation._

---

## Supporting Documentation

| Document                                                                           | Purpose                                                                                             |
| ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [docs/COC_DECISION_LOG_A_PLUS.md](docs/COC_DECISION_LOG_A_PLUS.md)                 | Team decision log: every major choice, alternatives considered, trade-offs accepted, rubric mapping |
| [docs/ML_CLAIMS_IMPLEMENTATION_MATRIX.md](docs/ML_CLAIMS_IMPLEMENTATION_MATRIX.md) | ML claim verification: every AI/ML claim mapped to implementation status with code citations        |
| [docs/PRESENTATION_GUIDE.md](docs/PRESENTATION_GUIDE.md)                           | Demo script: 10-minute flow, must-say lines, Q&A for tough questions, cURL fallback commands        |
| [docs/BUSINESS_MODEL_ASSUMPTIONS.md](docs/BUSINESS_MODEL_ASSUMPTIONS.md)           | Business model assumptions: benchmarks, team estimates, prototype simulations, validation targets   |
| [04-specs/safety-trust.md](04-specs/safety-trust.md)                               | Safety & trust spec: decision-support scoring, escalation paths, prototype status                   |
| [04-specs/auth-identity.md](04-specs/auth-identity.md)                             | Authentication & identity: prototype registration, planned KYC, role-based access                   |
| [04-specs/payment-escrow.md](04-specs/payment-escrow.md)                           | Payment & escrow: state machine, commission collection, prototype status                            |
| [04-specs/commission-settlement.md](04-specs/commission-settlement.md)             | Commission settlement: guide payout, tier-based rates, prototype status                             |
