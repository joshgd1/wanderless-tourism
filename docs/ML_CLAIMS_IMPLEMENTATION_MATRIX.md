# ML Claims Implementation Matrix

This document classifies every AI/ML claim made across WanderLess documentation, specifies implementation status, and provides safe wording for each claim.

**Last updated:** 2026-05-13

---

## How to Read This Matrix

| Status                    | Meaning                                                                                |
| ------------------------- | -------------------------------------------------------------------------------------- |
| **Implemented**           | Code exists in `backend/ml/` and is wired to a production endpoint                     |
| **Partially Implemented** | Code exists but is not yet wired to a production API endpoint, or has limited coverage |
| **Simulated**             | Synthetic/stub implementation used for prototype demonstration                         |
| **Planned**               | Described in architecture documentation; implementation started but not complete       |
| **Unsupported**           | Claimed in marketing or documentation; no corresponding implementation found           |

---

## 1. Interest-Compatibility Matching

| Claim                                                         | Source Document                 | Status                                                | Safe Wording                                                                                    | Notes                                                                                                                                      |
| ------------------------------------------------------------- | ------------------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 40% content-based / 40% collaborative / 20% contextual hybrid | README.md, 01-ml-engine.md      | **Partially Implemented**                             | "45% content / 45% collaborative / 10% destination affinity (hardcoded weights)"                | Weights are hardcoded constants in `recommender.py`, not tunable. Contextual 10% is destination boost, not time/weather/group-size signals |
| Content-based: cosine similarity on interest vectors          | 01-ml-engine.md                 | **Implemented**                                       | "Content-based: cosine similarity between tourist preference vector and guide expertise vector" | `ContentBasedRecommender.score_guides_for_tourist()` in `backend/ml/recommender.py`                                                        |
| Collaborative filtering: ALS (Alternating Least Squares)      | 01-ml-engine.md §2.3.2, ADR-002 | **Unsupported for ALS; Implemented for TruncatedSVD** | "Collaborative filtering: TruncatedSVD matrix factorization"                                    | `CollaborativeRecommender` uses `scipy.svds` (TruncatedSVD), NOT ALS. ADR-002 claims ALS but code uses SVD                                 |
| TruncatedSVD collaborative filtering                          | recommender.py                  | **Implemented**                                       | "TruncatedSVD on tourist×guide rating matrix"                                                   | `CollaborativeRecommender.fit()` decomposes rating matrix with `svds()`                                                                    |
| 64-dimensional interest vectors                               | 01-ml-engine.md                 | **Partially Implemented**                             | "Interest vectors built from 5 raw features (food/culture/adventure/pace/budget)"               | Tourist vectors are 5-dimensional, not 64-dim. 64-dim is aspirational (documented in architecture but not implemented)                     |
| Cold-start: synthetic data generation                         | README.md, 01-ml-engine.md      | **Simulated**                                         | "Synthetic ratings used to bootstrap CF model before real data exists"                          | 600 synthetic ratings in `data/synthetic_ratings.csv` with 88% genuine signal / 12% noise                                                  |
| Confidence interval on compatibility scores                   | 01-ml-engine.md §2.4            | **Not Implemented**                                   | "Compatibility scores reported as point estimates without confidence intervals"                 | No CI calculation in `backend/ml/recommender.py` or `backend/matching.py`                                                                  |
| Matrix factorization via `implicit` library (ALS)             | 01-ml-engine.md                 | **Not Implemented**                                   | "Uses scipy TruncatedSVD, not the `implicit` library"                                           | `recommender.py` imports `scipy.sparse.linalg.svds` and `sklearn` — not `implicit`                                                         |
| Feature dimensionality 64–128 for interest vectors            | 01-ml-engine.md                 | **Not Implemented**                                   | "Current implementation uses 5-dimensional raw feature vectors"                                 | Code uses 5 features; architecture doc describes 64–128 dim with PCA                                                                       |

---

## 2. Group Formation Engine

