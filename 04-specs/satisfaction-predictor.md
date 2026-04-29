# Satisfaction Predictor Specification

## Overview

The Satisfaction Predictor uses XGBoost regression to predict expected tour ratings before tours occur. Trained on post-tour ratings, it learns which tourist-guide-feature interactions produce high satisfaction.

## Model Architecture

### Primary Model: XGBoost Regression

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

### Feature Interaction Terms

```python
# Key insight: satisfaction comes from COMBINATIONS, not individual features
# Example: "adventure tourist + adventure guide + good weather" = high satisfaction
# But each alone doesn't predict satisfaction

interaction_features = {
    # Tourist-Guide Interest Alignment
    "food_align": tourist.food * guide.food_expertise,
    "culture_align": tourist.culture * guide.culture_expertise,
    "adventure_align": tourist.adventure * guide.adventure_expertise,

    # Pace Compatibility
    "pace_diff": |tourist.pace - guide.avg_tour_pace|,  # Smaller = better
    "pace_score": 1 - pace_diff,  # Normalized

    # Budget Alignment
    "budget_match": calculate_budget_overlap(tourist.budget, guide.price_tier),

    # Language Match
    "language_score": len(set(tourist.languages) & set(guide.languages)) /
                      len(set(tourist.languages) | set(guide.languages)),

    # Group Size Compatibility
    "group_size_fit": 1 - |tourist.group_size - guide.preferred_group_size| / 8,

    # Guide Quality Signals
    "guide_avg_rating": guide.average_rating,
    "guide_response_rate": guide.response_rate,
    "guide_tour_count": log(guide.total_tours_completed + 1),

    # Contextual
    "weather_score": weather.suitability_for(guide.expertise),
    "time_of_day_score": calculate_time_fit(tourist.preferred_time, tour.start_hour),
    "seasonal_factor": calculate_seasonal(tour.date),

    # Tourist-MGuide History
    "repeat_guide_bonus": 0.3 if tourist.has_rated_guide(guide) else 0,
    "repeat_guide_rating": tourist.rating_for_guide(guide) if repeat_guide_bonus else None,

    # Novelty
    "new_guide_bonus": 0.1 if guide.total_tours_completed < 10 else 0,
    "explored_interest": 0.2 if guide.expertise_area not in tourist.viewed_categories else 0,
}
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

### Training Schedule

```python
TRAINING_CONFIG = {
    # Full retrain: Weekly
    full_retrain_schedule: "Sunday 3AM UTC",

    # Incremental: Daily (for recent patterns)
    incremental_schedule: "Daily 2AM UTC",

    # Minimum training data before first model: 500 records
    min_training_records: 500,

    # Target accuracy milestone: 10,000 records for 85% accuracy
    accuracy_target_records: 10000,
}
```

### Feature Importance Tracking

```python
# XGBoost provides feature importance scores
# Track top predictors over time

TOP_PREDICTORS = [
    "guide_avg_rating",
    "food_align",
    "pace_score",
    "language_score",
    "adventure_align",
    "budget_match",
    "guide_tour_count",
    "group_size_fit",
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

### Confidence Levels

```python
def calculate_confidence(prediction, model, features):
    # Confidence based on:
    # 1. Feature coverage (are these features well-represented in training?)
    # 2. Distance from training distribution
    # 3. Number of similar past predictions

    feature_coverage = model.feature_coverage_score(features)
    distribution_distance = model.distance_from_training_mean(features)
    similar_predictions = model.count_similar_predictions(features)

    # Combine into confidence
    if feature_coverage > 0.9 and distribution_distance < 0.1:
        return "HIGH"
    elif feature_coverage > 0.7:
        return "MEDIUM"
    else:
        return "LOW"
```

## Integration with Matching

### Pre-Matching Filter

```python
def filter_by_satisfaction_prediction(matches, min_predicted_rating=3.5):
    """
    Remove matches predicted to have low satisfaction
    """
    filtered = []
    for match in matches:
        prediction = satisfaction_predictor.predict(match.tourist, match.guide)
        if prediction >= min_predicted_rating:
            match.predicted_satisfaction = prediction
            filtered.append(match)

    return filtered
```

### Match Ranking Enhancement

```python
def rank_matches(matches):
    """
    Combine compatibility score with satisfaction prediction
    """
    for match in matches:
        # Predicted satisfaction is 1-5, normalize to 0-1
        sat_normalized = (match.predicted_rating - 1) / 4

        # Weighted combination
        match.final_score = (
            0.5 * match.compatibility_score +
            0.5 * sat_normalized
        )

    return sorted(matches, key=lambda m: m.final_score, reverse=True)
```

## Feedback Loop

### Post-Rating Model Update

```python
def on_tourist_rating_received(booking):
    """
    When a tourist submits a rating, this feeds back into the model
    """
    # Record the actual outcome
    training_record = {
        "features": extract_features_at_prediction_time(booking),
        "rating": booking.tourist_rating,
        "tourist_id": booking.tourist_id,
        "guide_id": booking.guide_id,
        "booking_id": booking.id,
    }

    # Add to training buffer
    training_buffer.add(training_record)

    # Incremental update daily
    if training_buffer.size >= 100:
        schedule_incremental_retrain()

    # Update guide's running average
    guide.update_average_rating(booking.tourist_rating)

    # Check for prediction accuracy
    prediction_error = abs(
        booking.predicted_rating - booking.tourist_rating
    )
    log_prediction_error(prediction_error)
```

### Prediction Drift Detection

```python
def detect_prediction_drift():
    """
    Monitor if predictions are becoming less accurate
    """
    recent_predictions = PredictionLog.last_30_days()
    recent_actuals = RatingLog.last_30_days()

    # Calculate prediction error trend
    errors = [
        abs(p.expected - a.actual)
        for p, a in zip(recent_predictions, recent_actuals)
    ]

    avg_error = mean(errors)
    error_trend = calculate_trend(errors)

    if error_trend > 0.1:  # 10% increase in error
        alert_team("Prediction drift detected")
        schedule_full_model_retrain()
```

## Model Interpretability

### Key Factor Extraction

```python
def explain_prediction(prediction, features):
    """
    Return human-readable explanation of prediction
    """
    # Use SHAP values for interpretability
    shap_values = explainer.shap_values(features)

    # Get top contributing factors
    factor_importance = list(zip(
        feature_names,
        shap_values
    ))

    # Sort by absolute contribution
    sorted_factors = sorted(
        factor_importance,
        key=lambda x: abs(x[1]),
        reverse=True
    )

    return [
        {
            "factor": name,
            "contribution": value,
            "description": factor_descriptions[name]
        }
        for name, value in sorted_factors[:5]
    ]
```

## Performance Targets

| Metric                       | Target                      | Measurement                     |
| ---------------------------- | --------------------------- | ------------------------------- |
| Prediction accuracy          | > 85% directionally correct | Actual > Predicted - 0.5 within |
| MAE                          | < 0.5                       | Mean absolute error             |
| RMSE                         | < 0.7                       | Root mean squared error         |
| Prediction latency           | < 50ms                      | Per prediction                  |
| Feature importance stability | < 20% variance              | Week-over-week                  |

## Data Requirements

```
Minimum for meaningful model: 500 tours
Target for 85% accuracy: 10,000 tours
Maximum training window: 2 years (to avoid stale patterns)

At 10,000 tours:
- ~7,000 positive signals (4-5 stars)
- ~2,000 neutral (3 stars)
- ~1,000 negative (1-2 stars)
- 50+ guides with 50+ tours each
- 1,000+ unique tourists
- 3+ cities
```
