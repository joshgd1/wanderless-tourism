# Wanderless Laos — Group Assignment Report

## MGMT 655: Machine Learning for Decision Making | Professor Jack Hong

## Singapore Management University MBA Programme

**Repository:** https://github.com/joshgd1/wanderless-tourism

**Note:** Professor Hong has been separately granted repository access. Access may be removed after grading as instructed.

---

<!-- PAGE_BREAK -->

## Page 1 — Executive Launch Brief

### Wanderless Laos: AI/ML Decision-Support for Local Guide Matching in Luang Prabang

**Product Thesis:** Wanderless Laos is a pilot-ready AI/ML decision-support prototype for compatibility-based local guide matching in Luang Prabang, Laos. Instead of acting as a generic itinerary generator, the product helps tourists and travel operators decide which local guide, group, and itinerary best fit a traveller's language, budget, pace, interests, safety comfort, and travel style. The current prototype uses synthetic but structured data to demonstrate explainable guide matching, segmentation, itinerary logic, safety/trust indicators, and simulated booking. It is not yet a production deployment, but it is suitable for a controlled pilot with local operators or boutique hotel partners.

**Course:** MGMT 655 Machine Learning for Decision Making
**Instructor:** Professor Jack Hong
**Institution:** Singapore Management University MBA Programme
**GitHub:** https://github.com/joshgd1/wanderless-tourism

| Dimension                | Detail                                                                                         |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| **Core Function**        | Tourist–Guide compatibility matching + itinerary planning in Luang Prabang                     |
| **ML Engine**            | Hybrid recommender: cosine similarity (content-based) + TruncatedSVD (collaborative filtering) |
| **Group Formation**      | K-Means clustering + DBSCAN outlier detection                                                  |
| **Itinerary Optimiser**  | Greedy construction + 2-opt local search                                                       |
| **Safety/Trust Scoring** | Rule-based decision-support prototype — not a safety guarantee                                 |
| **Backend**              | FastAPI + SQLite + JWT authentication                                                          |
| **Frontend**             | Flutter cross-platform mobile app                                                              |
| **Synthetic Data**       | 400 tourists, 60 guides, 600 ratings across Singapore and Luang Prabang                        |
| **Test Suite**           | 14/14 pytest tests passing                                                                     |
| **Booking / Payment**    | Fully simulated — no real money moves                                                          |

### Intended Readers

| Reader                                   | What This Report Helps Them Decide                                                             |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **Business manager approving launch**    | Whether Wanderless Laos is ready for a controlled pilot and what risks must be managed         |
| **User of the app**                      | How the app helps a tourist choose a compatible guide and understand the recommendation        |
| **Fellow developer taking over the app** | How the repository is structured, how the app runs, and where the matching logic is documented |

**Decision Summary:** Wanderless Laos is a proof-of-concept demonstrating applied ML for a two-sided local tourism marketplace in Luang Prabang. The hybrid recommender and itinerary engine are functional and validated. Safety/trust scoring and dynamic pricing are rule-based prototypes suitable for decision support. A prototype XGBoost satisfaction predictor exists but is not wired to the live API. All data is synthetic or simulated.

---

<!-- PAGE_BREAK -->

## Page 2 — Business Problem and Market Need

### The Problem: Tourists Cannot Easily Find the Right Local Guide

Tourists visiting Luang Prabang face a specific decision problem: given dozens of local guides with different specialties, languages, availability, and styles, how does a visitor choose someone trustworthy, compatible, and well-suited to their preferences — before committing to a multi-day itinerary?

Existing solutions fail on three dimensions:

1. **Information asymmetry.** Tourists cannot assess guide quality before booking. Reviews on generic platforms are sparse and unverifiable. There is no structured authenticity signal for Luang Prabang's local guide ecosystem.

2. **Itinerary complexity.** Planning a multi-stop trip in a unfamiliar city — balancing opening hours, travel times, meal breaks, personal energy, and cultural interests — is a combinatorial optimisation problem that travellers solve sub-optimally by hand.