| Claim                                                       | Source Document                       | Status              | Safe Wording                                                                        | Notes                                                                                          |
| ----------------------------------------------------------- | ------------------------------------- | ------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| K-Means clustering for group formation                      | 01-ml-engine.md, `group_formation.py` | **Implemented**     | "K-Means clustering over tourist feature vectors"                                   | `form_groups()` in `backend/ml/group_formation.py`                                             |
| DBSCAN for outlier/solo detection                           | 01-ml-engine.md, `group_formation.py` | **Implemented**     | "DBSCAN (eps=1.5, min_samples=2) for outlier detection"                             | `DBSCAN` import in `group_formation.py`                                                        |
| Silhouette-score-based optimal k selection (range 3–8)      | 01-ml-engine.md §3.3.1                | **Implemented**     | "Silhouette score used to select optimal k (range 3–8)"                             | Lines 72–78 in `group_formation.py`; falls back to k=3 on scoring failure                      |
| Feature weights: food/culture/adventure at 1.5×             | 01-ml-engine.md §3.3                  | **Not in code**     | "Interest features (food/culture/adventure) receive 1.5× weight in group formation" | Claimed in doc; no weighted clustering in `group_formation.py` — all features use equal weight |
| Group size 3–8 tourists                                     | 01-ml-engine.md                       | **Implemented**     | "Groups of 3–8 tourists; outliers detected as solo candidates"                      | Hardcoded in `form_groups()`                                                                   |
| Solo traveler detection                                     | 01-ml-engine.md                       | **Implemented**     | "DBSCAN labels outliers as solo-traveler candidates"                                | Labels returned via `solo_candidates`                                                          |
| 74-dimensional feature vector (64 interest + 10 behavioral) | 01-ml-engine.md                       | **Not Implemented** | "Group formation uses 5-dimensional feature vector"                                 | Only 5 features used in `_build_tourist_features()`                                            |

---

## 3. Itinerary Optimization

| Claim                                                       | Source Document                 | Status              | Safe Wording                                                                                                          | Notes                                                                                                                                    |
| ----------------------------------------------------------- | ------------------------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| CP-SAT constraint solver for itinerary optimization         | README.md, 01-ml-engine.md      | **Not Implemented** | "Greedy construction + 2-opt local search for itinerary optimization (CP-SAT described as future production upgrade)" | `backend/ml/itinerary.py` docstring explicitly states: "CP-SAT / full Orienteering Problem solver can replace this for production scale" |
| Simulated annealing fallback for itinerary                  | 01-ml-engine.md                 | **Not Implemented** | "Simulated annealing described in architecture; not implemented"                                                      | No simulated annealing code in `backend/ml/itinerary.py`                                                                                 |
| Greedy construction + 2-opt local search                    | `backend/ml/itinerary.py`       | **Implemented**     | "Greedy construction + 2-opt local search"                                                                            | `_greedy_build()` and `_two_opt_improve()` in `itinerary.py`                                                                             |
| Constraint satisfaction (time windows, budget, meal breaks) | 01-ml-engine.md, `itinerary.py` | **Implemented**     | "Hard constraints: opening hours, budget ceiling, meal windows, day end"                                              | `_apply_hard_filters()`, `_maybe_insert_meal()` in `itinerary.py`                                                                        |
| Energy curve modeling                                       | 01-ml-engine.md §4.3.3          | **Not Implemented** | "Tourist energy curves described in architecture; not implemented"                                                    | No energy curve model in `backend/ml/itinerary.py`                                                                                       |
| Weather-aware POI routing                                   | 01-ml-engine.md                 | **Not Implemented** | "Weather integration described as production feature; not implemented"                                                | No weather API calls in itinerary code                                                                                                   |
| Dynamic re-routing                                          | 01-ml-engine.md                 | **Not Implemented** | "Real-time re-routing not implemented in prototype"                                                                   | —                                                                                                                                        |
| OR-Tools CP-SAT as primary solver                           | 01-ml-engine.md ADR-004         | **Not Implemented** | "CP-SAT described as production plan; prototype uses greedy + 2-opt"                                                  | No `ortools` import in codebase                                                                                                          |

