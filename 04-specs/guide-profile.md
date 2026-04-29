# Guide Profile Specification

## Overview

The guide profile captures a local guide's expertise, availability, credentials, and behavioral data needed for matching with tourists. Guides are the supply side of WanderLess's marketplace.

## Profile Schema

### Core Profile

```python
guide_profile = {
    # Identity
    guide_id: string,
    name: string,
    photo_url: string,
    bio: string[max_500_chars],

    # Credentials (Required)
    tat_license: string,  # Tourism Authority of Thailand license
    license_verified: boolean,
    license_expiry: date,

    # Expertise Vector
    expertise_vector: {
        food: float[0-1],           # Food tour expertise level
        culture: float[0-1],        # Cultural/historical expertise
        adventure: float[0-1],      # Adventure activity expertise
        nightlife: float[0-1],       # Nightlife/entertainment
        nature: float[0-1],         # Nature/ecotourism
        shopping: float[0-1],        # Shopping expertise
        wellness: float[0-1],       # Spa/wellness
        photography: float[0-1],    # Photography tours
    },

    # Languages (Required)
    languages_spoken: string[],  # ISO 639-1 codes
    primary_language: string,
    translation_available: boolean,

    # Service Parameters
    tour_types: string[],          # e.g., ["private", "group", "walking", "driving"]
    max_group_size: int[1-12],
    min_booking_notice_hours: int,
    cancellation_policy: enum["flexible", "moderate", "strict"],

    # Availability
    availability: {
        weekly_schedule: {
            day: [start_hour, end_hour],
            ...
        },
        blocked_dates: date[],
        instant_booking: boolean,
    },

    # Geographic Coverage
    service_areas: [{
        city: string,
        neighborhoods: string[],
        base_location: {lat, lng},
    }],

    # Business Data
    business_partners: partner_id[],  # Linked business partners
    average_tour_price: float,
    price_tier: enum["budget", "mid", "premium"],

    # Performance Metrics (Computed)
    metrics: {
        total_tours_completed: int,
        average_rating: float[1-5],
        rating_count: int,
        response_rate: float[0-1],
        response_time_minutes: int,
        cancellation_rate: float[0-1],
        repeat_tourist_rate: float[0-1],
        verified_badges: string[],  # e.g., ["top_guide", "food_expert"]
    },

    # Tier
    tier: enum["free", "professional", "expert"],
    tier_since: date,

    # Computed (ML)
    expertise_embedding: float[64],
    personality_vector: float[32],
    segment: string,  # Guide category for matching
}
```

## TAT License Verification

### Thailand Guide Licensing

```
Thailand requires tour guides to hold a TAT (Tourism Authority of Thailand) license.
Types:
- Thai Guide License: For Thai nationals
- Guide License (Foreigner): For foreign guides with work permits
```

### Verification Flow

```
1. Guide uploads TAT license image
2. System extracts license number via OCR
3. Validate against TAT database (mock for Phase 1)
4. Check expiry date (must be > 6 months)
5. Mark as verified or flag for manual review

Verification Status:
- pending: Submitted, under review
- verified: Valid license confirmed
- expired: License expired, guide notified
- invalid: License number not found
- manual_review: Edge case needs human check
```

## Onboarding Flow

### Step 1: Application

```
Screen: "Join WanderLess as a Guide"

Requirements:
✓ TAT License (Tourism Authority of Thailand)
✓ Smartphone with camera
✓ Bank account for payouts
✓ 18+ years old

[Apply Now]
```

### Step 2: License & Identity

```
Screen: "Verify Your Credentials"

TAT License Number: [Text field]
Upload License Photo: [Camera/Gallery]
Upload ID Photo: [Passport or Thai ID]

Processing time: Up to 48 hours
```

### Step 3: Profile Creation

```
Screen: "Your Guide Profile"

Name: [Pre-filled from signup]
Photo: [Upload]
Bio: [Text area - 500 chars max]

Expertise Selection (select top 3):
[✓] Food & Culinary
[ ] Culture & History
[ ] Adventure & Outdoor
[ ] Nightlife
[ ] Nature & Wildlife
[ ] Shopping
[ ] Wellness & Spa
[ ] Photography

Languages You Speak:
[English ▼] [+ Add Language]

Maximum Group Size: [5 ▼] (1-12)
```

### Step 4: Service Areas

```
Screen: "Where Do You Offer Tours?"

Primary City: [Chiang Mai ▼]

Neighborhoods/Areas (select all):
[✓] Old City
[✓] Nimman
[ ] Doi Suthep
[ ] Night Bazaar
[ ] Santithan
[ ] Other: [Text field]

Base Location: [Pin on map]
```

### Step 5: Availability Setup