3. **Group formation friction.** Solo travellers who want to share a guide's cost have no structured mechanism to find compatible peers with similar interests and travel styles.

### Why Luang Prabang as a Beachhead

Luang Prabang is a UNESCO World Heritage town with a concentrated, high-value local guide ecosystem. It offers:

- A defined geographic scope suitable for a prototype with limited data
- Culturally distinct guide specialisations (temples, waterfalls, night markets, alms-giving ceremonies, Mekong boat trips)
- A tourist profile (slow travel, cultural immersion, small groups) well-suited to compatibility-based matching
- An existing tourism infrastructure (boutique hotels, local operators) open to data-supported recommendation tools

### Why Machine Learning

Traditional travel platforms use keyword search and star ratings. Wanderless Laos upgrades each core decision with ML:

- **Guide matching** uses a hybrid recommender combining content-based preference alignment and collaborative rating patterns — producing explainable compatibility scores, not just search results.
- **Group formation** uses K-Means + DBSCAN clustering to surface compatible solo travellers automatically — replacing manual coordination with a structured segmentation signal.
- **Itinerary planning** uses greedy construction + 2-opt local search to produce routed day-by-day schedules — replacing generic templates with preference-aware optimisation.

### Stakeholder Table

| Stakeholder             | Pain Point                                                         | Value from Wanderless Laos                                       |
| ----------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------- |
| **Tourist**             | Hard to know which guide fits their preferences and safety comfort | Explainable, ranked guide recommendation with trust indicator    |
| **Local guide**         | Poor-fit bookings waste time and produce bad reviews               | Better-matched tourists; clearer profile signals                 |
| **Hotel / operator**    | Manual guide matching is inconsistent and hard to scale            | Data-supported recommendation layer integrated into booking flow |
| **Destination partner** | Visitor experience quality varies with guide                       | Better trust signals and satisfaction tracking                   |

---

<!-- PAGE_BREAK -->

## Page 3 — Product Experience for Users

### User Journey: Emma the Solo Traveller in Luang Prabang

Emma is a 30-year-old UX designer from London, travelling solo to Luang Prabang for 4 days. She wants an authentic cultural and food-focused experience but does not know which local guide to choose or how to plan a safe, well-paced itinerary.

**Emma's Journey on Wanderless Laos:**

| Step | User Action                                                                                | App Output                                                                      | Decision Supported                       |
| ---- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------- | ---------------------------------------- |
| 1    | Enters travel preferences (food, culture, adventure; pace; budget; language; travel style) | Structured traveller profile stored in database                                 | What kind of trip is needed              |
| 2    | Browses Luang Prabang destination; reviews guide list                                      | Ranked guide list scored by compatibility                                       | Which guides are most compatible         |
| 3    | Reads match explanation for each guide                                                     | Factor breakdown: preference alignment, collaborative rating, destination match | Why this guide is recommended            |
| 4    | Checks safety/trust indicator and itinerary                                                | Composite safety/trust score (0–100) + optimised itinerary with travel times    | Whether the guide and plan feel suitable |
| 5    | Joins a group (optional)                                                                   | K-Means clustering groups Emma with compatible solo travellers                  | Whether group travel is viable           |
| 6    | Proceeds to simulated booking                                                              | Booking confirmation with price quote and simulated wallet debit                | Whether to proceed with the plan         |

**Simulated Environment Notice:** All bookings, wallet balances, and payments are simulated. No real money is transferred. The safety/trust indicator supports user judgement but does not guarantee safety outcomes.

### What the Recommender Actually Does

When Emma requests guide recommendations, the system:

1. Builds a numerical preference vector from her profile (food, culture, adventure interests, pace, budget).
2. Builds a numerical expertise vector for each guide (specialty tags, budget tier, pace style).
3. Computes a **cosine similarity score** between Emma's preference vector and each guide's expertise vector — capturing content-based fit.
4. Looks up historical ratings Emma has not yet given using a **TruncatedSVD model** (k=20 factors) trained on the full tourist-guide rating matrix — capturing collaborative fit.
5. Applies a **destination boost** (+10%) for guides verified in Luang Prabang.
6. Returns a weighted composite score: 45% cosine + 45% collaborative + 10% destination boost, ranked descending.

