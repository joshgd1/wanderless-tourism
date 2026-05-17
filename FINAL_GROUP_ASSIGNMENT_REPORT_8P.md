# WanderLess Tourism Platform — Group Assignment Report

## MGMT 655: Machine Learning for Decision Making | Professor Jack Hong

## SMU MBA Program

**Repository:** https://github.com/joshgd1/wanderless-tourism
**Note:** Professor Hong has been separately granted repository access.

---

<!-- PAGE_BREAK -->

## Page 1 — Executive Launch Brief

### WanderLess: Authentic Local Tourism Matchmaking Platform

**Product Thesis:** WanderLess connects solo and group tourists with verified local guides across Southeast Asia, using a hybrid ML recommender to personalise match quality and an itinerary optimizer to maximise trip satisfaction — all within a simulated booking and payment environment.

**Course:** MGMT 655 Machine Learning for Decision Making
**Instructor:** Professor Jack Hong
**Institution:** Singapore Management University, MBA Programme
**GitHub:** https://github.com/joshgd1/wanderless-tourism

| Dimension               | Detail                                                                        |
| ----------------------- | ----------------------------------------------------------------------------- |
| **Core Function**       | Tourist–Guide matchmaking + itinerary planning                                |
| **ML Engine**           | Hybrid recommender (cosine similarity + TruncatedSVD collaborative filtering) |
| **Group Formation**     | K-Means clustering + DBSCAN outlier detection                                 |
| **Itinerary Optimiser** | Greedy construction + 2-opt local search                                      |
| **Safety Scoring**      | Rule-based decision-support prototype (not a safety guarantee)                |
| **Backend**             | FastAPI + SQLite + JWT authentication                                         |
| **Frontend**            | Flutter cross-platform mobile app                                             |
| **Synthetic Data**      | 400 tourists, 60 guides, 600 ratings across Singapore and Luang Prabang       |
| **Test Suite**          | 14/14 pytest tests passing                                                    |
| **Booking / Payment**   | Fully simulated — no real money moves                                         |

**Decision Summary:** The platform is a proof-of-concept demonstrating applied ML for a two-sided tourism marketplace. The core recommendation and itinerary engines are functional and validated. Safety scoring and dynamic pricing are implemented as rule-based prototypes suitable for decision support. A prototype XGBoost satisfaction predictor exists but is not wired to the live API.

---

<!-- PAGE_BREAK -->

## Page 2 — Business Problem and Market Need

### The Problem: Fragmented, One-Size-Fits-All Tourism

Southeast Asia is the world's fastest-growing tourism region (UNWTO 2024), yet solo and small-group travellers face three persistent problems:

1. **Information asymmetry.** Tourists cannot easily assess guide quality before booking. Reviews on generic platforms are sparse, unverifiable, and subject to fake entries.

2. **Itinerary inefficiency.** Planning a multi-stop trip across a new city requires aggregating transport times, opening hours, meal breaks, and personal preferences — a combinatorial optimisation problem that travellers solve sub-optimally by hand.

3. **Group formation friction.** Solo travellers who want to share a guide's cost and experience have no structured mechanism to find compatible peers.

### Market Context

| Factor                             | Observation                                                                           |
| ---------------------------------- | ------------------------------------------------------------------------------------- |
| **Southeast Asia inbound tourism** | 140 million+ arrivals annually across ASEAN (UNWTO 2024)                              |
| **Solo travel growth**             | Solo travellers now represent ~24% of all outbound trips (Booking.com 2024)           |
| **Guide verification**             | Most platforms rely on self-reported profiles with no structured authenticity signal  |
| **Itinerary planning**             | Majority of travellers use generic travel forums, not personalised ML-driven planners |

### Why Machine Learning

Traditional travel platforms use rule-based filters (star rating, price range). WanderLess upgrades each core function to ML:

- **Matchmaking** moves from keyword search to a hybrid collaborative + content-based recommender that captures both preference alignment and rating history.
- **Group formation** moves from manual coordination to K-Means + DBSCAN clustering that surfaces compatible solo travellers automatically.
- **Itinerary planning** moves from fixed templates to a greedy + 2-opt optimisation that respects time windows, transport modes, and personal energy curves.

The platform does **not** claim to replace travel agents, guarantee safety outcomes, or operate at commercial scale. It demonstrates ML techniques applied to real combinatorial problems in tourism.

---

<!-- PAGE_BREAK -->

