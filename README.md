# Wanderless Laos — MGMT655 Team Project

## 1. Product Thesis

WanderLess is a compatibility-intelligence marketplace for local guided travel in Laos, starting with Luang Prabang. The product matches tourists with guides based on who they are, not where they're going — using ML-assisted compatibility scoring, group formation, and itinerary optimization.

Unlike catalog-first platforms (Klook, Viator, GetYourGuide) where travelers browse pre-packaged offerings, WanderLess builds a multi-dimensional profile of each tourist and guide and uses machine learning to surface the right match before browsing begins.

**Core insight:** Compatibility matching has been proven in other consumer domains (Netflix, Spotify, Amazon) but remains largely uncaptured in travel, particularly for local guide matching. WanderLess closes that gap.

---

## 2. Why This Problem Matters

Generic travel platforms are strong at discovery, ratings, and price comparison, but weak at explaining traveler-guide fit. For guided cultural destinations, a poor guide match reduces trust, satisfaction, conversion, and repeat/referral potential.

---

## 3. What Is Implemented

| Capability | Algorithm | Status | Evidence |
|-----------|-----------|--------|---------|
| Tourist-Guide Matching | Cosine similarity + TruncatedSVD collaborative filtering | Implemented | `backend/ml/recommender.py` |
| Group Formation | K-Means clustering + DBSCAN outlier detection | Implemented | `backend/ml/group_formation.py` |
| Itinerary Construction | Greedy construction + 2-opt local search | Implemented | `backend/ml/itinerary.py` |
| Safety Indicator | Rule-based scoring | Decision-support prototype | `backend/ml/safety_score.py` |
| Dynamic Pricing | Cost-model pricing | Implemented | `backend/ml/pricing.py` |
| Satisfaction Prediction | XGBoost regression | Prototype, NOT wired to API | `backend/ml/review_intelligence.py` |

**Implemented ML weights:** 45% content-based + 45% collaborative + 10% destination boost (fixed at implementation time; tunable in production).

**Prototype limitations (disclosed):**
- Satisfaction prediction (XGBoost) is a prototype model not wired to any recommendation endpoint
- Collaborative filtering trained on 600 synthetic ratings (88% genuine signal + 12% calibrated noise)
- No real user pilot has been conducted
- Booking flow is simulated (no real payment processing)
- Safety score is a decision-support indicator, not a safety guarantee

---

## 4. Quick Start

**Backend:**

```bash
cd backend
pip install -r requirements.txt
pytest        # 14/14 tests pass
python main.py
```

**Frontend:**

```bash
cd app
flutter pub get
flutter run
```

Backend runs at `http://localhost:8000`. API docs at `http://localhost:8000/docs`.

**If Flutter fails:** Use `DEMO_API_COMMANDS.md` with curl against the backend API. Screenshots in `docs/demo_screenshots/`.

---

## Key Deliverables

| Deliverable | Path |
|------------|------|
| Executive Summary (4P) | `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` |
| CO Configuration | `CO_CONFIGURATION.md` |
| Market & Problem | `MARKET_PROBLEM.md` |
| Business Model | `BUSINESS_MODEL.md` |
| Model Card | `MODEL_CARD.md` |
| AI/ML Architecture | `AI_ML_ARCHITECTURE.md` |
| Demo Script | `DEMO_SCRIPT.md` |
| Demo API Commands | `DEMO_API_COMMANDS.md` |
| Validation Report | `VALIDATION_REPORT.md` |
| Rubric Alignment | `FINAL_RUBRIC_ALIGNMENT.md` |
| COC Decision Log | `docs/COC_DECISION_LOG_A_PLUS.md` |
| Submission Checklist | `SUBMISSION_CHECKLIST.md` |
| Backend | `backend/` |
| Frontend | `app/` |
| Data | `data/` |

---

## 5. Rubric Mapping

| Rubric Area | Primary Evidence | Supporting Evidence |
|------------|-----------------|-------------------|
| Market & Problem | `MARKET_PROBLEM.md`, `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` | `docs/MARKET_PROBLEM_A_PLUS.md` |
| Product & Demo | `app/`, `backend/`, `DEMO_SCRIPT.md` | `docs/DEMO_A_PLUS_SCRIPT.md`, `docs/VALIDATION_REPORT.md` |
| Business Model | `BUSINESS_MODEL.md` | `docs/BUSINESS_MODEL_ASSUMPTIONS.md` |
| Team & Execution | `docs/COC_DECISION_LOG_A_PLUS.md` | `docs/TEAM_EXECUTION_A_PLUS.md` |
| AI/ML Depth | `MODEL_CARD.md`, `AI_ML_ARCHITECTURE.md`, `backend/ml/` | `docs/ML_CLAIMS_IMPLEMENTATION_MATRIX.md` |

---

## 6. Test Status

**Backend tests: 14/14 passed** (date: 2026-05-17)

Run: `pytest tests/`

---

## 7. Known Limitations

- **Synthetic data**: All matching uses synthetic tourist/guide profiles and ratings
- **Fixed feature weights**: ML weights are hardcoded, not learned from real outcomes
- **No live marketplace integration**: Prototype not connected to real booking systems
- **Booking is simulated**: No real payment processing
- **No real user validation yet**: Pilot with real users is planned post-submission
- **Safety score is decision support**: Human judgment required; not an automated safety guarantee