This is an **explainable recommendation** — the business manager, the tourist, and the developer can all trace which factor drove each guide's ranking.

---

<!-- PAGE_BREAK -->

## Page 4 — Business Model and Launch Case

### Business Model: B2B2C Platform for Luang Prabang

Wanderless Laos operates as a two-sided marketplace focused on Luang Prabang:

- **Supply side (Guides):** Local Luang Prabang guides create profiles with specialty, language, license, and availability. The platform provides verification, scheduling, and pricing tools.
- **Demand side (Tourists):** Solo and small-group travellers discover guides, view compatibility scores, review itineraries, and book (simulated).
- **Platform (Operators / Hotels):** Boutique hotel partners and local tour operators can white-label or integrate the recommendation layer.

**Revenue Model:** Commission on simulated bookings (15% platform fee, configurable). Currently all bookings are simulated — no real payments occur.

### 90-Day Pilot Launch Plan

| Phase       | Timeline   | Focus                                                       | Milestone                                                                                                        |
| ----------- | ---------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Alpha**   | Days 1–30  | Internal team + invited users in Luang Prabang              | 20 active tourist profiles; 10–15 guide profiles; 50 simulated bookings                                          |
| **Beta**    | Days 31–60 | Expanded cohort (invite-only; up to 100 tourists)           | NPS survey; guide acceptance rate; recommender precision@k re-evaluation                                         |
| **Beta II** | Days 61–90 | Open sign-up; 1–2 additional Laos destinations (Vang Vieng) | Safety/trust score validation; dynamic pricing A/B test; XGBoost predictor wired to API (if prototype validates) |

### Launch Decision Table

| Launch Question                                         | Current Answer                                                                                        |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Should this be launched as full public production?      | No — not yet                                                                                          |
| Should it enter a controlled pilot with local partners? | Yes — if 3–5 boutique hotel or operator partners are secured                                          |
| What must be validated during pilot?                    | Guide acceptance rate, tourist satisfaction, cancellation rate, safety escalations, conversion uplift |
| Biggest risk?                                           | Synthetic data may not reflect real tourist-guide behaviour in Luang Prabang                          |
| How is the risk mitigated?                              | Pilot with real outcome tracking and human oversight; results used to retrain the recommender         |

---

<!-- PAGE_BREAK -->

## Page 5 — AI/ML and Decision-Support Design

### ML Architecture Overview

Wanderless Laos uses five ML-adjacent modules. One is a full ML pipeline (recommender), three are algorithmic (group formation, itinerary, pricing), and one is a rule-based decision-support prototype (safety/trust score). An additional XGBoost prototype exists but is not wired to the live API.

This is not only a dashboard or BI tool. The app ranks possible tourist-guide-itinerary combinations across multiple attributes and returns an **explainable recommendation** — each guide's score can be traced back to its component parts.

### Implemented Modules