```
Screen: "Your Availability"

Weekly Schedule:
Monday:    [09:00 ▼] - [18:00 ▼] [Active]
Tuesday:   [09:00 ▼] - [18:00 ▼] [Active]
...

Blocked Dates: [Calendar picker]

Instant Booking:
[✓] Allow instant bookings (no approval needed)

Minimum Notice: [4 ▼] hours before tour
```

### Step 6: Business Partners (Optional)

```
Screen: "Connect Your Partners"

Link business partners for referral commission:

[ ] Add Partner Store
    - Search stores by name
    - Scan partner QR code

Partners earn 5-10% commission when tourists visit
through your tours.
```

### Step 7: Review & Submit

```
Screen: "Review Your Profile"

[Preview Profile]

Guide ID: GL-XXXXX
Status: Pending Verification
Verification ETA: 24-48 hours

[Submit Application]
```

## Guide Dashboard

### Key Metrics Displayed

```
┌─────────────────────────────────────────────────┐
│  Your Performance (Last 30 Days)                │
├─────────────────────────────────────────────────┤
│  Tours Completed          │  12                   │
│  This Month's Earnings   │  ฿ 8,450              │
│  Average Rating          │  4.8 ★                │
│  Response Rate           │  98%                  │
│  Repeat Tourists         │  23%                  │
└─────────────────────────────────────────────────┘

[View Analytics] [Edit Profile] [Manage Availability]
```

## Guide Matching Preferences

### Profile-Matching Alignment

```python
# Guide can set preferences for tourist types
guide_preferences = {
    preferred_group_size: enum["solo", "couple", "small_group", "large_group"],
    preferred_travelers_age: enum["young", "mixed", "mature"],
    energy_level_match: enum["high", "medium", "flexible"],
    language_match_required: boolean,  # Must speak same language
}
```

## Premium Tiers

### Free Tier

```
Included:
- Profile listing in WanderLess
- Tourist matching (standard priority)
- Basic booking management
- Standard commission: 15-18%

Limitations:
- 1 active booking at a time
- No priority matching
- No analytics dashboard
- No business partner tools
```

### Professional Tier ($19.99/month)

```
Requirements: 20+ completed tours

Includes:
- Everything in Free
- Priority matching (shown to tourists first)
- Up to 5 concurrent active bookings
- Basic analytics dashboard
- Business partner management
- Featured listing in search results

Commission: 15%
```

### Expert Tier ($49.99/month)

```
Requirements: 50+ completed tours, 4.7+ average rating

Includes:
- Everything in Professional
- Top-tier featured listing
- Up to 12 concurrent bookings
- Advanced analytics
- Priority support
- Early access to new features
- Co-create audio tours (Phase 2)

Commission: 12%
```

## Guide Lifecycle

### Status States

```
ONBOARDING → ACTIVE → SUSPENDED → TERMINATED
              ↓
           INACTIVE (voluntary)
```

### Active Requirements

- TAT license current
- Response rate > 80%
- Cancellation rate < 10%
- Minimum 1 completed tour per quarter
- Profile complete > 80%

### Suspension Triggers

```
suspension_reasons = [
    "license_expired",
    "low_response_rate",      # < 80% for 30 days
    "high_cancellation",     # > 15% cancellation rate
    "quality_intervention",   # Rating < 3.5 average
    "safety_incident",
    "terms_violation",
]
```

### Quality Intervention

```
if guide.average_rating < 3.5:
    trigger_quality_review(guide)
    notify_guide("Your recent tours have received low ratings...")
    pause_new_bookings_until_review_complete()

if guide.average_rating < 3.0:
    escalate_to_support(guide)
    potential_suspension()
```

## Performance Metrics

### Rating Calculation

```
guide.rating = weighted_mean(
    ratings=guide.tour_ratings,
    weights=[1.0, 0.8, 0.6, 0.4],  # Most recent weighted more
)

# Minimum 5 ratings before displaying average
if guide.rating_count < 5:
    display: "New Guide - Building Rating"
```

### Response Metrics

```
response_rate = completed_responses / total_inquiries
response_time = median(time_to_first_response)
```

### Profile Completeness

```
completeness_score = (
    photo_uploaded * 0.1 +
    bio_filled * 0.1 +
    expertise_selected * 0.2 +
    languages_added * 0.15 +
    availability_set * 0.15 +
    business_partners_linked * 0.1 +
    verification_complete * 0.2
)
```

## Privacy & Data

### Guide Data Retention

- Profile data: Retained while active, 1 year after inactivity
- Earnings data: 7 years (tax compliance)
- Rating data: Indefinite for ML training

### Guide Rights

- View all collected data
- Export earnings reports
- Delete profile (subject to pending bookings)
- Dispute ratings within 14 days
