# WanderLess — Final Project Report

## MGMT 655: Machine Learning for Decision Making | Professor Jack Hong | Singapore Management University MBA Programme

**Team:** WanderLess | **Repository:** https://github.com/joshgd1/wanderless-tourism
**Note:** Professor Hong has been granted repository access. Access will be removed after grading as instructed.

---

<!-- PAGE_BREAK -->

## Page 1 — Executive Launch Brief

### WanderLess: AI/ML Decision-Support for Local Guide Matching in Luang Prabang

WanderLess is a pilot-ready AI/ML decision-support prototype for compatibility-based local guide matching in Luang Prabang, Laos. Instead of acting as another generic itinerary generator, it helps tourists and travel operators decide which local guide, group, and itinerary best fits a traveller's language, budget, pace, interests, safety comfort, and travel style.

The prototype uses synthetic but structured data to demonstrate explainable guide matching, segmentation, itinerary logic, safety/trust indicators, and simulated booking. It is suitable for a controlled pilot with local operators or boutique hotel partners.

### Intended Readers

| Reader                                | What This Report Helps Them Decide                                                     |
| ------------------------------------- | -------------------------------------------------------------------------------------- |
| **Business manager approving launch** | Whether WanderLess is ready for a controlled pilot and what risks must be managed      |
| **User of the app**                   | How the app helps choose a compatible guide and understand the recommendation          |
| **Fellow developer taking over**      | How the repository is structured, how the app runs, and where the matching logic lives |

### Key Dimensions

| Dimension                | Detail                                                                       |
| ------------------------ | ---------------------------------------------------------------------------- |
| **Core Function**        | Tourist–Guide compatibility matching + itinerary planning in Luang Prabang   |
| **ML Engine**            | Hybrid recommender: cosine similarity + TruncatedSVD collaborative filtering |
| **Group Formation**      | K-Means clustering + DBSCAN outlier detection                                |
| **Itinerary Optimiser**  | Greedy construction + 2-opt local search                                     |
| **Safety/Trust Scoring** | Rule-based decision-support prototype — not a safety guarantee               |
| **Backend**              | FastAPI + SQLite + JWT authentication                                        |
| **Frontend**             | Flutter cross-platform mobile app                                            |
| **Data**                 | 400 synthetic tourists, 60 synthetic guides, 600 synthetic ratings           |
| **Tests**                | 14/14 pytest tests passing                                                   |
| **Booking / Payment**    | Fully simulated — no real money moves                                        |

---

<!-- PAGE_BREAK -->

## Page 2 — The Problem and Why It Matters

### The Problem: Tourists Cannot Easily Find the Right Local Guide

Tourists visiting Luang Prabang face a specific decision problem: given dozens of local guides with different specialties, languages, and styles, how does a visitor choose someone trustworthy, compatible, and well-suited to their preferences before committing to a multi-day itinerary?

Existing solutions fail on three dimensions:

1. **Information asymmetry.** Reviews on generic platforms are sparse and unverifiable. There is no structured authenticity signal for Luang Prabang's local guide ecosystem.
2. **Itinerary complexity.** Planning a multi-stop trip — balancing opening hours, travel times, meals, energy, and cultural interests — is a combinatorial optimisation problem travellers solve sub-optimally by hand.
3. **Group formation friction.** Solo travellers who want to share a guide's cost have no structured mechanism to find compatible peers.

### Why Luang Prabang as a Beachhead

Luang Prabang is a UNESCO World Heritage town with a concentrated, high-value local guide ecosystem: temple ceremonies, Mekong boat trips, Kuang Si waterfalls, night markets, and alms-giving rituals. The tourist profile (slow travel, cultural immersion, small groups) is well-suited to compatibility-based matching, and the defined geographic scope makes it ideal for a data-constrained prototype.

### Why Machine Learning

Traditional platforms use keyword search and star ratings. WanderLess upgrades each core decision with ML:

- **Guide matching** uses a hybrid recommender combining content-based preference alignment and collaborative rating patterns — producing explainable compatibility scores, not search results.
- **Group formation** uses K-Means + DBSCAN clustering to surface compatible solo travellers automatically.
- **Itinerary planning** uses greedy construction + 2-opt local search to produce routed day-by-day schedules.

