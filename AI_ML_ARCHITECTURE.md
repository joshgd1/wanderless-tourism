# AI/ML Architecture

## Pipeline Overview

1. Data ingestion (synthetic tourist/guide profiles + ratings)
2. Feature normalization (5-dimension interest vectors)
3. Tourist-guide compatibility scoring (cosine similarity + TruncatedSVD)
4. Traveler/guide segmentation (K-Means + DBSCAN)
5. Itinerary recommendation logic (greedy + 2-opt)
6. Safety/trust decision-support layer (rule-based)
7. API response to UI
8. User explanation layer (why this match)

## Why ML Is Required

This is not a static rules app. The product must rank many possible tourist-guide-group-itinerary combinations across multiple weighted attributes. Manual rules cannot efficiently explore the combinatorial space of compatibility signals.

## Model Family

| Component              | Method                                                     | File                            |
| ---------------------- | ---------------------------------------------------------- | ------------------------------- |
| Guide matching         | Cosine similarity (content) + TruncatedSVD (collaborative) | `backend/ml/recommender.py`     |
| Group formation        | K-Means + DBSCAN clustering                                | `backend/ml/group_formation.py` |
| Itinerary optimization | Greedy + 2-opt heuristic                                   | `backend/ml/itinerary.py`       |
| Safety scoring         | Rule-based weighted sum                                    | `backend/ml/safety_score.py`    |
| Pricing                | Rule-based dynamic pricing                                 | `backend/ml/pricing.py`         |

## Explainability

For every recommendation, the UI/API exposes:

- Top matching factors (interest alignment, language match, price fit)
- Trade-offs (why a higher-price guide ranked below a lower-price option)
- Safety caveat if relevant
- Group compatibility rationale

## Model Governance

- No sensitive personal attributes used beyond travel preferences
- Safety score is decision support only — human judgment required
- Human override available for all safety-sensitive recommendations
- Synthetic data limitation disclosed to users
- Pilot data consent required before production use
- Bias risk monitored for new guides (recency disadvantage)
- Monitoring plan: match-to-booking conversion, cancellation rate, satisfaction score
