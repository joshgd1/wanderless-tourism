# Wanderless Laos — MGMT655 Team Project

## 1. Executive Summary

Wanderless Laos is an AI/ML decision-support product for local guided tourism in Luang Prabang. Instead of generating generic itineraries, it matches tourists to compatible local guides and travel groups based on travel style, risk preference, language, budget, cultural interests, and itinerary constraints. The current prototype uses synthetic but structured tourism data to demonstrate compatibility scoring, clustering, itinerary logic, safety indicators, and booking simulation. The product is designed for travel platforms, local tour operators, and destination-management partners seeking higher-trust guide matching.

---

## 2. Live Demo / How to Run

**Backend:**

```bash
cd backend
pip install -r requirements.txt
pytest
python main.py
```

**Frontend:**

```bash
cd app
flutter pub get
flutter run
```

Backend runs on `http://localhost:8000`. API docs at `http://localhost:8000/docs`.

---

## 3. Key Deliverables

| Deliverable          | Path                                 |
| -------------------- | ------------------------------------ |
| Executive Summary    | `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` |
| Market & Problem     | `MARKET_PROBLEM.md`                  |
| Business Model       | `BUSINESS_MODEL.md`                  |
| Model Card           | `MODEL_CARD.md`                      |
| AI/ML Architecture   | `AI_ML_ARCHITECTURE.md`              |
| COC Decision Log     | `docs/COC_DECISION_LOG_A_PLUS.md`    |
| Demo Script          | `DEMO_SCRIPT.md`                     |
| Demo API Commands    | `DEMO_API_COMMANDS.md`               |
| Validation Report    | `VALIDATION_REPORT.md`               |
| Rubric Alignment     | `FINAL_RUBRIC_ALIGNMENT.md`          |
| Submission Checklist | `SUBMISSION_CHECKLIST.md`            |
| Backend              | `backend/`                           |
| Frontend             | `app/`                               |
| Data                 | `data/`                              |

---

## 4. Rubric Mapping

| Rubric Area      | Where to Find Evidence                                    | What We Demonstrate                                                                 |
| ---------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Market & Problem | `MARKET_PROBLEM.md`, `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` | Clear Luang Prabang beachhead, guide trust and compatibility gap                    |
| Product & Demo   | `app/`, `backend/`, `DEMO_SCRIPT.md`                      | Working UI, matching flow, safety view, itinerary and booking simulation            |
| Business Model   | `BUSINESS_MODEL.md`                                       | Commission model, pilot metrics, unit-economics assumptions                         |
| Team & Execution | `docs/COC_DECISION_LOG_A_PLUS.md`, `VALIDATION_REPORT.md` | Structured decisions, rejected options, validation evidence                         |
| AI/ML Depth      | `MODEL_CARD.md`, `backend/ml/`                            | Compatibility scoring, dimensionality reduction, clustering, optimization heuristic |

---

## 5. What Is Implemented vs Not Implemented

| Capability                 | Status               | Notes                                                                       |
| -------------------------- | -------------------- | --------------------------------------------------------------------------- |
| Tourist onboarding         | Implemented          | UI flow in `app/lib/features/onboarding/`                                   |
| Guide matching             | Implemented          | Cosine similarity + TruncatedSVD hybrid in `backend/ml/recommender.py`      |
| Group matching             | Implemented          | K-Means + DBSCAN clustering in `backend/ml/group_formation.py`              |
| Itinerary suggestion       | Implemented          | Greedy + 2-opt heuristic in `backend/ml/itinerary.py`                       |
| Safety indicator           | Implemented          | Rule-based scoring in `backend/ml/safety_score.py`                          |
| Dynamic pricing            | Implemented          | Rule-based pricing in `backend/ml/pricing.py`                               |
| Booking/payment            | Simulated            | State machine demo; no real payment                                         |
| Real users                 | Not yet              | Pilot proposed                                                              |
| Real production deployment | Not yet              | Prototype only                                                              |
| XGBoost satisfaction model | Prototype, not wired | Code exists in `backend/ml/review_intelligence.py` but not connected to API |
| CP-SAT solver              | Not implemented      | Greedy + 2-opt used instead; CP-SAT described as future production upgrade  |
| LLM/RAG                    | Not implemented      | Not used in current implementation                                          |
| Real-time GPS              | Not implemented      | Not in current scope                                                        |
| Live booking/payments      | Not implemented      | Booking simulation only                                                     |

---

## 6. Test Status

**Backend tests passed: 14/14**
Date: 2026-05-17

Test command: `pytest tests/`
All tests pass with no failures.

---

## 7. Known Limitations

- **Synthetic data**: All matching results use synthetic tourist/guide profiles and ratings
- **Fixed feature weights**: ML weights are hardcoded, not learned from real outcomes
- **No live marketplace integration**: Prototype not connected to real booking systems
- **No real payment processing**: Booking simulation only
- **No field validation**: Pilot with real users is planned post-submission

---

## 8. Demo Fallback

If Flutter frontend fails to start:

1. Run `pytest tests/` — 14/14 pass
2. Use `DEMO_API_COMMANDS.md` to test API endpoints via curl
3. Screenshots available in `docs/demo_screenshots/`
