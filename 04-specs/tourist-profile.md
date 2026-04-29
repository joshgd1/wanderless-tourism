# Tourist Profile Specification

## Overview

The tourist profile is the foundational data structure that powers WanderLess's matching engine. It captures a tourist's interests, preferences, and behavioral signals to enable compatibility-based matching with guides.

## Profile Schema

### Core Interest Vector (64 dimensions)

```
tourist_profile = {
    # Interest Dimensions (5 primary, 59 derived)
    primary_interests: {
        food: float[0-1],        # Culinary exploration weight
        culture: float[0-1],       # Cultural immersion weight
        adventure: float[0-1],     # Adventure activity weight
        pace: float[0-1],          # Slow(0) vs fast(1) travel style
        budget: float[0-1]         # Budget(0) vs luxury(1)
    },

    # Demographics
    age_group: enum["18-25", "26-35", "36-45", "46-55", "56-65", "65+"],
    travel_style: enum["solo", "couple", "friends", "family", "group"],

    # Language Preferences
    primary_language: string,  # ISO 639-1
    acceptable_languages: string[],  # Guides must speak one

    # Physical Constraints
    mobility: enum["full", "limited", "accessible"],
    dietary_restrictions: string[],
    accessibility_needs: string[],

    # Temporal Preferences
    preferred_start_time: enum["early_morning", "morning", "midday", "afternoon", "evening"],
    tour_duration_preference: enum["2h", "4h", "6h", "full_day", "multi_day"],

    # Historical Signals (for collaborative filtering)
    completed_tours: tour_id[],
    guide_ratings: {guide_id: float[1-5]},
    guide_id_vector: guide_id[],  # Guides tourist has rated
    rating_vector: float[],         # Corresponding ratings

    # Engagement Signals
    viewed_guides: guide_id[],
    search_queries: string[],
    booking_frequency: enum["first_time", "occasional", "regular", "frequent"],

    # Computed Fields (ML-generated)
    interest_vector: float[64],     # Full embedding
    segment: string,                # K-Means cluster ID
    confidence_score: float[0-1],   # Profile completeness confidence
}
```

## Onboarding Flow

### Step 1: Interest Declaration (5 Sliders)

```
Screen: "What matters most in your travels?"

Interest Slider 1: Food
[  0  |============================  1  ]
Not important                           Essential

Interest Slider 2: Culture
...

Interest Slider 3: Adventure
...

Interest Slider 4: Pace
Solo/Slow                               Packed/Fast

Interest Slider 5: Budget
Hostel/Budget                           Resort/Luxury
```

**Validation**: All 5 sliders required. Cannot proceed without complete declaration.

### Step 2: Language Preferences

```
Screen: "What languages do you speak?"

Primary Language: [Dropdown: English, Mandarin, Korean, Japanese, ...]

Additional Languages (optional): [Multi-select]
```

### Step 3: Travel Style

```
Screen: "Who are you traveling with?"

[ ] Solo - I'm exploring on my own
[ ] Couple - My partner and I
[ ] Friends - A group of friends
[ ] Family - Adults and children
[ ] Group - Organized group tour
```

### Step 4: Physical & Dietary Constraints

```
Screen: "Any special requirements?" (Optional)

[ ] Mobility limitations
[ ] Wheelchair accessibility needed
[ ] Dietary restrictions: [Text field]
[ ] Other accessibility needs: [Text field]
```

### Step 5: Profile Completion

```
Screen: "Your profile is ready!"

Based on your interests, we found:
• 12 guides matching your profile in Chiang Mai
• 3 potential group matches for food tours
• Average compatibility: 78%

[View Matches] [Browse Guides] [Take Me Somewhere]
```

## Profile Completeness Score

```
completeness_score = (
    primary_interests_filled * 0.3 +
    language_filled * 0.15 +
    travel_style_filled * 0.15 +
    physical_constraints_filled * 0.1 +
    completed_tours * 0.2 +
    engagement_signals * 0.1
)

Thresholds:
- < 0.5: "New" - Limited matching, recommend profile completion
- 0.5 - 0.75: "Active" - Basic matching available
- > 0.75: "Established" - Full matching with confidence
```

## Profile Update Triggers

### Implicit Updates (No User Action)

- Booking completed → update `completed_tours`, `guide_ratings`
- Guide rating submitted → update collaborative filtering vectors
- Guide viewed → add to `viewed_guides`
- Search query → add to `search_queries`

### Explicit Updates (User Action)

- Re-take interest sliders → full vector recompute
- Update travel style → segment recompute
- Add/remove language → matching filter update

## Matching Eligibility

```
eligible_for_matching(tourist) = (
    completeness_score >= 0.5 AND
    primary_interests_filled AND
    language_filled AND
    destination_selected
)
```

## Privacy & Data

### Retention

- Profile data: Retained for 3 years after last activity
- Rating history: Retained indefinitely for ML training
- Engagement signals: 90-day rolling window

### User Controls

- [ ] Allow data for ML training (default: on)
- [ ] Allow interest-based group matching (default: on)
- [ ] Data export (GDPR compliant)
- [ ] Profile deletion

## Edge Cases

### New Tourist (No History)

- Use `primary_interests` only for initial matching
- Apply popularity-based fallback for top guides
- Show "Building your profile" indicator

### Tourist with Contradictory Signals

- Example: Claims "adventure = 0.9" but only books cultural tours
- Flag for profile review
- Weight behavioral signals over stated preferences after threshold

### Tourist Refuses Interest Sliders

- Allow skip with confirmation: "Matching will be less accurate"
- Apply popularity-based matching only
- Show "Complete your profile for better matches" banner
