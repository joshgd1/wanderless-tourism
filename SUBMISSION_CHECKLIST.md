# Final Submission Checklist

**All items below are required for a complete MGMT655 submission.**

---

## 1. Repository Hygiene (ZERO tolerance for mistakes here)

| # | Check | Status |
|---|-------|--------|
| 1 | No `.env`, `.venv`, `__pycache__`, `.pytest_cache`, `.DS_Store`, `__MACOSX`, `node_modules`, or credentials in git | ✅ |
| 2 | No stale Thailand / Chiang Mai references anywhere in the repo | ✅ |
| 3 | No local duplicates of files that exist elsewhere (e.g., `guide_profiles.csv` at root AND in `data/`) | ✅ |
| 4 | Zip creation script (`scripts/create_submission_zip.sh`) produces zero forbidden files | ✅ |

---

## 2. Required Deliverables at Root Level

| # | File | Purpose | Status |
|---|------|---------|--------|
| 1 | `README.md` | Marker-facing landing page with quick start, rubric map, and 5-minute orientation | ✅ |
| 2 | `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` | 4P executive summary (Product, Price, Place, Promotion) | ✅ |
| 3 | `CO_CONFIGURATION.md` | ML decision framework, rejected alternatives, open questions | ✅ |
| 4 | `MARKET_PROBLEM.md` | Market sizing, problem statement, competitive gap | ✅ |
| 5 | `BUSINESS_MODEL.md` | Revenue model, unit economics, expansion path | ✅ |
| 6 | `MODEL_CARD.md` | ML model disclosure: inputs, outputs, limitations | ✅ |
| 7 | `AI_ML_ARCHITECTURE.md` | Full ML system architecture with algorithm descriptions | ✅ |
| 8 | `DEMO_SCRIPT.md` | Marker-facing demo narration with must-say lines | ✅ |
| 9 | `DEMO_API_COMMANDS.md` | cURL commands for API fallback if Flutter app fails | ✅ |
| 10 | `VALIDATION_REPORT.md` | Evidence of ML claim verification against code | ✅ |
| 11 | `FINAL_RUBRIC_ALIGNMENT.md` | Rubric area → evidence mapping | ✅ |
| 12 | `SUBMISSION_CHECKLIST.md` | This file | ✅ |

---

## 3. Evidence Folder Required Files

| # | File | Purpose | Status |
|---|------|---------|--------|
| 1 | `docs/COC_DECISION_LOG_A_PLUS.md` | Every decision: alternatives considered, trade-offs, rationale | ✅ |
| 2 | `docs/ML_CLAIMS_IMPLEMENTATION_MATRIX.md` | Every AI/ML claim mapped to code and implementation status | ✅ |
| 3 | `docs/PRESENTATION_GUIDE.md` | Must-say lines, tough Q&A, cURL fallback | ✅ |
| 4 | `docs/BUSINESS_MODEL_ASSUMPTIONS.md` | Benchmark sources, team estimates, simulation basis | ✅ |
| 5 | `docs/demo_screenshots/` | Pre-captured screenshots for demo fallback | ✅ |

---

## 4. Backend Required Files

| # | File | Status |
|---|------|--------|
| 1 | `backend/main.py` — FastAPI app | ✅ |
| 2 | `backend/models.py` — Pydantic models | ✅ |
| 3 | `backend/database.py` — SQLite setup | ✅ |
| 4 | `backend/matching.py` — Matching logic | ✅ |
| 5 | `backend/ml/recommender.py` — Hybrid recommender | ✅ |
| 6 | `backend/ml/group_formation.py` — K-Means + DBSCAN | ✅ |
| 7 | `backend/ml/itinerary.py` — Greedy + 2-opt | ✅ |
| 8 | `backend/ml/safety_score.py` — Rule-based safety indicator | ✅ |
| 9 | `backend/ml/pricing.py` — Dynamic pricing | ✅ |
| 10 | `backend/ml/review_intelligence.py` — XGBoost prototype (labeled prototype, not wired) | ✅ |
| 11 | `backend/seed_accounts.py` — Synthetic data seeding | ✅ |
| 12 | `backend/requirements.txt` — Dependencies | ✅ |
| 13 | `backend/tests/` — All pytest tests pass | ✅ 14/14 |

---

## 5. Consistency Checks (MANDATORY before submission)

| # | Check | Rule |
|---|-------|------|
| 1 | No fabricated statistics or unverified claims | Zero tolerance |
| 2 | No "real-time ML" unless latency is actually measured | Must be implemented |
| 3 | No LLM/RAG/CP-SAT claimed unless implemented and wired | Label as future work if not |
| 4 | XGBoost satisfaction model must say "prototype" and "not wired" | Mandatory disclosure |
| 5 | Safety score must say "decision-support" and "not a guarantee" | Mandatory disclosure |
| 6 | Synthetic data must say "synthetic" and "not real user data" | Mandatory disclosure |
| 7 | Simulated booking must say "simulated" | Mandatory disclosure |
| 8 | No self-assessment scores (e.g., "88/100") that anchor the grader low | Remove all |
| 9 | No "77-87/100 indicative total" or similar framing | Remove all |
| 10 | No Chiang Mai / Thailand references | Must be zero |

---

## 6. Test Verification (run these before submitting)

```bash
# 1. Backend tests
cd backend && pytest tests/ -v
# Expected: 14/14 passed

# 2. API smoke test
cd backend && python main.py &
BASE_URL=http://localhost:8000 bash scripts/demo_smoke_test.sh
# Expected: 7/7 pass

# 3. Legacy reference scan
rg -n "Chiang Mai\|Thailand" --type md --type py
# Expected: zero results

# 4. Zip hygiene
bash scripts/create_submission_zip.sh
# Expected: zero forbidden files
```

---

## 7. Demo Reliability

| # | Check | Status |
|---|-------|--------|
| 1 | Flutter app runs OR | ✅ |
| 2 | `DEMO_API_COMMANDS.md` cURL fallback works | ✅ |
| 3 | Screenshots available in `docs/demo_screenshots/` | ✅ |
| 4 | Demo script has must-say lines for marker | ✅ |

---

**Submission is READY FOR GRADING when all ✅ items are confirmed.**

Last verified: 2026-05-17