| Component                     | Method                                                                         | Purpose                                                                  | Status                                                                 |
| ----------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| **Preference representation** | Normalized feature vectors (food/culture/adventure/pace/budget)                | Convert tourist and guide attributes into comparable numerical structure | Implemented — `backend/ml/recommender.py`                              |
| **Guide matching**            | Cosine similarity between tourist preference vector and guide expertise vector | Rank guide fit for a given tourist                                       | Implemented — `backend/ml/recommender.py`                              |
| **Collaborative filtering**   | TruncatedSVD (k=20 factors) on tourist-guide rating matrix + k-NN retrieval    | Surface rating-pattern insights for tourists with few ratings            | Implemented — `backend/ml/recommender.py`                              |
| **Group formation**           | K-Means clustering (elbow method for k) + DBSCAN outlier detection             | Identify compatible solo traveller groups                                | Implemented — `backend/ml/group_formation.py`                          |
| **Itinerary logic**           | Greedy construction + 2-opt local search on place sequence                     | Produce time-feasible, preference-ranked daily routes                    | Implemented — `backend/ml/itinerary.py`                                |
| **Safety/trust indicator**    | Rule-based weighted score (license, language, density, traveller fit)          | Support user safety comfort decision — not a guarantee                   | Implemented prototype — `backend/ml/safety_score.py`                   |
| **Dynamic pricing**           | Rule-based quote (daily rate × duration × season × group factor)               | Provide simulated price estimates                                        | Implemented — `backend/ml/pricing.py`                                  |
| **Satisfaction prediction**   | XGBoost prototype on synthetic ratings                                         | Predict tourist satisfaction from guide + booking features               | Prototype only, NOT wired to API — `backend/ml/review_intelligence.py` |

### Governance and Limitations

- **Synthetic data:** All ratings and profiles are synthetically generated and marked `rating_source: "synthetic"`. Real user behaviour may differ significantly.
- **Safety/trust score:** This is a rule-based decision-support prototype. It does not incorporate real-time GPS, verified incident reports, or third-party safety APIs. It must not be marketed as a safety guarantee.
- **XGBoost prototype:** The satisfaction predictor exists and runs but is not connected to any live API endpoint. It will be wired after real pilot data is collected.
- **Human oversight required:** Safety escalations and guide disputes must have a human escalation path during the pilot.
- **Bias monitoring:** New guides with few ratings may be systematically disadvantaged by the collaborative filtering component. Fair-exposure monitoring should be added before scaling.
- **Privacy:** Tourist preference data and booking history must be handled under a privacy-safe framework before real user onboarding.

---

<!-- PAGE_BREAK -->

## Page 6 — Technical Architecture and Developer Handover

### Repository Structure

```
wanderless-tourism/
├── backend/
│   ├── main.py              # FastAPI application — all API routes
│   ├── database.py          # SQLite via SQLAlchemy + async connection pool
│   ├── models.py            # SQLAlchemy ORM models (Tourist, Guide, Booking, etc.)
│   ├── matching.py          # Compatibility scoring + top-K match retrieval
│   ├── seed_accounts.py    # Seed script: 20 SEA guides (incl. Luang Prabang), test accounts
│   ├── requirements.txt    # fastapi, sqlalchemy, scikit-learn, scipy, pandas, uvicorn, etc.
│   └── ml/
│       ├── __init__.py      # Exports: fit_recommender, form_groups, compute_safety_score, etc.
│       ├── recommender.py    # HybridRecommender — cosine + TruncatedSVD
│       ├── group_formation.py # K-Means + DBSCAN clustering
│       ├── itinerary.py      # Greedy build + 2-opt local search
│       ├── pricing.py        # Dynamic booking quote
│       ├── safety_score.py   # Rule-based safety/trust indicator
│       └── review_intelligence.py  # XGBoost prototype (not wired)
├── app/                     # Flutter cross-platform frontend
├── data/
│   └── generate_synthetic.py # Synthetic data generator (400 tourists, 60 guides, 600 ratings)
├── synthetic_ratings.csv     # Generated rating dataset (synthetic — labelled)
├── docs/                    # Demo screenshots and architecture docs
├── MODEL_CARD.md            # Model logic and limitations
├── AI_ML_ARCHITECTURE.md    # Pipeline and governance
├── CO_CONFIGURATION.md      # Human-AI workflow design
├── VALIDATION_REPORT.md     # Tests and smoke scenarios
├── DEMO_SCRIPT.md           # Live demo script
└── DEMO_API_COMMANDS.md    # API fallback demo commands
```

### Developer Flow: Request to Recommendation