---

<!-- PAGE_BREAK -->

## Page 3 — Product Experience for Users

### User Journey: Emma the Solo Traveller in Luang Prabang

Emma is a 30-year-old UX designer from London, travelling solo to Luang Prabang for 4 days. She wants an authentic cultural and food-focused experience but does not know which local guide to choose or how to plan a safe, well-paced itinerary.

**Emma's Journey on WanderLess:**

| Step | User Action                                                                  | App Output                                                                      | Decision Supported                       |
| ---- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ---------------------------------------- |
| 1    | Enters preferences (food, culture, adventure; pace; budget; language; style) | Structured traveller profile stored in database                                 | What kind of trip is needed              |
| 2    | Reviews guide list for Luang Prabang                                         | Ranked guide list scored by compatibility                                       | Which guides are most compatible         |
| 3    | Reads match explanation for each guide                                       | Factor breakdown: preference alignment, collaborative rating, destination match | Why this guide is recommended            |
| 4    | Checks safety/trust indicator and itinerary                                  | Composite safety/trust score (0–100) + optimised itinerary with travel times    | Whether the guide and plan feel suitable |
| 5    | Simulates booking and receives confirmation                                  | Booking confirmation with simulated price quote and wallet debit                | Whether to proceed with the plan         |

The booking flow is simulated. The safety/trust indicator supports user judgement but does not guarantee safety.

### What the Recommender Actually Does

When Emma requests recommendations, the system: (1) builds a numerical preference vector from her profile; (2) scores each Luang Prabang guide using cosine similarity against guide expertise vectors (content-based, 45%); (3) looks up collaborative rating patterns via a TruncatedSVD model (collaborative, 45%); (4) applies a destination boost for Luang Prabang-verified guides (10%). The result is an explainable composite score — each guide's ranking traces to component factors.

---

<!-- PAGE_BREAK -->

## Page 4 — AI/ML and Decision-Support Design

### ML Architecture

WanderLess uses five ML-adjacent modules. One is a full ML pipeline (recommender), three are algorithmic (group formation, itinerary, pricing), and one is a rule-based decision-support prototype (safety/trust score).

| Component                     | Method                                                          | Purpose                                            |
| ----------------------------- | --------------------------------------------------------------- | -------------------------------------------------- |
| **Preference representation** | Normalized feature vectors (food/culture/adventure/pace/budget) | Compare tourist and guide attributes numerically   |
| **Guide matching**            | Cosine similarity between preference and expertise vectors      | Rank guide compatibility                           |
| **Collaborative filtering**   | TruncatedSVD (k=20) on tourist-guide rating matrix              | Surface rating-pattern insights for sparse ratings |
| **Segmentation**              | K-Means clustering + DBSCAN outlier detection                   | Identify traveller group patterns                  |
| **Itinerary logic**           | Greedy construction + 2-opt local search                        | Sequence preference-aware daily routes             |
| **Safety/trust indicator**    | Rule-based weighted score (license, language, density, fit)     | Support safety comfort judgment — not a guarantee  |
| **Dynamic pricing**           | Rule-based quote (daily rate × duration × season × group)       | Provide simulated price estimates                  |
| **Satisfaction prediction**   | XGBoost prototype on synthetic ratings                          | Prototype only — NOT wired to API                  |

### Explainability

- Each compatibility score is decomposed into: content-based fit, collaborative rating fit, and destination boost
- Top match factors and trade-offs are displayed for each guide recommendation
- The safety/trust score shows its component signals (license verification, language alignment, tour density)
- Limitations are disclosed: the score is a decision-support prototype, not a safety certification

### Governance

- All training data is synthetic and labelled `rating_source: "synthetic"`
- Safety/trust score is a rule-based prototype — not a guarantee
- Human escalation path required for safety-related disputes during pilot
- New guides with few ratings may be disadvantaged by collaborative filtering — fair-exposure monitoring needed

---

<!-- PAGE_BREAK -->

## Page 5 — Business Model and Launch Plan

### Business Model: B2B2C Platform for Luang Prabang

WanderLess operates as a two-sided marketplace:

