# Wanderless Laos — MGMT655 Team Project

## Product Thesis

WanderLess is an AI/ML decision-support product for compatibility-based local guide matching in Luang Prabang, Laos.

It helps tourists answer: _"Which local guide or group best fits my travel style, safety preference, language, budget, pace, and itinerary needs?"_

It helps travel operators answer: _"Which guide should we recommend, and why?"_

This is not a generic itinerary generator. The product wedge is **compatibility intelligence** for trusted local guided travel.

---

## Final Report

The 4–8 page final group assignment report for Prof. Jack Hong is available here:

**[FINAL_GROUP_ASSIGNMENT_REPORT.md](FINAL_GROUP_ASSIGNMENT_REPORT.md)**

The report satisfies Prof. Hong's audience requirement and is written for:

1. a **business manager** approving launch,
2. a **user of the app**,
3. a **fellow developer** taking over the app.

---

## Why This Problem Matters

Generic travel platforms are strong at discovery, ratings, and price comparison, but weak at explaining traveler-guide fit. In cultural guided tourism, poor guide fit can reduce booking confidence, satisfaction, safety comfort, and repeat/referral potential.

---

## What Is Implemented

| Capability                    | Status                     | Evidence                        |
| ----------------------------- | -------------------------- | ------------------------------- |
| Tourist preference onboarding | Implemented                | `app/`                          |
| Guide matching                | Implemented                | `backend/ml/recommender.py`     |
| Compatibility scoring         | Implemented                | `MODEL_CARD.md`                 |
| Group / segment logic         | Prototype                  | `backend/ml/group_formation.py` |
| Itinerary sequencing          | Prototype                  | `backend/ml/itinerary.py`       |
| Safety/trust indicator        | Prototype decision-support | `backend/ml/safety_score.py`    |
| Booking flow                  | Simulated                  | `DEMO_SCRIPT.md`                |
| Real payment                  | Not implemented            | Future work                     |
| Real user pilot               | Not yet conducted          | `BUSINESS_MODEL.md`             |

**ML architecture:** Hybrid recommender — 45% content-based (cosine similarity) + 45% collaborative (TruncatedSVD matrix factorization) + 10% destination boost. Trained on 600 synthetic ratings (88% genuine signal, 12% calibrated noise). Weights fixed at implementation time; tunable in production.

**Satisfaction prediction (XGBoost):** Prototype model in `backend/ml/review_intelligence.py` — not wired to any recommendation endpoint. Labeled as future work.

---

## Quick Start

### Backend

```bash
cd backend
python -m pip install -r requirements.txt
python -m pytest ../tests
python main.py
```

### Frontend

```bash
cd app
flutter pub get
flutter run
```

Backend runs at `http://localhost:8000`. API docs at `http://localhost:8000/docs`.

**If Flutter setup fails:** Use `DEMO_API_COMMANDS.md` with curl against the backend API. Screenshots in `docs/demo_screenshots/`.

---

## Key Deliverables

| Deliverable                       | Path                                   |
| --------------------------------- | -------------------------------------- |
| **Final group assignment report** | **`FINAL_GROUP_ASSIGNMENT_REPORT.md`** |
| Executive Summary (4P)            | `SUBMISSION_EXECUTIVE_SUMMARY_4P.md`   |
| CO Configuration                  | `CO_CONFIGURATION.md`                  |
| Market & Problem                  | `MARKET_PROBLEM.md`                    |
| Business Model                    | `BUSINESS_MODEL.md`                    |
| Model Card                        | `MODEL_CARD.md`                        |
| AI/ML Architecture                | `AI_ML_ARCHITECTURE.md`                |
| Demo Script                       | `DEMO_SCRIPT.md`                       |
| Demo API Commands                 | `DEMO_API_COMMANDS.md`                 |
| Validation Report                 | `VALIDATION_REPORT.md`                 |
| Rubric Alignment                  | `FINAL_RUBRIC_ALIGNMENT.md`            |
| COC Decision Log                  | `docs/COC_DECISION_LOG_A_PLUS.md`      |
| Submission Checklist              | `SUBMISSION_CHECKLIST.md`              |
| Backend                           | `backend/`                             |
| Frontend                          | `app/`                                 |
| Data                              | `data/`                                |

---

## Rubric Mapping

| Rubric Area      | Primary Evidence                                          | Supporting Evidence                                       |
| ---------------- | --------------------------------------------------------- | --------------------------------------------------------- |
| Market & Problem | `MARKET_PROBLEM.md`, `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` | `docs/MARKET_PROBLEM_A_PLUS.md`                           |
| Product & Demo   | `app/`, `backend/`, `DEMO_SCRIPT.md`                      | `docs/DEMO_A_PLUS_SCRIPT.md`, `docs/VALIDATION_REPORT.md` |
| Business Model   | `BUSINESS_MODEL.md`                                       | `docs/BUSINESS_MODEL_ASSUMPTIONS.md`                      |
| Team & Execution | `docs/COC_DECISION_LOG_A_PLUS.md`                         | `docs/TEAM_EXECUTION_A_PLUS.md`                           |
| AI/ML Depth      | `MODEL_CARD.md`, `AI_ML_ARCHITECTURE.md`, `backend/ml/`   | `docs/ML_CLAIMS_IMPLEMENTATION_MATRIX.md`                 |

---

## Test Status

**Backend tests: 14/14 passed** (date: 2026-05-17)

Run: `cd backend && python -m pytest ../tests`

---

## Known Limitations

- **Synthetic data**: All matching uses synthetic tourist/guide profiles and ratings
- **Fixed feature weights**: ML weights are hardcoded, not learned from real outcomes
- **No live marketplace integration**: Prototype not connected to real booking systems
- **Booking is simulated**: No real payment processing
- **No real user pilot yet**: Pilot with real users is planned post-submission
- **Safety score is decision support**: Human judgment required; not an automated safety guarantee
- **Satisfaction prediction (XGBoost)**: Prototype only, not wired to any recommendation endpoint

---

_WanderLess is a MGMT655 Machine Learning for Decision Making team project. Prototype — not a commercial product. Not for deployment without further development and validation._