```
1. Tourist enters preferences in Flutter app
2. Frontend sends GET /api/recommendations?tourist_id=...&destination=Luang%20Prabang
3. Backend loads tourist profile from SQLite
4. HybridRecommender builds tourist preference vector and scores all Luang Prabang guides
5. Optional: form_groups() segments tourists for group matching
6. Optional: build_itinerary() produces a optimised route if requested
7. Backend returns ranked guide list with compatibility scores and explanations
8. Frontend displays: guide cards, safety/trust indicator, simulated booking button
```

### Running the Backend

```bash
cd backend
pip install -r requirements.txt
python seed_accounts.py     # Seeds test accounts + Luang Prabang guides
uvicorn main:app --reload --port 8000
# API docs at http://localhost:8000/docs
```

### Running Tests

```bash
cd backend && python -m pytest ../tests -x -v
# Expected: 14/14 tests passing
```

### Running the Frontend

```bash
cd app
flutter pub get
flutter run
# If Flutter setup fails: use DEMO_API_COMMANDS.md against the backend API directly
```

### Key Documentation Files

| File                    | Purpose                                     |
| ----------------------- | ------------------------------------------- |
| `README.md`             | Main navigation and quick start             |
| `MODEL_CARD.md`         | Model logic, training data, limitations     |
| `AI_ML_ARCHITECTURE.md` | Full pipeline and governance                |
| `CO_CONFIGURATION.md`   | Human-AI decision workflow design           |
| `VALIDATION_REPORT.md`  | Test results and smoke-test scenarios       |
| `DEMO_API_COMMANDS.md`  | Fallback API demo if Flutter is unavailable |

### Test Accounts (password: `wanderless123`)

| Role     | Email                     | Details                                     |
| -------- | ------------------------- | ------------------------------------------- |
| Tourist  | `test@wanderless.com`     | Alex Traveler; S$5,000 simulated wallet     |
| Guide    | `guide@wanderless.com`    | Bounmy Phommasak (Luang Prabang specialist) |
| Business | `business@wanderless.com` | Luang Prabang Heritage Tours                |

---

<!-- PAGE_BREAK -->

## Page 7 — Validation, Limitations, and Risks

### Validation Evidence

**Backend Test Suite:** 14/14 pytest tests passing. Test coverage spans: tourist authentication, guide listing and filtering, personalised recommendations, match scoring, trip plan creation and guide acceptance, wallet operations, and pricing.

**Business Smoke Tests:** 5/5 end-to-end scenarios documented in `VALIDATION_REPORT.md`, covering the full guide-request flow from tourist login through trip-plan creation and guide acceptance.

**API Fallback:** `DEMO_API_COMMANDS.md` provides curl commands for all key API endpoints, enabling backend demonstration without Flutter.

**Demo Screenshots:** Available in `docs/demo_screenshots/` if Flutter runtime is unavailable.

**ML Implementation:** All ML-adjacent modules are implemented in `backend/ml/` with exported functions wired to FastAPI routes in `backend/main.py`. See `MODEL_CARD.md` for the full model inventory.

**Real User Pilot:** Not yet conducted. Validation roadmap after pilot described in Page 8.

### Synthetic Data Disclosure

All tourist profiles, guide profiles, and ratings used for development and evaluation are **synthetically generated** and labelled:

- **400 synthetic tourists** across Singapore and Luang Prabang (200 per destination)
- **60 synthetic guides** across Singapore and Luang Prabang (30 per destination)
- **600 synthetic ratings** (88% signal + 12% calibrated Gaussian noise)
- Labelled with `rating_source: "synthetic"` in all data exports

### Limitations

| Area                        | Limitation                                                                                   |
| --------------------------- | -------------------------------------------------------------------------------------------- |
| **Collaborative filtering** | Rating matrix is sparse; TruncatedSVD (k=20) may underfit for infrequent tourist-guide pairs |
| **XGBoost prototype**       | Satisfaction predictor is NOT wired to the live API — runs in isolation only                 |
| **Safety/trust scoring**    | Rule-based; no real-time GPS, incident reports, or third-party safety API integration        |
| **Dynamic pricing**         | Rule-based; no ML demand forecasting or competitor price integration                         |
| **Synthetic data**          | All ML evaluation on synthetic data — real tourist behaviour may differ                      |
| **Scope**                   | Prototype; not deployed, no real payments, no real GPS tracking                              |
| **Scalability**             | SQLite appropriate for demo; PostgreSQL required for production scale                        |