---

## 4. Satisfaction Prediction

| Claim                                                          | Source Document            | Status                    | Safe Wording                                                                      | Notes                                                                                       |
| -------------------------------------------------------------- | -------------------------- | ------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| XGBoost regression for satisfaction prediction                 | README.md, 01-ml-engine.md | **Partially Implemented** | "XGBoost regression model in prototype; not yet wired to recommendation endpoint" | `backend/ml/review_intelligence.py` exists and uses XGBoost; not called by any API endpoint |
| Satisfaction prediction as proactive quality intervention      | 01-ml-engine.md            | **Partially Implemented** | "Satisfaction model exists as prototype; not exposed via API"                     | Model trained offline; not in the request path                                              |
| MAE < 0.4, RMSE < 0.6, directional accuracy > 85%              | 01-ml-engine.md            | **Planned**               | "Targets stated in architecture; not validated with real data"                    | No holdout evaluation executed                                                              |
| Feature importance stability monitoring                        | 01-ml-engine.md            | **Not Implemented**       | "SHAP-based feature importance stability not implemented"                         | No SHAP imports or monitoring code                                                          |
| Cold-start blend with content-based fallback                   | 01-ml-engine.md            | **Implemented**           | "Cold-start: global mean rating fallback when tourist has no rating history"      | `CollaborativeRecommender.predict()` returns `global_mean` for unknown tourists             |
| Interaction term modeling (interest match, pace compatibility) | 01-ml-engine.md §5.2.3     | **Not Implemented**       | "Interaction features described in architecture; not in prototype model"          | `review_intelligence.py` uses raw features; no interaction terms                            |
| Guide self-fulfilling prophecy detection                       | 01-ml-engine.md            | **Not Implemented**       | "Leave-one-out training for guide-aware prediction not implemented"               | —                                                                                           |

---

## 5. Backend / Matching Layer

| Claim                                     | Source Document   | Status           | Safe Wording                                                                        | Notes                                                                                    |
| ----------------------------------------- | ----------------- | ---------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Compatibility score 1–5 scale             | `matching.py`     | **Implemented**  | "Compatibility scoring returns 1.0–5.0 range"                                       | `compatibility_score()` in `backend/matching.py`                                         |
| Expertise map matching                    | `matching.py`     | **Implemented**  | "Expertise keywords matched against guide specialty tags"                           | `EXPERTISE_MAP`, `AUTHENTICITY_KEYWORDS`, `CHIANG_MAI_NEIGHBORHOODS` hardcoded constants |
| Authenticity multiplier                   | `matching.py`     | **Implemented**  | "License verification boosts authenticity score by 1.2×"                            | `AUTHENTICITY_KEYWORDS` lookup                                                           |
| Satisfaction prediction wired to endpoint | `backend/main.py` | **Not Verified** | "Satisfaction prediction endpoint could not be verified due to truncated file read" | `main.py` was truncated at line 200; endpoint existence unconfirmed                      |
| JWT-based role authentication             | `backend/main.py` | **Not Verified** | "JWT authentication for tourist/guide/business roles"                               | Same truncation issue                                                                    |
| Rate limiting (100 req/min per IP)        | `backend/main.py` | **Not Verified** | "Rate limiting implemented"                                                         | Same truncation issue                                                                    |

---

## 6. Frontend / Mobile App

| Claim                                  | Source Document        | Status           | Safe Wording                                                 | Notes                                                                                |
| -------------------------------------- | ---------------------- | ---------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| "AI-Guided Matches" in Flutter UI      | `discover_screen.dart` | **Unsupported**  | "Personalized ML matching using compatibility-based scoring" | `mlMatchesProvider` labeled "AI-Guided Matches" — actual ML is content+collab hybrid |
| Safety score endpoint                  | `api_client.dart`      | **Not Verified** | "Safety score API call exists"                               | `getSafetyScore()` called; backend endpoint unconfirmed (main.py truncated)          |
| ML-powered destination recommendations | `api_client.dart`      | **Implemented**  | "ML-powered destination ranking via hybrid recommender"      | `getMlDestinationRecommendations()` calls `recommend_destinations()`                 |
| Guide open requests                    | `api_client.dart`      | **Implemented**  | "Guide availability broadcast API"                           | `getGuideOpenRequests()` exists                                                      |

