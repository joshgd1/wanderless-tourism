# Satisfaction Predictor Specification

## Overview

The Satisfaction Predictor uses XGBoost regression to predict expected tour ratings before tours occur. Trained on post-tour ratings, it learns which tourist-guide-feature interactions produce high satisfaction.

**Prototype status**: The XGBoost model exists in `backend/ml/review_intelligence.py` and is used for guide profile analysis at startup. It is **not wired to the recommendation API endpoint** and does not currently influence guide matching or ranking.

## Production Validation Requirements

Before this model can be used as a live recommendation signal, the following real data must be collected:

- **Real booking data**: Completed tours with tourist-guide pairs
- **Post-tour ratings**: 1–5 scale ratings submitted by tourists after tours
- **Cancellation records**: Cancellations and reasons (affects base rate)
- **Complaint history**: Escalations, safety incidents, guide disputes
- **Repeat bookings**: Whether tourists re-booked the same guide

**Minimum for meaningful model**: 500 completed tours with ratings
**Target for 85% directional accuracy**: 10,000 completed tours (architecture-stage estimate, not validated)

## Prototype Implementation Status

### Implemented

| Component                   | Status          | Notes                                                                          |
| --------------------------- | --------------- | ------------------------------------------------------------------------------ |
| XGBoost regression model    | **Prototype**   | Exists in `backend/ml/review_intelligence.py`; used for guide profile analysis |
| Guide profile clustering    | **Prototype**   | TfidfVectorizer + KMeans on guide text data                                    |
| Traveler-type pattern rules | **Prototype**   | Rule-based solo/couple/family/group detection                                  |
| Cold-start with global mean | **Implemented** | Global mean fallback when no rating history exists                             |

### Not Wired to Recommendation API

The satisfaction prediction model is **not called by any production API endpoint**. It exists as a standalone prototype that runs at backend startup for guide analysis. Connecting it to the recommendation engine requires:

1. Validating model accuracy against real post-tour ratings
2. Exposing a `/satisfaction/predict` endpoint
3. Integrating the score into the match-ranking pipeline

### Not Implemented

| Component                                | Status              | Notes                                                                                   |
| ---------------------------------------- | ------------------- | --------------------------------------------------------------------------------------- |
| SHAP explanations                        | **Not Implemented** | Described in spec but not in code                                                       |
| Feature interaction terms                | **Not Implemented** | The prototype uses raw features; interaction terms described in this spec are not wired |
| Bootstrap confidence intervals           | **Not Implemented** | Confidence levels are not currently calculated                                          |
| Real-time prediction endpoint            | **Not Implemented** | No API endpoint currently serves satisfaction predictions                               |
| Feedback loop (post-rating model update) | **Not Implemented** | No incremental retraining pipeline exists                                               |
| Prediction drift detection               | **Not Implemented** | No monitoring for model accuracy degradation                                            |

## Model Architecture (Prototype)

### XGBoost Configuration

```python
satisfaction_predictor = {
    model_type: "xgboost.XGBRegressor",
    objective: "reg:squarederror",  # MSE for rating prediction
    n_estimators: 500,
    max_depth: 6,
    learning_rate: 0.05,
    subsample: 0.8,
    colsample_bytree: 0.8,
    min_child_weight: 3,
}
```

**Note**: Configuration is prototype-stage. Production requires hyperparameter tuning on real data.

### Feature Interaction Terms (Planned — Not Implemented)

The following interaction terms are described in the architecture specification but are **not currently implemented** in the prototype. The prototype uses raw features only.

```python
# Planned interaction features:
# - Tourist-Guide interest alignment scores
# - Pace compatibility scores
# - Budget overlap calculations
# - Language match scores
# These require feature engineering pipelines not yet in production
```

## Training Data

### Label: Post-Tour Rating (1-5)

```python
training_record = {
    # Input features (100+ dimensions)
    features: {...},

    # Label
    rating: float[1-5],  # Tourist's post-tour rating

    # Metadata
    tourist_id: string,
    guide_id: string,
    booking_id: string,
    tour_date: date,
    city: string,
    created_at: timestamp,
}
```

### Training Schedule (Planned)

