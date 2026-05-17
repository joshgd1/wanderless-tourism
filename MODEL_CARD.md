# Model Card — Wanderless Laos

## Decision Problem

Recommend compatible local guides and/or groups for a traveler based on structured preference and profile features.

## Input Features

**Tourist-side:**

- Language preference
- Budget range
- Travel pace
- Interests (food, culture, adventure, heritage, nature)
- Safety comfort level
- Group preference
- Itinerary duration
- Mobility/accessibility needs (if available)

**Guide-side:**

- Languages
- Guide style
- Activity expertise
- Price band
- Availability
- Safety/trust score
- Past rating or simulated rating
- Itinerary specialization

## ML / Algorithmic Methods Used

### 1. Compatibility Scoring

- **Method:** Cosine similarity + weighted similarity over normalized features
- **Purpose:** Rank guide-tourist fit
- **Implementation:** `backend/ml/recommender.py` — `ContentBasedRecommender`

### 2. Dimensionality Reduction

- **Method:** TruncatedSVD (scipy `svds`)
- **Purpose:** Compress tourist×guide rating matrix for collaborative signal
- **Implementation:** `backend/ml/recommender.py` — `CollaborativeRecommender`

### 3. Clustering

- **Method:** K-Means (sklearn) + DBSCAN (sklearn)
- **Purpose:** Identify compatible traveler groups or preference segments
- **Implementation:** `backend/ml/group_formation.py` — `form_groups()`

### 4. Route / Itinerary Logic

- **Method:** Greedy construction + 2-opt local search heuristic
- **Purpose:** Improve itinerary sequencing without requiring exact optimization
- **Implementation:** `backend/ml/itinerary.py`

### 5. Safety Scoring

- **Method:** Rule-based weighted risk indicator
- **Purpose:** Surface decision-support signal, not automate safety judgment
- **Implementation:** `backend/ml/safety_score.py`

## Why These Methods Fit the Business Problem

- Matching is a ranking and compatibility problem, not only a prediction problem
- Clustering helps segment traveler styles for group formation
- Heuristics are appropriate for prototype itinerary optimization — exact optimization would be premature before real demand data
- Explainability matters more than black-box sophistication at pilot stage

## Evaluation

| Metric                    | Value          | Notes                                      |
| ------------------------- | -------------- | ------------------------------------------ |
| Test pass rate            | 14/14 (100%)   | `pytest tests/`                            |
| Synthetic matching sanity | Pass           | Demo scenarios validate ranking logic      |
| Algorithm coverage        | All demo flows | Guide match, group form, itinerary, safety |
| Latency                   | Not measured   | Prototype performance not yet profiled     |

_No AUC, F1, RMSE, or uplift calculated — no real outcome labels exist yet._

## Limitations

- All data is synthetic (400 tourists, 60 guides, 600 ratings)
- Feature weights are fixed, not learned from real outcomes
- No live marketplace integration
- No real transaction data
- No field validation yet
- Safety score is decision support, not a guarantee

## Next Model Improvements

- Learn weights from booking/conversion outcomes
- Collect real post-tour satisfaction labels
- Run A/B test on guide conversion
- Add fairness checks so new guides are not permanently disadvantaged
- Add human override for safety-sensitive recommendations
