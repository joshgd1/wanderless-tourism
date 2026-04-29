# Group Formation Engine Specification

## Overview

The Group Formation Engine uses unsupervised learning to cluster tourists with similar interests, enabling group tour experiences while maintaining compatibility standards.

## Algorithm Selection

### Primary: K-Means Clustering

```
cluster_tourists(tourists, k) =
    # Standard K-Means on interest vectors

    1. Initialize k centroids (K-Means++ for better init)
    2. Iterate until convergence:
       a. Assign each tourist to nearest centroid
       b. Recompute centroid positions
    3. Return cluster assignments + silhouette scores
```

### Outlier Detection: DBSCAN

```
outliers = detect_outliers(tourists) =
    # Tourists who don't fit any cluster

    DBSCAN(eps=0.3, min_samples=3)
    # Points labeled -1 are outliers (solo-preferred travelers)
```

## Feature Vector

### Input Features (32 dimensions)

```
group_features = {
    # Interest alignment (5 dims)
    food_similarity: float,
    culture_similarity: float,
    adventure_similarity: float,
    pace_similarity: float,
    budget_similarity: float,

    # Demographics (4 dims)
    age_distance: float,           # |tourist_age - group_avg_age|
    travel_style_match: float,     # One-hot encoding
    language_commonality: float,   # Jaccard similarity

    # Logistics (5 dims)
    requested_date_overlap: float,
    requested_time_overlap: float,
    duration_compatibility: float,
    location_proximity: float,     # Hotel locations

    # Preferences (8 dims)
    dietary_compatibility: float,
    mobility_match: float,
    group_size_preference: float,

    # Engagement (10 dims)
    booking_frequency: float,
    platform_tenure: float,
    review_rate: float,
    avg_guide_rating: float,
    response_rate: float,
}
```

## Clustering Pipeline

### Step 1: Feature Extraction

```python
def extract_group_features(tourist_batch):
    # Batch processing for efficiency
    features = []
    for tourist in tourist_batch:
        f = []
        f.append(tourist.food / 5.0)
        f.append(tourist.culture / 5.0)
        f.append(tourist.adventure / 5.0)
        f.append(tourist.pace / 5.0)
        f.append(tourist.budget / 5.0)
        # ... remaining features
        features.append(f)
    return normalize(features)  # L2 normalize
```

### Step 2: Optimal K Selection

```python
def find_optimal_k(tourists, k_range=range(2, 15)):
    scores = []
    for k in k_range:
        labels, centroids = kmeans(tourists, k)
        silhouette = silhouette_score(tourists, labels)
        scores.append((k, silhouette))

    # Select k with highest silhouette score
    optimal_k = max(scores, key=lambda x: x[1])[0]
    return optimal_k
```

### Step 3: Group Assignment

```python
def assign_to_groups(tourist, clusters, centroids):
    """
    Assign a tourist to an existing group or trigger new group formation
    """
    # Find nearest centroid
    nearest_cluster = find_nearest_centroid(tourist.features, centroids)
    cluster = clusters[nearest_cluster]

    # Check group size constraint
    if len(cluster.members) < 8:  # Max group size
        if cluster.silhouette_score > 0.3:  # Quality threshold
            cluster.add(tourist)
            return cluster

    # Create new cluster
    return create_new_cluster(tourist)
```

## Group Size Constraints

```
MIN_GROUP_SIZE = 3
MAX_GROUP_SIZE = 8
OPTIMAL_GROUP_SIZE = 5

Size Rules:
- Below MIN_GROUP_SIZE: "Solo option" or "Small group" flag
- Above MAX_GROUP_SIZE: Split into multiple groups
- OPTIMAL_GROUP_SIZE: Ideal balance for social + logistics
```

## Group Formation Triggers

### Automatic (ML-Driven)

```
trigger_group_formation(tourist_request) =
    if tourist.prefers_group == true AND
       tourist_request.location != null AND
       tourist_request.date != null:

        # Find compatible tourists
        candidates = find_matching_tourists(tourist_request)

        if len(candidates) >= 3:
            cluster = form_cluster(candidates + [tourist])
            suggest_group_tour(cluster)
```

### Tourist-Initiated

```
# Tourist sees "Join a group" option
join_group_request(tourist, preferences) =
    find_group_options(
        date=preferences.date,
        location=preferences.location,
        interests=preferences.primary_interest,
        size_range=(3, 8)
    )
```

## Group Lifecycle

### State Machine

```
PENDING → CONFIRMED → IN_PROGRESS → COMPLETED
   ↓           ↓           ↓
 CANCELLED  CANCELLED   CANCELLED
```

### State Definitions

| State       | Definition                     | Exit Conditions                               |
| ----------- | ------------------------------ | --------------------------------------------- |
| PENDING     | Formed, awaiting confirmations | All confirm → CONFIRMED; Any decline → reform |
| CONFIRMED   | All members committed          | Tour date arrives → IN_PROGRESS               |
| IN_PROGRESS | Tour is happening              | Tour ends → COMPLETED                         |
| COMPLETED   | Successfully finished          | Final state                                   |
| CANCELLED   | Dissolved before tour          | Final state                                   |

### Dissolution Rules

```
dissolve_conditions(group) =
    - Member drops below MIN_GROUP_SIZE (3)
    - Majority (>50%) vote to cancel
    - Guide cancels
    - 48 hours before tour with no resolution
```

## Communication

### Group Chat

```
# Each confirmed group gets a chat channel
group_chat = {
    participants: [tourist_ids] + [guide_id],
    messages: Message[],
    created_at: timestamp,
    tour_context: {
        itinerary: Itinerary,
        meeting_point: Location,
        meeting_time: datetime
    }
}
```

## Dynamic Rebalancing

### Cancellation Handling

```
on_member_cancel(group, tourist_id):
    group.remove(tourist_id)

    if len(group.members) < MIN_GROUP_SIZE:
        # Option 1: Recruit replacement
        replacement = find_replacement(group, cancelled_tourist)
        if replacement:
            group.add(replacement)
            return

        # Option 2: Convert to smaller group
        if len(group.members) >= 2:
            notify_group("Group size reduced to {n} travelers")
            return

        # Option 3: Dissolve
        dissolve_group(group, reason="insufficient_members")
```

## Solo Travelers (DBSCAN Outliers)

```
outlier_handling(tourist):
    if tourist.cluster_id == -1:  # DBSCAN outlier
        # Prefers independent travel
        return {
            "eligible_for_groups": false,
            "reason": "travel_style=independent",
            "alternative": "Private guide matching"
        }
```

## Performance Requirements

| Metric                     | Target                        |
| -------------------------- | ----------------------------- |
| Clustering latency (p95)   | < 100ms per tourist           |
| Group suggestion relevance | Silhouette > 0.3              |
| Rejection rate             | < 20% of suggested groups     |
| Formation success rate     | > 60% of triggers → confirmed |
