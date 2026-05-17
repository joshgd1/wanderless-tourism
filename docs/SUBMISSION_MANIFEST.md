# WanderLess Submission Manifest

**Project**: WanderLess — Compatibility Intelligence Layer for Local Tourism
**Submission Date**: 2026-05-14
**Grading Rubric**: MGMT655 Team Project

---

## Required Deliverables

| Deliverable                     | File / Folder                             | Purpose                                         | Rubric Supported       | Status   |
| ------------------------------- | ----------------------------------------- | ----------------------------------------------- | ---------------------- | -------- |
| Executive Summary (4 pages max) | `SUBMISSION_EXECUTIVE_SUMMARY_4P.md`      | Concise venture summary for graders             | Market & Problem (25%) | Required |
| Working Product                 | `app/`, `backend/`                        | Live Flutter app + Python API                   | Product & Demo (30%)   | Required |
| Business Model Documentation    | `docs/BUSINESS_MODEL_ASSUMPTIONS.md`      | Commission logic, unit economics, pilot metrics | Business Model (20%)   | Required |
| COC Decision Log                | `docs/COC_DECISION_LOG_A_PLUS.md`         | Decision journey, rejected/accepted choices     | Team & Execution (15%) | Required |
| ML Claims Matrix                | `docs/ML_CLAIMS_IMPLEMENTATION_MATRIX.md` | Implementation status per ML claim              | AI/ML Depth (10%)      | Required |
| Presentation Guide              | `docs/PRESENTATION_GUIDE.md`              | Demo script, kill list, backup commands         | Product & Demo (30%)   | Required |
| Validation Report               | `docs/VALIDATION_REPORT.md`               | Test results, known limitations                 | Product & Demo (30%)   | Required |
| README                          | `README.md`                               | Grader quick start, evidence locations          | All                    | Required |

---

## Codebase Files

| File / Folder                       | Purpose                                      | Rubric Supported | Status   |
| ----------------------------------- | -------------------------------------------- | ---------------- | -------- |
| `backend/main.py`                   | Nexus API server entry point                 | Product & Demo   | Required |
| `backend/models.py`                 | SQLAlchemy data models                       | Product & Demo   | Required |
| `backend/matching.py`               | Compatibility scoring engine                 | AI/ML Depth      | Required |
| `backend/ml/recommender.py`         | Hybrid recommender (content + collaborative) | AI/ML Depth      | Required |
| `backend/ml/group_formation.py`     | K-Means + DBSCAN clustering                  | AI/ML Depth      | Required |
| `backend/ml/itinerary.py`           | Greedy + 2-opt optimizer                     | AI/ML Depth      | Required |
| `backend/ml/safety_score.py`        | Rule-based safety scoring                    | AI/ML Depth      | Required |
| `backend/ml/pricing.py`             | Dynamic pricing                              | AI/ML Depth      | Required |
| `backend/ml/review_intelligence.py` | XGBoost prototype (not wired)                | AI/ML Depth      | Required |
| `app/lib/main.dart`                 | Flutter app entry                            | Product & Demo   | Required |
| `app/lib/features/auth/`            | Tourist authentication                       | Product & Demo   | Required |
| `app/lib/features/onboarding/`      | 5-dimension interest profile                 | Product & Demo   | Required |
| `app/lib/features/discover/`        | Guide matching screen                        | Product & Demo   | Required |
| `app/lib/features/itinerary/`       | Trip itinerary display                       | Product & Demo   | Required |
| `app/lib/features/booking/`         | Booking flow                                 | Product & Demo   | Required |
| `data/tourist_profiles.csv`         | 400 synthetic tourist profiles               | AI/ML Depth      | Required |
| `data/guide_profiles.csv`           | 60 synthetic guide profiles                  | AI/ML Depth      | Required |
| `data/synthetic_ratings.csv`        | 600 synthetic ratings                        | AI/ML Depth      | Required |

---

## Specification Files