## Page 3 — Product Experience for Users

### User Journey: Emma the Solo Traveller in Singapore

Emma is a 30-year-old UX designer from London, travelling solo to Singapore for 4 days. She wants an authentic local experience but doesn't know which guide to choose or how to plan her itinerary efficiently.

**Emma's Journey on WanderLess:**

| Step            | What Emma Does                                                                                                                  | What the Platform Does                                                                                                                                          |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Onboarding   | Creates profile: food (0.8), culture (0.9), adventure (0.4); pace = relaxed; budget = mid; age = 26-35; style = authentic_local | Stores as preference vector in SQLite                                                                                                                           |
| 2. Discovery    | Browses destinations; selects Singapore                                                                                         | Recommender loads Singapore guide pool                                                                                                                          |
| 3. Matchmaking  | Platform shows ranked guide recommendations                                                                                     | Hybrid recommender scores all Singapore guides: 45% cosine similarity (preference-vs-expertise) + 45% TruncatedSVD collaborative rating + 10% destination boost |
| 4. Safety Check | Emma reviews each guide's safety score                                                                                          | Rule-based safety indicator examines license verification, language alignment, tour density → outputs a numeric signal (0–100) and flags                        |
| 5. Group Option | Emma ticks "Open to joining a group"                                                                                            | K-Means (k=3 by elbow method) clusters solo travellers with similar preferences; DBSCAN flags outliers for solo-only routing                                    |
| 6. Booking      | Emma selects guide Wei Ling Tan; platform quotes S$320.00                                                                       | Dynamic pricing applies daily rate × duration × season factor (1.15× for weekend) — all simulated wallet                                                        |
| 7. Itinerary    | Emma clicks "Optimise Itinerary"                                                                                                | Greedy algorithm builds 4-day schedule; 2-opt improves route ordering; outputs time-stamped stops with travel times                                             |
| 8. Post-Trip    | Emma rates Wei Ling Tan 4.5/5                                                                                                   | Rating stored; feeds back into collaborative filtering matrix for future recommendations                                                                        |

**Simulated Environment Notice:** All bookings, wallet balances, and payments are simulated within the platform. No real money is transferred. Safety scores are rule-based decision-support signals, not guarantees of outcome.

---

<!-- PAGE_BREAK -->

## Page 4 — Business Model and Launch Case

### Business Model: B2B2C Platform

WanderLess operates as a two-sided marketplace:

- **Supply side (Guides):** Local guides in Southeast Asian cities create profiles; the platform provides verification, scheduling, and pricing tools.
- **Demand side (Tourists):** Solo and small-group travellers discover guides, plan itineraries, and book (simulated).

**Revenue Model:** Commission on simulated bookings (15% platform fee, configurable). Currently all bookings are simulated — no real payments occur.

### 90-Day Pilot Launch Plan

| Phase       | Timeline   | Focus                                                    | Milestone                                                                                                               |
| ----------- | ---------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Alpha**   | Days 1–30  | Internal team + invited users (Singapore, Luang Prabang) | 50 active tourist profiles; 20 guide profiles; 100 simulated bookings; recommender retrained on collected signals       |
| **Beta**    | Days 31–60 | Expanded cohort (invite-only; ~200 tourists)             | NPS survey; guide retention rate; recommender precision@k evaluation                                                    |
| **Beta II** | Days 61–90 | Open sign-up; 2 additional cities (Hanoi, Bali)          | Safety score validation; dynamic pricing A/B test; XGBoost satisfaction predictor wired to API (if prototype validates) |

### Launch Decision Table

| Criterion                          | Assessment                                                       | Status                                                         |
| ---------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------- |
| Recommender accuracy (precision@5) | Validated on synthetic data; to be re-evaluated on pilot signals | PROCEED with Alpha                                             |
| Guide verification completeness    | License number + language pairs + specialty tags captured        | PROCEED                                                        |
| Itinerary optimiser feasibility    | Greedy + 2-opt confirmed on Singapore test cases                 | PROCEED                                                        |
| Safety scoring maturity            | Rule-based prototype; suitable for decision-support only         | DECISION-SUPPORT FRAMEWORK — do not market as safety guarantee |
| Synthetic booking simulation       | Fully functional; no real payment infrastructure                 | APPROPRIATE for academic project                               |
| XGBoost prototype readiness        | Review intelligence prototype exists; NOT wired to API           | FUTURE WORK — wire after pilot data collected                  |