- **Supply side (Guides):** Local Luang Prabang guides create profiles with specialty, language, license, and availability.
- **Demand side (Tourists):** Solo and small-group travellers discover guides, view compatibility scores, and book (simulated).
- **Platform (Operators / Hotels):** Boutique hotel partners can integrate the recommendation layer.

**Revenue Model:** Commission on simulated bookings (15% platform fee, configurable). All bookings are currently simulated — no real payments occur.

### 90-Day Pilot Plan

| Phase       | Timeline   | Focus                                          | Milestone                                                                     |
| ----------- | ---------- | ---------------------------------------------- | ----------------------------------------------------------------------------- |
| **Alpha**   | Days 1–30  | Internal team + invited users in Luang Prabang | 20 tourist profiles; 10–15 guide profiles; 50 simulated bookings              |
| **Beta**    | Days 31–60 | Invite-only cohort (~100 tourists)             | NPS survey; guide acceptance rate; recommender re-evaluation                  |
| **Beta II** | Days 61–90 | Open sign-up; 1–2 additional Laos destinations | Safety/trust score validation; XGBoost predictor wired if prototype validates |

### Launch Decision

| Launch Question    | Current Answer                                              |
| ------------------ | ----------------------------------------------------------- |
| Public launch now? | No, not as full production                                  |
| Controlled pilot?  | Yes, with selected operators/hotels in Luang Prabang        |
| Main risk?         | Synthetic data may not reflect real tourist-guide behaviour |
| Mitigation?        | Pilot with real outcome tracking and human oversight        |

---

<!-- PAGE_BREAK -->

## Page 6 — Technical Architecture and Handoff

### Repository Structure

| Area          | Path                    | Purpose                                        |
| ------------- | ----------------------- | ---------------------------------------------- |
| README        | `README.md`             | Main navigation and quick start                |
| Backend       | `backend/`              | FastAPI API server, matching logic, ML modules |
| Frontend      | `app/`                  | Flutter cross-platform mobile app              |
| Data          | `data/`                 | Synthetic data generator and output CSVs       |
| Model docs    | `MODEL_CARD.md`         | Model logic, training data, limitations        |
| Architecture  | `AI_ML_ARCHITECTURE.md` | Pipeline and governance                        |
| Validation    | `VALIDATION_REPORT.md`  | Test results and smoke-test scenarios          |
| Demo fallback | `DEMO_API_COMMANDS.md`  | curl-based API demo if Flutter unavailable     |

### Developer Flow: Request to Recommendation

```
Tourist enters preferences in Flutter app
  → Frontend sends GET /api/recommendations?tourist_id=...&destination=Luang%20Prabang
  → Backend loads tourist profile from SQLite
  → HybridRecommender scores all Luang Prabang guides:
      45% cosine similarity (preference vs expertise)
      45% TruncatedSVD collaborative rating
      10% Luang Prabang destination boost
  → Optional: form_groups() segments tourists for group matching
  → Optional: build_itinerary() produces optimised route
  → Backend returns ranked guide list with scores and explanations
  → Frontend displays: guide cards, safety/trust indicator, simulated booking
```

### Running the Application

```bash
# Backend
cd backend
pip install -r requirements.txt
python seed_accounts.py     # Seeds test accounts + Luang Prabang guides
python main.py              # Starts FastAPI on localhost:8000

# Tests
pytest tests/                # 14/14 tests passing

# Frontend (if Flutter is set up)
cd app
flutter pub get
flutter run
```

### Test Accounts (password: `wanderless123`)

| Role     | Email                     | Details                                     |
| -------- | ------------------------- | ------------------------------------------- |
| Tourist  | `test@wanderless.com`     | Alex Traveler; S$5,000 simulated wallet     |
| Guide    | `guide@wanderless.com`    | Bounmy Phommasak (Luang Prabang specialist) |
| Business | `business@wanderless.com` | Luang Prabang Heritage Tours                |

---

<!-- PAGE_BREAK -->

## Page 7 — Individual Technical Contributions

### My Role in WanderLess

I served as the primary developer and technical architect for WanderLess. My specific contributions:

| Component               | Contribution                                                             | File(s)                                                                                   |
| ----------------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| **Flutter Mobile App**  | Full mobile frontend — guide discovery, matching UI, booking flow        | `app/lib/features/guide/`, `app/lib/features/discover/`                                   |
| **Guide Matching Flow** | Request acceptance workflow with guide name display and timeout handling | `app/lib/features/guide/screens/guide_jobs_screen.dart`, `app/lib/features/guide_detail/` |
| **API Integration**     | Dio HTTP client with JWT auth and 10s timeout                            | `app/lib/core/api_client.dart`                                                            |
| **Backend Matching**    | Compatibility scoring and recommendation API endpoints                   | `backend/matching.py`, `backend/main.py`                                                  |
| **ML Recommender**      | Hybrid recommender (cosine + TruncatedSVD)                               | `backend/ml/recommender.py`                                                               |
| **Database Schema**     | SQLAlchemy models for tourists, guides, bookings, ratings                | `backend/models.py`                                                                       |

### Technical Decisions I Made

**SQLite for prototype:** Zero setup, runs everywhere. Schema is PostgreSQL-compatible — migration is a one-line connection string change.

**Flutter cross-platform:** Core logic lives in the backend API. Flutter gives iOS and Android from one codebase. `DEMO_API_COMMANDS.md` provides a curl-based fallback if Flutter setup fails.

**Simulated booking:** Real payment integration was out of scope. A simulated wallet demonstrates the full end-to-end flow without regulatory complexity.

**XGBoost as prototype only:** The satisfaction predictor (`backend/ml/review_intelligence.py`) is trained on synthetic data — I deliberately did not wire it to any recommendation endpoint to avoid overclaiming accuracy.

### Key Files I Wrote

**`backend/matching.py`** — Core compatibility scoring returning both a score and a factor breakdown so the Flutter UI can explain _why_ a guide was recommended.

**`app/lib/core/api_client.dart`** — Flutter API client with JWT token injection, 10-second Dio timeout (handles Render free-tier cold starts), and structured error handling.

**`backend/ml/recommender.py`** — Hybrid recommender trained on 600 synthetic ratings during the seed phase using TruncatedSVD (k=20).

---

<!-- PAGE_BREAK -->

## Page 8 — Validation, Limitations, and Next Steps

### Validation

| Area                 | Status                   | Evidence                   |
| -------------------- | ------------------------ | -------------------------- |
| Backend tests        | 14/14 passing            | `VALIDATION_REPORT.md`     |
| Business smoke tests | 5/5 scenarios documented | `VALIDATION_REPORT.md`     |
| API fallback demo    | Available                | `DEMO_API_COMMANDS.md`     |
| Real user pilot      | Not yet conducted        | Required before production |

### Limitations

All ratings, tourist profiles, and guide profiles are **synthetically generated** (88% signal + 12% calibrated noise) and labelled `rating_source: "synthetic"`. Real tourist behaviour may differ significantly. Safety/trust scoring is rule-based — no real-time GPS, incident reports, or third-party safety API integration. The XGBoost satisfaction predictor is a prototype not wired to any API. SQLite is appropriate for demo; PostgreSQL is required for production scale.

### Risk Table

| Risk                                               | Impact | Mitigation                                                       |
| -------------------------------------------------- | ------ | ---------------------------------------------------------------- |
| Synthetic data results not generalising            | MEDIUM | Pilot with real outcome tracking                                 |
| Hardcoded matching weights biasing recommendations | MEDIUM | Retune after pilot data collected                                |
| Safety/trust score misread as a guarantee          | HIGH   | Clear "decision-support prototype only" labelling in UI and docs |
| Demo setup variability (Flutter)                   | LOW    | API fallback via `DEMO_API_COMMANDS.md` always available         |

### Next Steps

**Business:** Secure 3–5 boutique hotel or local operator partners in Luang Prabang; onboard 10–30 guides; define pilot success metrics; establish human escalation process.

**User validation:** Conduct test sessions with real tourists; compare AI-guided match quality against manual recommendation.

**Developer:** Replace synthetic data with real pilot data; tune matching weights from outcomes; wire XGBoost predictor after sufficient real ratings gathered; add fairness monitoring for guide exposure.

---

**Repository:** https://github.com/joshgd1/wanderless-tourism

Professor Hong has been granted repository access. Access will be removed after grading.

---

_WanderLess is a MGMT655 Machine Learning for Decision Making team project. Prototype — not a commercial product. Not for deployment without further development and validation._