---

## 7. Data Infrastructure

| Claim                                                          | Source Document | Status                      | Safe Wording                                                        | Notes                                                                    |
| -------------------------------------------------------------- | --------------- | --------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| 10,000 tours for data moat                                     | 01-ml-engine.md | **Unsupported**             | "Data moat milestone stated as estimate; not derived from analysis" | No supporting analysis for 10K threshold; labeled "MODERATE" moat in doc |
| Compounding flywheel (more tours → better CF → better matches) | 01-ml-engine.md | **Theoretically Supported** | "Described mechanism; not validated with data"                      | Flywheel logic is sound; actual compounding effect unmeasured            |
| Weekly batch retraining pipeline                               | 01-ml-engine.md | **Not Implemented**         | "Retraining pipeline described in architecture; not implemented"    | No cron/background job for model retraining                              |
| Feature drift detection (KS statistic)                         | 01-ml-engine.md | **Not Implemented**         | "Drift detection code snippet in doc; not in codebase"              | `detect_feature_drift()` function described in doc only                  |

---

## 8. Summary: Claims Requiring Safe Wording Corrections

| Claim (as stated)                            | Correct Status        | Safe Wording to Use                                                                  |
| -------------------------------------------- | --------------------- | ------------------------------------------------------------------------------------ |
| "ALS for collaborative filtering"            | TruncatedSVD          | "TruncatedSVD matrix factorization"                                                  |
| "40/40/20 hybrid weighting"                  | 45/45/10 hardcoded    | "45% content-based / 45% collaborative / 10% destination affinity"                   |
| "64-dimensional interest vectors"            | 5-dimensional         | "5-feature preference vectors (food, culture, adventure, pace, budget)"              |
| "CP-SAT + simulated annealing for itinerary" | Greedy + 2-opt        | "Greedy construction + 2-opt local search (CP-SAT described for production upgrade)" |
| "XGBoost satisfaction prediction"            | Prototype, not wired  | "XGBoost prototype model; not yet exposed as recommendation signal"                  |
| "AI-Guided Matches" (UI label)               | Content+Collab hybrid | "Personalized ML Matches" or "Compatibility-Scored Matches"                          |
| "10,000-tour data moat"                      | Unsupported estimate  | "Data flywheel improves with scale; 10K tours is an aspirational milestone"          |
| "85%+ directional accuracy target"           | Planned, not measured | "Directional accuracy target stated in architecture; requires real data validation"  |
| "Energy curve modeling"                      | Not implemented       | "Described in architecture; not in current implementation"                           |
| "Weather-aware routing"                      | Not implemented       | "Production roadmap item; not in current implementation"                             |

---

## 9. Implementation File Cross-Reference

| File                                | ML Capability                         | Status                                       |
| ----------------------------------- | ------------------------------------- | -------------------------------------------- |
| `backend/matching.py`               | Compatibility scoring                 | Implemented                                  |
| `backend/ml/recommender.py`         | Hybrid recommender (content + collab) | Implemented                                  |
| `backend/ml/group_formation.py`     | K-Means + DBSCAN group formation      | Implemented                                  |
| `backend/ml/itinerary.py`           | Greedy + 2-opt itinerary              | Implemented                                  |
| `backend/ml/review_intelligence.py` | XGBoost satisfaction model            | Partially Implemented (prototype, not wired) |
| `backend/ml/safety_score.py`        | Safety scoring                        | Implemented                                  |
| `backend/ml/pricing.py`             | Dynamic pricing                       | Implemented                                  |
| `backend/ml/__init__.py`            | Module init                           | Implemented                                  |