---

<!-- PAGE_BREAK -->

## Page 5 — AI/ML and Decision-Support Design

### ML Architecture Overview

WanderLess uses five ML-adjacent modules. One is a full ML pipeline (recommender), three are algorithmic (group formation, itinerary, pricing), and one is a rule-based decision-support prototype (safety score). An additional XGBoost prototype exists but is not wired to the live API.

### 1. Hybrid Recommender (ML — Production)

Combines two complementary signals:

| Component               | Algorithm                                                                       | Weight | Input                                                                         |
| ----------------------- | ------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------- |
| Content-based           | Cosine similarity between tourist preference vector and guide expertise vector  | 45%    | Tourist profile (food/culture/adventure interests, pace, budget) + Guide tags |
| Collaborative filtering | TruncatedSVD on tourist-guide rating matrix (k=20 factors), then k-NN retrieval | 45%    | All stored ratings                                                            |
| Destination boost       | Pre-computed boost for guides matching selected destination                     | 10%    | Guide's registered cities                                                     |

**Source:** `backend/ml/recommender.py` — `HybridRecommender` class; `backend/ml/__init__.py` exports `fit_recommender`, `get_recommender`.
**Validation:** Precision@k measured on held-out synthetic test set.

### 2. Group Formation (Algorithmic — Production)

1. Tourist feature vector built from profile (food/culture/adventure interests, age, travel style, language, budget).
2. K-Means clustering (k determined by elbow method on inertia curve) groups tourists by similarity.
3. DBSCAN (eps=0.3, min_samples=3) identifies outlier tourists unsuitable for groups — routed to solo-only matching.
4. Within-cluster language and budget filters ensure practical group viability.

**Source:** `backend/ml/group_formation.py` — `form_groups()` and `suggest_grouping()` functions.

### 3. Itinerary Optimiser (Algorithmic — Production)

Two-stage construction:

- **Stage 1 (Greedy Build):** Places are scored by preference fit × opening-hours validity × travel-time feasibility. Top-scoring feasible places are added sequentially until the daily budget of hours is exhausted.
- **Stage 2 (2-opt Local Search):** The initial route is improved by reversing segments between non-consecutive stops. Iterated until no improvement reduces total travel time.

Input includes: place list, tourist preference weights, transport mode, daily hours budget, energy curve (24-element vector for stamina modelling).

**Source:** `backend/ml/itinerary.py` — `build_itinerary()` function; `_greedy_build()` and `_two_opt_improve()`.

### 4. Safety Score (Rule-Based Prototype — Decision Support)

A composite signal computed from:

| Factor               | Signal                                         |
| -------------------- | ---------------------------------------------- |
| License verification | +20 if verified                                |
| Language alignment   | +10 if tourist/guide language overlap          |
| Tour density         | −5 per additional overlapping tour on same day |
| Traveller fit        | Age/distance/travel-style alignment score      |

**Output:** Numeric score 0–100 and a flag list. This is a **decision-support prototype** — it informs the tourist's judgement but does not guarantee safety outcomes.

**Source:** `backend/ml/safety_score.py` — `compute_safety_score()` function.

### 5. Review Intelligence / Satisfaction Prediction (XGBoost Prototype — Not Wired)

A prototype XGBoost model trained on synthetic ratings to predict tourist satisfaction from guide attributes, booking features, and itinerary characteristics. This prototype **exists and runs** but is **not connected to the live API** — it is a demonstrated capability for future wiring after real pilot data is collected.

**Source:** `backend/ml/review_intelligence.py` — `ReviewIntelligence` class; `get_review_intelligence()` function.

### 6. Dynamic Pricing (Rule-Based — Production)

Rule-based quote engine computing estimated booking cost:

```
price = daily_rate × duration_hours × season_factor × group_size_factor
```

Season factor: 1.15× for Saturday/Sunday bookings (observed higher guide availability on weekends).
Group size factor: 1.0 for solo; 0.85× per additional person (volume incentive).

**Source:** `backend/ml/pricing.py` — `compute_booking_quote()` function.

---

<!-- PAGE_BREAK -->

## Page 6 — Technical Architecture and Developer Handover

### Repository Structure

