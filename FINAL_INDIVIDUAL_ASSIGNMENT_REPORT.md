# WanderLess — Individual Assignment Report

## MGMT 655: Machine Learning for Decision Making | Professor Jack Hong | Singapore Management University MBA Programme

**Repository:** https://github.com/joshgd1/wanderless-tourism
**Individual Contributor:** joshgd1
**Note:** Professor Hong has been separately granted repository access. Access may be removed after grading as instructed.

---

<!-- PAGE_BREAK -->

## Page 1 — Individual Technical Contribution Overview

### My Role in WanderLess

I served as the primary developer and technical architect for WanderLess, an AI/ML decision-support prototype for compatibility-based local guide matching in Luang Prabang, Laos. My specific contributions include:

| Component                  | My Contribution                                                                           | File(s)                                                                                   |
| -------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Flutter Mobile App**     | Full mobile frontend implementation — guide discovery, matching UI, booking flow          | `app/lib/features/guide/`, `app/lib/features/discover/`                                   |
| **Guide Matching Flow**    | Tourist-to-guide request acceptance workflow with guide name display and timeout handling | `app/lib/features/guide/screens/guide_jobs_screen.dart`, `app/lib/features/guide_detail/` |
| **API Integration**        | Dio-based API client with JWT auth headers and 10s timeout handling                       | `app/lib/core/api_client.dart`                                                            |
| **Backend Matching Logic** | Guide compatibility scoring and recommendation API endpoints                              | `backend/matching.py`, `backend/main.py`                                                  |
| **ML Recommender**         | Hybrid recommender (cosine similarity + TruncatedSVD collaborative filtering)             | `backend/ml/recommender.py`                                                               |
| **Database Schema**        | SQLAlchemy models for tourists, guides, bookings, and ratings                             | `backend/models.py`                                                                       |

### Technical Philosophy

I designed the architecture around **explainability first** — every ML recommendation can be traced back to its component factors (preference alignment, collaborative rating, destination match). This matters for a decision-support system where users need to understand _why_ a guide was recommended, not just see a score.

---

<!-- PAGE_BREAK -->

## Page 2 — What I Built: The Guide Matching System

### The Core User Flow I Implemented

When a tourist opens WanderLess, they enter preferences (food, culture, adventure interests; pace; budget; language; travel style). The system then scores every Luang Prabang guide against those preferences and returns a ranked list. I built the Flutter screens that display this flow and the backend API that powers it.

**My implementation of the recommendation request:**

```
Tourist enters preferences in Flutter app
  → Frontend sends GET /api/recommendations?tourist_id=...&destination=Luang%20Prabang
  → Backend loads tourist profile from SQLite
  → HybridRecommender scores all Luang Prabang guides:
      45% cosine similarity (preference vs expertise)
      45% TruncatedSVD collaborative rating
      10% Luang Prabang destination boost
  → Backend returns ranked guide list with scores and explanations
  → Flutter displays: guide cards, safety/trust indicator, simulated booking
```

### Guide Request Acceptance Flow

One feature I added in the final polish: when a guide views their open requests, they now see "For: [Tourist Name]" instead of their own name, and the acceptance success message correctly says "now guiding [Tourist Name]" instead of showing the guide's own name. This required:

1. The backend `/api/guide/requests` endpoint now returns `guide_name` so guides see who requested them
2. The Flutter guide jobs screen shows the tourist name on each request row
3. Timeout detection on guide detail screen with friendly error and Try Again button

---

<!-- PAGE_BREAK -->

## Page 3 — ML System Design (My Technical Decisions)

### Hybrid Recommender Architecture

I chose a hybrid recommender combining three signals:

1. **Content-based (45%)**: Cosine similarity between tourist preference vector and guide expertise vector
2. **Collaborative (45%)**: TruncatedSVD (k=20) on tourist-guide rating matrix to surface rating patterns
3. **Destination boost (10%)**: Luang Prabang-verified guides get a small boost

**Why hybrid?** Pure collaborative filtering suffers from cold-start (new guides with few ratings). Pure content-based can't capture that a guide is "unusually beloved by travelers like you" (collaborative signal). The 10% destination boost ensures local guides aren't drowned out by more-popular distant alternatives.

### The ML Logic I Implemented

```python
# backend/ml/recommender.py — simplified logic
def score_guide(tourist_profile, guide, svd_model, ratings_matrix):
    # Content-based: preference vs expertise cosine similarity
    content_score = cosine_similarity(tourist_profile.preference_vector,
                                     guide.expertise_vector)

    # Collaborative: SVD-based rating prediction
    collab_score = svd_model.predict(tourist_profile.id, guide.id)

    # Destination boost
    dest_boost = 1.1 if guide.destination == "Luang Prabang" else 1.0

    return 0.45 * content_score + 0.45 * collab_score + 0.10 * dest_boost
```

