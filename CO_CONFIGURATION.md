# CO Configuration — WanderLess

**MGMT655 Machine Learning for Decision Making**
**Team: WanderLess | Luang Prabang, Laos | May 2026**

---

## 1. Project Identity

| Field            | Value                                                          |
| ---------------- | -------------------------------------------------------------- |
| Project name     | WanderLess                                                     |
| Product type     | Compatibility-intelligence marketplace for local guided travel |
| Beachhead market | Luang Prabang, Laos                                            |
| Demo context     | MGMT655 course submission                                      |
| Team size        | [Team size — fill in]                                          |
| Model name       | WanderLess Recommender (custom)                                |

---

## 2. ML Decision Framework

### 2.1 Decisions Made

| Decision                | Choice                                                           | Rationale                                                                                        |
| ----------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Matching architecture   | Hybrid recommender (content + collaborative + destination boost) | Cold-start resistant; blends preference matching with rating patterns                            |
| Collaborative filtering | TruncatedSVD matrix factorization                                | Scales to sparse tourist-guide matrix; captures latent compatibility signals                     |
| Group formation         | K-Means + DBSCAN                                                 | K-Means for coherent clusters; DBSCAN isolates solo-preferred outliers                           |
| Itinerary optimization  | Greedy + 2-opt local search                                      | CP-SAT described as production upgrade; greedy+2opt provides good-enough solutions for prototype |
| Satisfaction prediction | XGBoost regression                                               | Described in architecture; prototype not wired to API — labeled as future work                   |
| Synthetic data          | 88% genuine signal + 12% noise                                   | Bootstrap collaborative filtering before real ratings accumulate                                 |
| Safety scoring          | Rule-based indicator                                             | Decision-support only; not an ML safety guarantee                                                |

### 2.2 Decisions Rejected

| Rejected option                  | Reason rejected                                               | Alternative adopted                   |
| -------------------------------- | ------------------------------------------------------------- | ------------------------------------- |
| LLM/RAG for itinerary generation | Out of scope for course ML focus; no real user data for RAG   | Greedy + 2-opt heuristic construction |
| CP-SAT constraint solver         | Requires commercial license; overkill for prototype itinerary | Greedy + 2-opt local search           |
| Pure popularity-based matching   | Does not solve compatibility gap                              | Hybrid recommender                    |
| Rule-based matching              | Does not scale; no personalization                            | Content + collaborative hybrid        |

### 2.3 Open Questions

| Question                                      | Status                                    | Impact |
| --------------------------------------------- | ----------------------------------------- | ------ |
| Satisfaction prediction accuracy on real data | Unknown — requires pilot                  | High   |
| Optimal recommender weight tuning             | Fixed at 45/45/10; A/B test needed        | Medium |
| Guide density threshold for matching quality  | Unvalidated; 50 guides assumed sufficient | High   |

---

## 3. Evidence Standards

### 3.1 Claim Verification Protocol

Every claim in documentation must be traceable to:

1. **Implemented code** (for ML capabilities)
2. **Synthetic data validation** (for ML performance metrics)
3. **External benchmark citation** (for market size, competitor claims)

### 3.2 Required Disclosures

| Claim type                  | Disclosure required                                                          |
| --------------------------- | ---------------------------------------------------------------------------- |
| ML performance metrics      | "Based on synthetic data; real-data validation pending"                      |
| Business metrics (LTV, CAC) | "Prototype estimate; requires pilot validation"                              |
| Market size                 | "TAM/SAM/SOM are team estimates, not independently validated"                |
| Satisfaction prediction     | "Prototype model; not wired to production recommendation signal"             |
| Safety score                | "Decision-support indicator; not a safety guarantee"                         |
| Synthetic ratings           | "Trained on 600 synthetic tuples; 88% genuine signal + 12% calibrated noise" |

---

## 4. Demo Configuration

### 4.1 Approved Demo Paths

| Path             | Description                                                                                         | Fallback                             |
| ---------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------ |
| Flutter app      | Full UI with preference onboarding → guide matching → group view → itinerary                        | `DEMO_API_COMMANDS.md` cURL commands |
| Backend API only | Direct API calls to `/api/recommendations`, `/api/matches`, `/api/pricing/quote`, `/api/trip-plans` | `DEMO_API_COMMANDS.md`               |
| Demo screenshots | Pre-captured screens in `docs/demo_screenshots/`                                                    | Narrative walkthrough                |

### 4.2 Demo Constraints

- No simulated booking as proof of revenue
- No fabricated user testimonials
- No live payment processing
- Safety score displayed as "decision support — human judgment required"

---

## 5. Compliance Mapping

| Grading rubric area | Coverage                                                                            | Evidence                                                  |
| ------------------- | ----------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Market & Problem    | Problem well-defined; Luang Prabang beachhead justified                             | `MARKET_PROBLEM.md`, `SUBMISSION_EXECUTIVE_SUMMARY_4P.md` |
| Product & Demo      | Working backend API; Flutter app demo                                               | `backend/`, `app/`, `DEMO_SCRIPT.md`                      |
| Business Model      | Commission model; unit economics disclosed                                          | `BUSINESS_MODEL.md`, `CO_CONFIGURATION.md`                |
| Team & Execution    | Decisions logged; alternatives documented                                           | `docs/COC_DECISION_LOG_A_PLUS.md`                         |
| AI/ML Depth         | Hybrid recommender, clustering, optimization implemented; XGBoost labeled prototype | `MODEL_CARD.md`, `AI_ML_ARCHITECTURE.md`, `backend/ml/`   |

---

_Created per MGMT655 course requirements. WanderLess is a team project prototype — not a commercial product._
