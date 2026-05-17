# Wanderless Laos — MGMT655 Team Project

## 1. What This Product Does

Wanderless Laos is an AI/ML decision-support product for compatibility-based local guide matching in Luang Prabang, Laos.

It helps tourists answer: _"Which local guide or group best fits my travel style, safety preference, language, budget, and itinerary needs?"_

It helps operators answer: _"Which guide should we recommend, and why?"_

This is not a generic itinerary generator. The product wedge is **compatibility intelligence** for local guided travel.

---

## 2. Why This Problem Matters

Generic travel platforms are strong at discovery, ratings, and price comparison, but weak at explaining traveler-guide fit. For guided cultural destinations, a poor guide match reduces trust, satisfaction, conversion, and repeat/referral potential.

---

## 3. What Is Implemented

| Capability                             | Status                     | Evidence                              |
| -------------------------------------- | -------------------------- | ------------------------------------- |
| Tourist preference onboarding          | Implemented                | `app/lib/features/onboarding/`        |
| Guide matching (cosine + TruncatedSVD) | Implemented                | `backend/ml/recommender.py`           |
| Group matching (K-Means + DBSCAN)      | Implemented                | `backend/ml/group_formation.py`       |
| Itinerary sequencing (greedy + 2-opt)  | Prototype                  | `backend/ml/itinerary.py`             |
| Safety/trust indicator                 | Prototype decision-support | `backend/ml/safety_score.py`          |
| Dynamic pricing                        | Implemented                | `backend/ml/pricing.py`               |
| Booking flow                           | Simulated                  | `app/lib/features/booking/`           |
| Real payment processing                | Not implemented            | Future work                           |
| Real user pilot                        | Not yet conducted          | Pilot proposed in `BUSINESS_MODEL.md` |
| XGBoost satisfaction model             | Prototype, not wired       | `backend/ml/review_intelligence.py`   |
| CP-SAT solver                          | Not implemented            | Greedy+2-opt used instead             |
| LLM/RAG                                | Not implemented            | Not used                              |

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

## 5. Key Deliverables

| Deliverable          | Path                                 |
| -------------------- | ------------------------------------ |
| Executive Summary    | `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` |
| Market & Problem     | `MARKET_PROBLEM.md`                  |
| Business Model       | `BUSINESS_MODEL.md`                  |
| Model Card           | `MODEL_CARD.md`                      |
| AI/ML Architecture   | `AI_ML_ARCHITECTURE.md`              |
| Demo Script          | `DEMO_SCRIPT.md`                     |
| Demo API Commands    | `DEMO_API_COMMANDS.md`               |
| Validation Report    | `VALIDATION_REPORT.md`               |
| Rubric Alignment     | `FINAL_RUBRIC_ALIGNMENT.md`          |
| COC Decision Log     | `docs/COC_DECISION_LOG_A_PLUS.md`    |
| Submission Checklist | `SUBMISSION_CHECKLIST.md`            |
| Backend              | `backend/`                           |
| Frontend             | `app/`                               |
| Data                 | `data/`                              |

---

## 6. Rubric Mapping

| Rubric Area      | Evidence                                                  | Demonstrates                                                             |
| ---------------- | --------------------------------------------------------- | ------------------------------------------------------------------------ |
| Market & Problem | `MARKET_PROBLEM.md`, `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` | Luang Prabang beachhead; guide trust and compatibility gap               |
| Product & Demo   | `app/`, `backend/`, `DEMO_SCRIPT.md`                      | Working UI, matching flow, safety view, itinerary and booking simulation |
| Business Model   | `BUSINESS_MODEL.md`                                       | Commission-first B2B2C model; pilot metrics; honest assumptions          |
| Team & Execution | `docs/COC_DECISION_LOG_A_PLUS.md`, `VALIDATION_REPORT.md` | Structured decisions; rejected options; validation evidence              |
| AI/ML Depth      | `MODEL_CARD.md`, `AI_ML_ARCHITECTURE.md`, `backend/ml/`   | Compatibility scoring, TruncatedSVD, clustering, heuristic optimization  |

---

## 7. Test Status

**Backend tests: 14/14 passed** (date: 2026-05-17)

Run: `pytest tests/`

---

## 8. Known Limitations

- **Synthetic data**: All matching uses synthetic tourist/guide profiles and ratings
- **Fixed feature weights**: ML weights are hardcoded, not learned from real outcomes
- **No live marketplace integration**: Prototype not connected to real booking systems
- **Booking is simulated**: No real payment processing
- **No real user validation yet**: Pilot with real users is planned post-submission
- **Safety score is decision support**: Human judgment required; not an automated safety guarantee
