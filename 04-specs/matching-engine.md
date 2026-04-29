# Matching Engine Specification

## Overview

The Matching Engine is WanderLess's core ML capability. It predicts tourist-guide compatibility using a hybrid recommendation approach combining content-based, collaborative, and contextual signals.

## Architecture

### Hybrid Recommendation Model

```
compatibility_score(tourist, guide) =
    0.40 * content_score(tourist, guide) +
    0.40 * collaborative_score(tourist, guide) +
    0.20 * contextual_score(tourist, guide, context)
```

## 1. Content-Based Score (40%)

### Tourist Interest Vector

```
tourist_vector = embed(primary_interests + demographics + preferences)
# Output: normalized float[64]
```

### Guide Expertise Vector

```
guide_vector = embed(expertise + personality + languages + availability)
# Output: normalized float[64]
```

### Cosine Similarity

```
content_score = cosine_similarity(tourist_vector, guide_vector)
# Range: [-1, 1] normalized to [0, 1]
```

### Content Features

| Feature           | Tourist Side                           | Guide Side                                |
| ----------------- | -------------------------------------- | ----------------------------------------- |
| Primary interests | food, culture, adventure, pace, budget | food, culture, adventure expertise levels |
| Languages         | spoken languages                       | spoken languages                          |
| Age demographic   | age_group                              | guide_age_bracket (for compatibility)     |
| Travel style      | solo/couple/friends/family/group       | guide_prefers_tourist_type                |
| Pace preference   | pace slider                            | guide_avg_tour_pace                       |
| Budget alignment  | budget slider                          | guide_avg_tour_price                      |

## 2. Collaborative Score (40%)

### Matrix Factorization

```
# Training data: tourist-guide-rating tuples
# After 10K+ tours, model learns latent factors

rating_matrix: sparse_matrix[tourists × guides]
# Factorization: rating_matrix ≈ U × V^T

# U: tourist latent factors [tourist_id × k_factors]
# V: guide latent factors [guide_id × k_factors]

collaborative_score = sigmoid(U[tourist_id] · V[guide_id]^T)
# Range: [0, 1]
```

### Cold Start Handling

```
if tourist.guide_ratings_count < 5:
    # Insufficient direct ratings
    collaborative_score = global_average

    # Find similar tourists (content-based)
    similar_tourists = find_k_nearest(tourist_vector, k=10)

    # Use their ratings of this guide
    collaborative_score = mean([
        rating[guide_id]
        for rating in similar_tourists.guide_ratings
        if guide_id in rating
    ])
```

## 3. Contextual Score (20%)

### Context Factors

```
context_features = {
    time_of_day: float,           # Hour of tour start (0-24)
    day_of_week: float,           # Monday=0, Sunday=1
    weather_forecast: enum,        # clear, cloudy, rain, storm
    seasonal_factor: float,        # Peak=1.2, Off=0.8
    group_size: int,              # Solo=1, Group=3-8
    days_since_last_booking: int, # Engagement recency
    city_demand: float,            # Guide booking demand
}
```

### Context Adjustment

```
context_score = model.predict(context_features × interaction_terms)
# Interaction terms capture context × guide specialty effects

# Example: Adventure guide on rainy day gets context_score < 0.5
# Example: Food guide at lunch time gets context_score > 0.7
```

## Confidence Interval

### Calculation

```
# Bootstrap sampling for confidence
n_bootstrap = 100
bootstrap_scores = []

for _ in range(n_bootstrap):
    # Resample training data
    sample = resample(training_data)
    model_sample = train(sample)
    score_sample = model_sample.predict(tourist, guide)
    bootstrap_scores.append(score_sample)

confidence_lower = percentile(bootstrap_scores, 2.5)
confidence_upper = percentile(bootstrap_scores, 97.5)
confidence_width = confidence_upper - confidence_lower
```

### Confidence Levels

```
confidence_width < 0.1:  "HIGH"   # Green indicator
confidence_width < 0.2:  "MEDIUM" # Yellow indicator
confidence_width >= 0.2: "LOW"    # Red indicator
```

## Matching Output

### Top Matches Response

```json
{
  "matches": [
    {
      "guide_id": "guide_123",
      "compatibility_score": 87.3,
      "confidence": {
        "level": "HIGH",
        "lower": 82.1,
        "upper": 91.4
      },
      "key_factors": [
        { "factor": "food_interest_match", "contribution": "+15.2" },
        { "factor": "pace_compatibility", "contribution": "+8.7" },
        { "factor": "language_match", "contribution": "+5.0" },
        { "factor": "adventure_overlap", "contribution": "+3.1" }
      ],
      "predicted_satisfaction": 4.6,
      "explanation": "You're 92% compatible with Khan. Strong food interest alignment and matched travel pace."
    }
    // ... top 5 guides
  ]
}
```

## Failure Modes

### Empty Result Set

```
if eligible_guides == []:
    return {
        "matches": [],
        "message": "No guides match your criteria in this destination",
        "suggestions": [
            "Try adjusting your interest sliders",
            "Expand language preferences",
            "Check back soon - new guides join weekly"
        ]
    }
```

### Low Confidence Matches

```
if all(matches.confidence == "LOW"):
    # Show warning but still present matches
    return {
        "warning": "Limited data for your profile. Matches may be less accurate.",
        "matches": matches,
        "cta": "Complete more tours to improve matching"
    }
```

### Guide Unavailable

```
if guide.availability[requested_time] is False:
    # Exclude from matching, suggest alternative times
    alternative_times = find_available_slots(guide, date_range)
    return {
        "matches": [match for match in matches if match.guide_id != unavailable_guide],
        "alternatives": {
            "guide_id": unavailable_guide,
            "available_times": alternative_times
        }
    }
```

## Performance Requirements

| Metric              | Target  | Measurement                            |
| ------------------- | ------- | -------------------------------------- |
| Match latency (p95) | < 200ms | Time from request to top-5 response    |
| Match latency (p99) | < 500ms | 99th percentile                        |
| Coverage            | > 95%   | % of eligible tourists getting matches |
| Ranking quality     | > 0.7   | NDCG@5 on holdout test set             |

## Training Schedule

```
Training Frequency:
- Full retrain: Weekly (Sunday 3AM UTC)
- Incremental update: Daily (2AM UTC)
- Context model update: Monthly

Data Requirements:
- Minimum 100 completed tours before first collaborative model
- Recommend 1,000+ tours for stable collaborative filtering
- Target: 10,000 tours for 85%+ directional accuracy
```