| File / Folder                 | Purpose                | Rubric Supported | Status     |
| ----------------------------- | ---------------------- | ---------------- | ---------- |
| `04-specs/matching-engine.md` | Matching engine design | AI/ML Depth      | Supporting |
| `04-specs/_index.md`          | Spec index             | Team & Execution | Supporting |
| `ENTERPRISE_BRIEF.md`         | Product brief          | Market & Problem | Supporting |

---

## Research Files

| File / Folder                                      | Purpose             | Rubric Supported | Status     |
| -------------------------------------------------- | ------------------- | ---------------- | ---------- |
| `01-analysis/00-executive-summary.md`              | Initial analysis    | Market & Problem | Supporting |
| `01-analysis/01-research/02-ecosystem-platform.md` | Competitor analysis | Market & Problem | Supporting |
| `01-analysis/03-ml-architecture/01-ml-engine.md`   | ML architecture     | AI/ML Depth      | Supporting |
| `03-user-flows/01-user-flows.md`                   | User journey flows  | Product & Demo   | Supporting |

---

## Supporting Documentation

| File                                      | Purpose                  | Rubric Supported | Status   |
| ----------------------------------------- | ------------------------ | ---------------- | -------- |
| `SUBMISSION_EXECUTIVE_SUMMARY_4P.md`      | 4-page executive summary | Market & Problem | Required |
| `docs/VALIDATION_REPORT.md`               | Test validation results  | Product & Demo   | Required |
| `FINAL_GROUP_PROJECT_READINESS_REPORT.md` | Final readiness report   | All              | Required |

---

## NOT Included in Submission

The following are excluded from the submission package:

| File / Folder        | Reason                                            |
| -------------------- | ------------------------------------------------- |
| `.env`               | Contains API keys; gitignored but present locally |
| `node_modules/`      | Playwright dependencies; gitignored               |
| `__pycache__/`       | Python cache; gitignored                          |
| `.pytest_cache/`     | Test cache; gitignored                            |
| `playwright-report/` | Test artifacts; gitignored                        |
| `test-results/`      | Test artifacts; gitignored                        |
| `app/build/`         | Flutter build output; gitignored                  |
| `.dart_tool/`        | Flutter tool cache; gitignored                    |
| `__MACOSX/`          | macOS artifacts; gitignored                       |
| `.DS_Store`          | macOS artifacts; gitignored                       |
| `Figma.png`          | Design artifact; not required for grading         |
| `.session-notes`     | Per-session working notes; gitignored             |
| `journal/`           | Development journal; internal reference only      |

---

## Rubric Coverage Summary

| Rubric Category  | Max Points | Key Evidence Files                                                                                |
| ---------------- | ---------- | ------------------------------------------------------------------------------------------------- |
| Market & Problem | 25         | `SUBMISSION_EXECUTIVE_SUMMARY_4P.md`, `ENTERPRISE_BRIEF.md`, `docs/BUSINESS_MODEL_ASSUMPTIONS.md` |
| Product & Demo   | 30         | `app/`, `backend/`, `docs/PRESENTATION_GUIDE.md`, `docs/VALIDATION_REPORT.md`                     |
| Business Model   | 20         | `docs/BUSINESS_MODEL_ASSUMPTIONS.md`, `docs/COC_DECISION_LOG_A_PLUS.md`                           |
| Team & Execution | 15         | `docs/COC_DECISION_LOG_A_PLUS.md`, `docs/SUBMISSION_MANIFEST.md`                                  |
| AI/ML Depth      | 10         | `docs/ML_CLAIMS_IMPLEMENTATION_MATRIX.md`, `backend/ml/`                                          |
| **Total**        | **100**    |                                                                                                   |

---

## Quick Grader Navigation

1. **Start here**: `SUBMISSION_EXECUTIVE_SUMMARY_4P.md`
2. **Run demo**: `docs/PRESENTATION_GUIDE.md` → Setup Checklist
3. **Verify ML claims**: `docs/ML_CLAIMS_IMPLEMENTATION_MATRIX.md`
4. **Understand decisions**: `docs/COC_DECISION_LOG_A_PLUS.md`
5. **Check business model**: `docs/BUSINESS_MODEL_ASSUMPTIONS.md`
6. **Validate implementation**: `docs/VALIDATION_REPORT.md`