**Missing from implementation:**

- `backend/ml/satisfaction_model.py` — referenced in architecture, does not exist
- `backend/ml/itinerary_optimizer.py` (CP-SAT) — referenced in architecture, does not exist
- `backend/ml/cold_start.py` — referenced in architecture, does not exist

---

## 10. ML Component Deep-Dive

### Primary Live ML Components

| ML Component            | Input Features                                                                                                              | Algorithm                                                                                   | Output                                              | Decision Supported                                | Limitation                                                  |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------- | ----------------------------------------------------------- |
| **Hybrid recommender**  | Tourist 5-dim preference vector (food, culture, adventure, pace, budget); Guide expertise tags; Tourist-guide rating matrix | 45% cosine similarity + 45% TruncatedSVD collaborative filtering + 10% destination affinity | Ranked guide list with score breakdown              | "Which guide should I choose?"                    | Fixed weights; collaborative filtering needs rating history |
| **Group formation**     | Tourist feature vectors (preferences, pace, budget, language, group-size preference)                                        | K-Means clustering + DBSCAN outlier detection                                               | Group clusters (3–8 tourists); solo candidate flags | "Which travelers are compatible for group tours?" | Equal feature weights; no interest-weighted clustering      |
| **Itinerary optimizer** | POI list, time windows, budget, meal constraints, travel distances                                                          | Greedy construction + 2-opt local search                                                    | Ordered stop sequence with times and total duration | "What order should I visit these places?"         | Greedy can miss global optimum; CP-SAT is future upgrade    |
| **Safety score**        | Guide license tier, completion rate, rating, incident flags                                                                 | Rule-based weighted sum                                                                     | Numeric score (0–100) + risk flag list              | "Can I trust this guide?"                         | Rule-based; not ML model; advisory only                     |

### Prototype / Future Components

| ML Component                | Input Features                                                         | Algorithm                                        | Output                      | Decision Supported                          | Limitation                                      |
| --------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------ | --------------------------- | ------------------------------------------- | ----------------------------------------------- |
| **Satisfaction prediction** | Tourist profile, guide profile, interest alignment, pace compatibility | XGBoost regression                               | Predicted tour rating (1–5) | "Will this match be satisfying?" (future)   | Prototype only; not wired to recommendation API |
| **CP-SAT solver**           | POI list, constraints, distances                                       | OR-Tools CP-SAT                                  | Optimal stop sequence       | "What is the mathematically optimal route?" | Not implemented; greedy + 2-opt is current      |
| **Weather-aware routing**   | POI list, weather forecast, travel times                               | Constraint optimization with weather constraints | Weather-adapted route       | "How does weather affect my itinerary?"     | Not implemented; production roadmap item        |

---

## 11. Safe Wording Quick Reference

| Claim                   | Unsafe Wording                         | Safe Wording                                                                |
| ----------------------- | -------------------------------------- | --------------------------------------------------------------------------- |
| Collaborative filtering | "ALS"                                  | "TruncatedSVD matrix factorization"                                         |
| Hybrid weights          | "40/40/20"                             | "45% content / 45% collaborative / 10% destination affinity"                |
| Interest vectors        | "64-dimensional"                       | "5-dimensional (food, culture, adventure, pace, budget)"                    |
| Itinerary optimizer     | "CP-SAT + simulated annealing"         | "Greedy construction + 2-opt local search (CP-SAT is production upgrade)"   |
| Satisfaction model      | "XGBoost prediction wired to live API" | "XGBoost prototype model; not yet exposed as recommendation signal"         |
| UI label                | "AI-Guided Matches"                    | "Compatibility-Scored Matches"                                              |
| Data moat               | "10,000-tour data moat"                | "Data flywheel improves with scale; 10K tours is an aspirational milestone" |
| Accuracy                | "85%+ directional accuracy"            | "Target validation metric; not yet measured in production"                  |