```python
TRAINING_CONFIG = {
    # Full retrain: Weekly (planned)
    full_retrain_schedule: "Sunday 3AM UTC",

    # Incremental: Daily (planned)
    incremental_schedule: "Daily 2AM UTC",

    # Minimum training data before first model: 500 records
    min_training_records: 500,

    # Target accuracy milestone: 10,000 records for 85% accuracy
    # NOTE: This is an architecture-stage estimate; not validated with real data
    accuracy_target_records: 10000,
}
```

### Feature Importance Tracking (Planned)

```python
# Planned: XGBoost feature importance tracking
# Requires real model training on post-tour ratings
TOP_PREDICTORS = [
    # To be determined from real data analysis
]
```

## Prediction Output

### Standard Prediction

```json
{
  "predicted_rating": 4.6,
  "confidence": {
    "lower": 4.2,
    "upper": 5.0,
    "confidence_level": "HIGH"
  },
  "key_factors": [
    {
      "factor": "Strong food interest alignment",
      "direction": "positive",
      "magnitude": "+0.3"
    },
    {
      "factor": "Guide has 200+ 5-star tours",
      "direction": "positive",
      "magnitude": "+0.2"
    },
    {
      "factor": "Perfect pace match",
      "direction": "positive",
      "magnitude": "+0.2"
    },
    {
      "factor": "First time with this guide",
      "direction": "neutral",
      "magnitude": "0.0"
    }
  ],
  "risk_flags": [
    {
      "flag": "Budget tourist + Premium guide",
      "severity": "low",
      "mitigation": "Ensure pricing transparency before booking"
    }
  ]
}
```

### Confidence Levels (Planned)

```python
# Planned confidence calculation — not implemented in prototype
# Would require bootstrap sampling or model uncertainty estimation
def calculate_confidence(prediction, model, features):
    # To be implemented with real model
    pass
```

## Integration with Matching (Planned — Not Wired)

The following integrations are **described in this specification but not currently wired** to the recommendation API.

### Planned Pre-Matching Filter

```python
# Planned integration — not currently implemented
def filter_by_satisfaction_prediction(matches, min_predicted_rating=3.5):
    """
    Remove matches predicted to have low satisfaction.
    Requires: /satisfaction/predict endpoint wired to matching pipeline.
    """
    pass
```

### Planned Match Ranking Enhancement

```python
# Planned integration — not currently implemented
def rank_matches(matches):
    """
    Combine compatibility score with satisfaction prediction.
    Requires: satisfaction model validated on real ratings.
    """
    pass
```

## Feedback Loop (Planned)

### Post-Rating Model Update (Planned)

```python
# Planned: connect post-tour ratings back to model retraining
def on_tourist_rating_received(booking):
    """
    When a tourist submits a rating, this feeds back into the model.
    Not implemented — requires: real ratings + retraining pipeline.
    """
    pass
```

### Prediction Drift Detection (Planned)

```python
# Planned — not implemented
def detect_prediction_drift():
    """
    Monitor if predictions are becoming less accurate.
    Not implemented — requires: production model + monitoring infrastructure.
    """
    pass
```

## Model Interpretability (Not Implemented)

### SHAP Explanations

**SHAP-based explanations are not implemented** in the current prototype. The model exists as a prototype; without a wired prediction endpoint, there is no user-facing explanation to generate.

```python
# Planned — not implemented
def explain_prediction(prediction, features):
    """
    Return human-readable explanation of prediction using SHAP values.
    Requires: production model + explainer library integration.
    """
    raise NotImplementedError("SHAP explanations not yet implemented")
```

## Performance Targets (Architecture Estimates — Not Validated)

| Metric                       | Target                      | Status                                                   |
| ---------------------------- | --------------------------- | -------------------------------------------------------- |
| Prediction accuracy          | > 85% directionally correct | **Architecture estimate; requires real-data validation** |
| MAE                          | < 0.5                       | **Architecture estimate; not measured**                  |
| RMSE                         | < 0.7                       | **Architecture estimate; not measured**                  |
| Prediction latency           | < 50ms                      | **Planned target**                                       |
| Feature importance stability | < 20% variance              | **Planned; requires production model**                   |

## Data Requirements

```
Minimum for meaningful model: 500 completed tours with post-tour ratings
Target for 85% accuracy: 10,000 completed tours (architecture-stage estimate, not validated)

These thresholds require real-data validation before production use.
The prototype was trained on synthetic data and has not been validated against real user ratings.
```