### Group Formation Engine

I implemented K-Means clustering + DBSCAN outlier detection to group compatible tourists. K-Means finds natural clusters (k chosen via silhouette score); DBSCAN flags solo-preferred travelers who don't fit any cluster.

### Itinerary Optimizer

Greedy construction + 2-opt local search. The greedy phase builds an initial route visiting preferred destinations. The 2-opt phase then swaps edges to reduce total travel time.

---

<!-- PAGE_BREAK -->

## Page 4 — Technical Decisions and Trade-offs

### Decision: SQLite for Prototype

I used SQLite instead of PostgreSQL for the prototype. Rationale: the prototype uses synthetic data (400 tourists, 60 guides, 600 ratings) — no scale pressure. SQLite requires zero setup and runs everywhere. The schema and queries are PostgreSQL-compatible, so migration is a one-line change in production.

### Decision: Flutter Cross-Platform Frontend

I chose Flutter over native iOS/Android because the core matching logic lives in the backend API — the frontend just displays what the API returns. Flutter gives us iOS and Android from one codebase. The API fallback (curl-based demo in `DEMO_API_COMMANDS.md`) works even if Flutter setup fails.

### Decision: Simulated Booking

Real payment integration (Stripe, etc.) was out of scope for a prototype. I implemented a simulated wallet that debits a fictional balance on booking — sufficient to demonstrate the end-to-end flow without regulatory/compliance complexity.

### Decision: XGBoost Satisfaction Predictor as Prototype Only

The satisfaction prediction model (`backend/ml/review_intelligence.py`) uses XGBoost regression trained on synthetic ratings. I deliberately did NOT wire it to any recommendation endpoint because:

- The model is trained on synthetic data, not real outcomes
- Connecting it would imply confidence we don't have
- It's documented as "prototype" so future teams know it exists

### Known Limitations I Acknowledged

| Limitation                   | Why It Exists                        | Impact                                           |
| ---------------------------- | ------------------------------------ | ------------------------------------------------ |
| Synthetic training data      | No real users during prototype       | ML metrics are extrapolated, not validated       |
| Fixed recommendation weights | Weights tuned once at implementation | Can't A/B test without production infrastructure |
| Safety score is rule-based   | No real-time GPS or incident API     | Decision-support only, not a safety guarantee    |

---

<!-- PAGE_BREAK -->

## Page 5 — Codebase Structure for Handoff

### Repository Layout

```
wanderless-tourism/
├── README.md                    # Start here — quick start, test accounts
├── FINAL_GROUP_ASSIGNMENT_REPORT.md   # Group report (all audiences)
├── FINAL_INDIVIDUAL_ASSIGNMENT_REPORT.md  # This file
├── app/                        # Flutter mobile app
│   └── lib/
│       ├── core/api_client.dart    # Dio HTTP client with auth + timeouts
│       └── lib/features/           # Feature modules: auth, discover, guide, booking
├── backend/                    # Python FastAPI backend
│   ├── main.py                 # API server (14 endpoints)
│   ├── models.py               # SQLAlchemy data models
│   ├── matching.py             # Compatibility scoring logic
│   ├── database.py             # SQLite connection + seed data
│   └── ml/
│       ├── recommender.py       # Hybrid recommender
│       ├── group_formation.py  # K-Means + DBSCAN clustering
│       ├── itinerary.py         # Greedy + 2-opt optimizer
│       ├── safety_score.py      # Rule-based safety indicator
│       └── pricing.py           # Dynamic pricing engine
├── data/                       # Synthetic data (400 tourists, 60 guides, 600 ratings)
├── docs/                       # Supporting documentation
│   ├── ML_CLAIMS_IMPLEMENTATION_MATRIX.md  # ML claim verification
│   └── COC_DECISION_LOG_A_PLUS.md           # Full decision history
└── tests/                      # pytest test suite (14/14 passing)
```

### Running My Code

```bash
# Backend
cd backend
pip install -r requirements.txt
python seed_accounts.py    # Seeds test accounts + guides
python main.py             # Starts FastAPI on localhost:8000

# Tests
pytest tests/              # 14/14 tests passing

# Flutter (if available)
cd app
flutter pub get
flutter run

# API fallback if Flutter unavailable
# See DEMO_API_COMMANDS.md
```

### Test Accounts (password: `wanderless123`)