### Risk Table

| Risk                                                | Impact | Mitigation                                                               |
| --------------------------------------------------- | ------ | ------------------------------------------------------------------------ |
| Safety/trust indicator misread as a guarantee       | HIGH   | Clear "decision-support prototype only" label in UI and all docs         |
| XGBoost prototype claimed as a live feature         | MEDIUM | Explicit labelling; not wired to any API endpoint                        |
| Synthetic data results generalised to production    | MEDIUM | Explicit synthetic disclosure throughout all documentation               |
| New guides disadvantaged by collaborative filtering | MEDIUM | Monitor exposure and fair-exposure metrics during pilot                  |
| Booking/payment confusion (simulated vs real)       | LOW    | Simulated wallet labelled at every step; no real payment endpoints exist |
| Flutter setup varies by machine                     | LOW    | API fallback via `DEMO_API_COMMANDS.md` always available                 |

---

<!-- PAGE_BREAK -->

## Page 8 — Final Recommendation and Next Steps

### Final Recommendation

Wanderless Laos should **not** be launched as a full public production system yet. It should proceed to a **controlled 90-day pilot** with 3–5 selected local operators or boutique hotel partners in Luang Prabang.

The product is technically credible: the hybrid recommender (cosine + TruncatedSVD) is a legitimate dual-signal approach, the itinerary optimiser (greedy + 2-opt) is a proper two-stage metaheuristic, and the group formation module (K-Means + DBSCAN) provides structured segmentation where most platforms offer only manual coordination. The 14/14 test suite and documented smoke tests provide regression confidence.

The most important thing the product does **not** claim to be is a safety guarantee. The safety/trust indicator is a rule-based decision-support signal — it helps tourists form a judgement, it does not certify outcomes.

### Business Next Steps

- Secure 3–5 boutique hotel or local operator partners in Luang Prabang
- Onboard 10–30 local guides with verified profiles and license numbers
- Define pilot success metrics: guide acceptance rate, tourist satisfaction (NPS), cancellation rate, safety escalations
- Establish a human escalation process for safety-related disputes
- Confirm privacy and data collection approach before real user onboarding

### User Validation Next Steps

- Conduct test sessions with real tourists in Luang Prabang
- Compare AI-guided match quality against manual hotel recommendation
- Collect structured satisfaction labels after each trip
- Measure booking conversion rate and cancellation rate
- Gather qualitative feedback on the safety/trust indicator and itinerary optimiser

### Developer Next Steps

- Confirm reproducible setup across clean checkout (see `README.md`)
- Harden API error handling and add authentication middleware for non-demo use
- Replace synthetic training data with real pilot data after first cohort
- Retrain and tune matching weights using collected outcomes
- Wire the XGBoost satisfaction predictor after sufficient real ratings are gathered
- Add a monitoring dashboard for guide exposure, rating distributions, and fairness metrics
- Document deployment path (Render, Fly.io, or similar) if moving beyond prototype

### Closing Statement

Wanderless Laos is a credible pilot-ready AI/ML decision-support product. Its strongest value is not itinerary generation — it is **explainable compatibility intelligence** between traveller preferences, guide attributes, itinerary context, and safety comfort. With a controlled pilot, real outcome tracking, and developer hardening, it can become a commercially credible tool for Luang Prabang's local guided tourism ecosystem.

### Repository and Access

**GitHub:** https://github.com/joshgd1/wanderless-tourism

Professor Hong has been separately granted repository access. Access may be removed after grading as instructed.

---

_Report prepared for MGMT 655: Machine Learning for Decision Making, Professor Jack Hong, Singapore Management University MBA Programme._