```
wanderless-tourism/
├── backend/
│   ├── main.py              # FastAPI application — all API routes
│   ├── database.py           # SQLite via SQLAlchemy + async connection pool
│   ├── models.py             # SQLAlchemy ORM models (Tourist, Guide, Booking, etc.)
│   ├── matching.py           # Compatibility scoring + top-K match retrieval
│   ├── seed_accounts.py     # Seed script: 20 SEA guides, test accounts
│   ├── ml/
│   │   ├── __init__.py      # Exports: fit_recommender, form_groups, compute_safety_score, etc.
│   │   ├── recommender.py    # HybridRecommender (cosine + TruncatedSVD)
│   │   ├── group_formation.py # K-Means + DBSCAN clustering
│   │   ├── itinerary.py      # Greedy build + 2-opt local search
│   │   ├── pricing.py        # Dynamic booking quote
│   │   ├── safety_score.py   # Rule-based safety indicator
│   │   └── review_intelligence.py  # XGBoost prototype (not wired)
│   └── requirements.txt     # fastapi, sqlalchemy, scikit-learn, scipy, pandas, uvicorn, etc.
├── app/                     # Flutter cross-platform frontend
├── data/
│   └── generate_synthetic.py # Synthetic data generator (400 tourists, 60 guides, 600 ratings)
├── synthetic_ratings.csv     # Generated rating dataset (synthetic)
├── docs/                    # Demo screenshots and architecture docs
└── journal/                 # Design decision log
```

### Backend API Routes

| Route                         | Method | Auth      | Description                               |
| ----------------------------- | ------ | --------- | ----------------------------------------- |
| `/api/health`                 | GET    | None      | Health check                              |
| `/api/auth/register`          | POST   | None      | Tourist registration                      |
| `/api/auth/login`             | POST   | None      | Tourist login (returns JWT)               |
| `/api/guides`                 | GET    | JWT       | List all guides (filter by destination)   |
| `/api/guides/{id}`            | GET    | JWT       | Guide profile detail                      |
| `/api/guides/login`           | POST   | None      | Guide login (separate from tourist)       |
| `/api/recommendations`        | GET    | JWT       | Top-K personalised guide recommendations  |
| `/api/matches`                | GET    | JWT       | Top-K match scores for a tourist          |
| `/api/pricing/quote`          | POST   | JWT       | Dynamic booking price estimate            |
| `/api/trip-plans`             | POST   | JWT       | Create a trip plan                        |
| `/api/trip-plans/{id}/accept` | POST   | Guide JWT | Guide accepts trip plan                   |
| `/api/safety-score`           | POST   | JWT       | Safety score for a guide-destination pair |
| `/api/groups`                 | POST   | JWT       | Form tourist groups via clustering        |
| `/api/wallet`                 | GET    | JWT       | Wallet balance (simulated)                |
| `/api/wallet/top-up`          | POST   | JWT       | Add simulated funds                       |