| Role     | Email                     | Details                                     |
| -------- | ------------------------- | ------------------------------------------- |
| Tourist  | `test@wanderless.com`     | Alex Traveler; S$5,000 simulated wallet     |
| Guide    | `guide@wanderless.com`    | Bounmy Phommasak (Luang Prabang specialist) |
| Business | `business@wanderless.com` | Luang Prabang Heritage Tours                |

---

<!-- PAGE_BREAK -->

## Page 6 — Technical Deep Dive: Key Files I Wrote

### `backend/matching.py` — Compatibility Scoring

This module implements the core matching logic. Key function:

```python
def compute_compatibility_score(tourist: TouristProfile,
                                 guide: GuideProfile,
                                 svd_model,
                                 ratings_matrix) -> CompatibilityResult:
    """
    Returns a CompatibilityResult with:
    - overall_score (0-100)
    - content_score (0-100) — cosine similarity
    - collab_score (0-100) — SVD collaborative prediction
    - factors: list of factor breakdowns for explainability
    """
```

The function is called by the `/api/recommendations` endpoint and returns both a score and a factor breakdown — so the Flutter UI can display _why_ a guide was recommended.

### `app/lib/core/api_client.dart` — API Client

I implemented the Flutter API client with:

- JWT token injection via `_authHeaders`
- 10-second Dio timeout to handle cold-start delays on Render free tier
- Empty auth headers for public endpoints (guide detail without login)
- Structured error handling with typed exceptions

### `backend/ml/recommender.py` — Hybrid Recommender

The recommender combines three signals. I trained the TruncatedSVD model on 600 synthetic ratings during the seed phase:

```python
from sklearn.decomposition import TruncatedSVD

svd = TruncatedSVD(n_components=20, random_state=42)
U = svd.fit_transform(ratings_matrix)  # Tourist latent factors
V = svd.components_                    # Guide latent factors
```

---

<!-- PAGE_BREAK -->

## Page 7 — Validation and Testing

### Backend Test Results

I wrote 14 pytest tests covering:

| Test                            | What It Validates                |
| ------------------------------- | -------------------------------- |
| `test_tourist_profile_creation` | Tourist profiles store correctly |
| `test_guide_profile_creation`   | Guide profiles with specialties  |
| `test_recommendation_endpoint`  | API returns ranked guides        |
| `test_booking_flow`             | Simulated booking debits wallet  |
| `test_group_formation`          | K-Means produces valid clusters  |
| `test_itinerary_optimization`   | 2-opt improves over greedy       |

**Result: 14/14 passing** (verified 2026-05-17)

### Smoke Test

I wrote a bash smoke test (`scripts/demo_smoke_test.sh`) that hits all 7 API endpoints and validates response structure. This runs against `localhost:8000` and confirms the backend is live.

### API Demo Fallback

If Flutter isn't available, `DEMO_API_COMMANDS.md` provides curl commands demonstrating every major flow — matching, booking, itinerary — directly against the API.

---

## Page 8 — Lessons Learned and Recommendations

### What I Learned

**1. Hybrid recommenders need explainability layers.**
The 45/45/10 weighting came from iterating on the demo. Initially I used 60/30/10, but the collaborative signal felt too dominant for new guides. The factor breakdown UI (showing each component score) was essential for debugging weight choices.

**2. Timeout handling is a feature, not an afterthought.**
Render free tier cold-starts take 30+ seconds. Without explicit timeout handling and retry UI, the app looks broken. Adding a 10s timeout + "Try Again" button converted a failure mode into acceptable UX.

**3. Synthetic data is a prototyping tool, not a validation tool.**
The 600 synthetic ratings let me demonstrate the ML pipeline end-to-end, but I knew the accuracy metrics were illustrative. Explicit `rating_source: "synthetic"` labels and prototype documentation were necessary to prevent overclaiming.

### Recommendations for Future Work

| Priority | Recommendation                                 | Why                                                       |
| -------- | ---------------------------------------------- | --------------------------------------------------------- |
| High     | Replace synthetic data with real pilot ratings | Collaborative filtering accuracy depends on real patterns |
| High     | Tune recommendation weights from A/B test      | Fixed weights can't adapt to user feedback                |
| Medium   | Wire XGBoost satisfaction predictor to API     | Currently dormant — value locked until wired              |
| Medium   | Add real-time safety signals (GPS check-in)    | Rule-based score needs real-world grounding               |
| Low      | Migrate SQLite → PostgreSQL                    | Schema supports it; only the connection string changes    |

---

**Repository:** https://github.com/joshgd1/wanderless-tourism

**Access note:** Professor Hong has been separately granted repository access. Access may be removed after grading as instructed.

---

_WanderLess is a MGMT655 Machine Learning for Decision Making individual contribution report. Prototype — not a commercial product. Not for deployment without further development and validation._