### Running the Backend

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python seed_accounts.py          # Seeds 20 SEA guides + test accounts
uvicorn main:app --reload --port 8000
```

**Test accounts (all use password `wanderless123`):**

- Tourist: `test@wanderless.com` (balance: S$5,000 simulated)
- Guide: `guide@wanderless.com` (Mei Ling / Bounmy Phommasak)
- Business: `business@wanderless.com`

### Running Tests

```bash
cd backend && python -m pytest tests/ -x -v
# Expected: 14/14 tests passing
```

---

<!-- PAGE_BREAK -->

## Page 7 — Validation, Limitations, and Risks

### Validation Evidence

**Test Suite:** 14/14 pytest tests passing. Test coverage spans: tourist guide authentication, guide listing and filtering, personalised recommendations, match scoring, trip plan creation and guide acceptance, wallet operations, and pricing.

**Source:** `backend/test/` (pytest test suite); `VALIDATION_REPORT.md` (full test results).

**Demo Screenshot Evidence:** Screenshots of the Flutter app running on iOS simulator demonstrating: login flow, guide discovery, recommendation results, itinerary optimisation, and simulated booking confirmation.

**Source:** `docs/demo_screenshots/README.md` (screenshot inventory and fallback approach).

**ML Implementation Evidence:** All five ML-adjacent modules are implemented in `backend/ml/` with exported functions wired to the FastAPI routes in `backend/main.py`.

### Synthetic Data Disclosure

All ratings, tourist profiles, and guide profiles used for training and evaluation are **synthetically generated** using a calibrated generator:

- **400 synthetic tourists** across Singapore and Luang Prabang (200 per destination)
- **60 synthetic guides** across Singapore and Luang Prabang (30 per destination)
- **600 synthetic ratings** (88% signal + 12% calibrated Gaussian noise added to simulate real-world rating variance)

**Source:** `data/generate_synthetic.py`; `synthetic_ratings.csv`; marked with `rating_source: "synthetic"` field.

### Limitations

| Area                        | Limitation                                                                                   |
| --------------------------- | -------------------------------------------------------------------------------------------- |
| **Collaborative filtering** | Rating matrix is sparse; TruncatedSVD (k=20) may underfit for infrequent tourist-guide pairs |
| **XGBoost prototype**       | Review intelligence model is NOT wired to the live API — it runs in isolation                |
| **Safety scoring**          | Rule-based; does not incorporate real-time GPS, incident reports, or third-party safety APIs |
| **Pricing**                 | Dynamic pricing is rule-based; no ML demand forecasting or competitor price integration      |
| **Synthetic data**          | All ML evaluation on synthetic data — real user behaviour may differ significantly           |
| **Scope**                   | Platform is a proof-of-concept; not deployed, no live payments, no real GPS tracking         |
| **Scalability**             | SQLite is appropriate for demo; PostgreSQL + connection pooling required for production      |

### Risks

| Risk                                             | Severity | Mitigation                                                                                    |
| ------------------------------------------------ | -------- | --------------------------------------------------------------------------------------------- |
| Safety score used as safety guarantee            | HIGH     | Clear labelling: "decision-support prototype, not a safety guarantee" in UI and documentation |
| XGBoost prototype claimed as live feature        | MEDIUM   | Prototype clearly labelled as "future work" pending real pilot data                           |
| Synthetic data results generalised to production | MEDIUM   | Explicit synthetic data disclosure throughout documentation                                   |
| Booking/payment confusion                        | LOW      | Simulated wallet clearly labelled; no real payment endpoints exist                            |

---

<!-- PAGE_BREAK -->

## Page 8 — Final Recommendation and Next Steps

### Recommendation

WanderLess is a well-structured proof-of-concept that demonstrates applied ML for a two-sided tourism marketplace. The implementation is technically sound:

- The **hybrid recommender** (cosine + TruncatedSVD + destination boost) is a legitimate hybrid approach that addresses both cold-start and sparse-rating problems.
- The **itinerary optimiser** (greedy + 2-opt) is a proper two-stage metaheuristic for a real combinatorial problem.
- The **group formation** module (K-Means + DBSCAN) provides a machine learning clustering approach to a UX problem that most platforms solve with manual coordination.
- The **test suite** (14/14 passing) provides regression coverage for all core API paths.

**What this platform is:** A demonstration that ML techniques (collaborative filtering, matrix factorisation, clustering, combinatorial optimisation) solve real travel-planning problems in a composable, testable system.

**What this platform is not:** A production system. All data is synthetic or simulated. Safety scoring is decision-support only. Payments are not real. The XGBoost satisfaction predictor is a prototype.

### Required Disclosures (Maintained in All External Communications)

1. "Booking and payment on WanderLess is fully simulated. No real money is transferred."
2. "Safety scores are a rule-based decision-support prototype — they do not guarantee the safety of any guide or tour."
3. "All tourist, guide, and rating data used in development is synthetic and labelled as such."
4. "The XGBoost review intelligence module is a prototype not yet wired to the live API."
5. "This platform was developed as an academic project for SMU MBA MGMT 655."

### Post-Submission Validation Roadmap

| Item                         | Description                                                                                | Priority |
| ---------------------------- | ------------------------------------------------------------------------------------------ | -------- |
| Wire XGBoost prototype       | Connect `review_intelligence.py` to `/api/recommendations` after real pilot data collected | HIGH     |
| Real safety data integration | Incorporate third-party safety APIs or verified incident reports                           | HIGH     |
| PostgreSQL migration         | Migrate from SQLite to PostgreSQL for production-scale connection pooling                  | MEDIUM   |
| Demand forecasting           | Add ML-based demand forecasting for dynamic pricing accuracy                               | MEDIUM   |
| Real payment integration     | Stripe or PayPal integration replacing simulated wallet                                    | LOW      |

### Contact

For questions about the implementation, contact the development team via the GitHub repository:
**https://github.com/joshgd1/wanderless-tourism**

_Report prepared for MGMT 655: Machine Learning for Decision Making, Professor Jack Hong, Singapore Management University MBA Programme._
