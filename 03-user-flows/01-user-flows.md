# WanderLess User Flow Analysis

**Document Version**: 1.0
**Date**: 2026-04-26
**Classification**: Product Requirements Document
**Prepared For**: WanderLess Founding Team
**Phase**: 01 — Analysis

---

## Executive Summary

WanderLess is an ML Compatibility Engine for Travel that matches tourists with local guides based on compatibility across five interest dimensions (food, culture, adventure, pace, budget), using hybrid recommendation ML to rank guide candidates and optimize tour itineraries. The product serves three distinct user types — tourists seeking personalized guided experiences, local guides wanting quality traveler matches, and business partners (restaurants, shops, activity providers) seeking foot traffic — connected by a group formation engine that clusters compatible tourists and an itinerary optimizer that sequences stops under constraints.

**Complexity**: Moderate — three-sided marketplace with real-time ML inference, batch group formation, and constraint-based planning; geographic density creates cold-start risk on all three sides simultaneously.

---

## 1. Tourist Journey

### 1.1 Discovery and Onboarding

**Entry Points**:

| Channel               | Discovery Mechanism                          | Conversion Trigger                        |
| --------------------- | -------------------------------------------- | ----------------------------------------- |
| Organic search        | "find local guide Thailand"                  | Guide profile preview + match explanation |
| Hostel/hotel referral | Partner concierge mentions WanderLess        | Trust signal from known intermediary      |
| Social media          | Instagram/TikTok content from prior tourists | User-generated experience video           |
| App store             | "travel guide matching" search               | Rating + screenshots                      |
| Business partner      | Restaurant/shop recommends after visit       | In-person endorsement                     |
| Word of mouth         | Friend who used WanderLess                   | Direct personal referral                  |

**Onboarding Sequence**:

```
[App Download / Web Visit]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Welcome Screen                                      │
│  "Find your ideal local guide — matched by          │
│   personality, not just destination"                │
│                                                     │
│  [Get Started] → [Language Selection]               │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Account Creation (30 seconds)                     │
│  • Google/Apple/Email sign-in                      │
│  • Name, nationality, travel dates                 │
│  • Destination city selection                       │
│  • Trip purpose: Solo / Couple / Group / Friends   │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Interest Declaration — 5 Sliders (3-5 minutes)   │
│                                                     │
│  Food:        1─────────5  (Street food → Fine dining) │
│  Culture:     1─────────5  (Surface → Deep immersion)  │
│  Adventure:   1─────────5  (Relaxed → Extreme)        │
│  Pace:        1─────────5  (Slow exploration → Efficient) │
│  Budget:      1─────────5  (Budget → Premium)          │
│                                                     │
│  Plus: Languages spoken, travel style (first-time   │
│  visitor / returning / digital nomad),              │
│  accessibility needs, group size preference          │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Feature Vector Generation                          │
│  System encodes:                                   │
│  • 5-dim interest vector → 64-dim embedding       │
│  • Demographics + preferences → profile object     │
│  • Stored in tourist feature store (Redis/Postgres) │
└─────────────────────────────────────────────────────┘
```

**Onboarding Data Captured**:

| Field                 | Type      | Purpose                           |
| --------------------- | --------- | --------------------------------- |
| `tourist_id`          | UUID      | Primary identifier                |
| `interest_vector`     | float[64] | Compressed interest embedding     |
| `demographics`        | object    | Age group, nationality, languages |
| `preferences`         | object    | Budget tier, pace, group size     |
| `travel_context`      | object    | Destination, dates, trip type     |
| `survey_completeness` | float     | Fraction of onboarding answered   |

**Failure Points**:

- Tourist abandons during 5-slider flow → Offer simplified 3-slider express path
- Tourist objects to interest declaration → Explain that skipping reduces match quality; allow "surprise me" mode with generic profile
- Duplicate account detection → Prompt to merge or continue as new

### 1.2 Match Browsing and Selection

**Match Generation**:

After onboarding, the ML matching engine runs a hybrid scoring model:

```
Compatibility Score = 0.40 × ContentScore + 0.40 × CollabScore + 0.20 × ContextScore
```

**Tourist views Top 5 Matches**:

```
┌─────────────────────────────────────────────────────┐
│  Your Top Matches in Chiang Mai                      │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ 1. [Photo] Kem S. — 94% match              │   │
│  │    "Food & culture specialist, 8 years"     │   │
│  │    ★ 4.9 (127 reviews) | Speaks: EN, TH    │   │
│  │    Top factors: Food interest, Pace match    │   │
│  │    [View Profile] [Request Match]           │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ 2. [Photo] Noot T. — 91% match             │   │
│  │    "Adventure + nature, sustainable tourism"│   │
│  │    ★ 4.8 (84 reviews) | Speaks: EN, DE     │   │
│  │    [View Profile] [Request Match]           │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ... (up to 5 shown)                               │
└─────────────────────────────────────────────────────┘
```

**Match Card Data Displayed**:

| Element             | Source                   | Purpose                 |
| ------------------- | ------------------------ | ----------------------- |
| Guide photo + name  | Profile                  | Recognition + trust     |
| Compatibility score | ML engine (0-100%)       | Quick quality signal    |
| Star rating         | Aggregated reviews       | Social proof            |
| Review count        | Aggregated reviews       | Volume signal           |
| Languages           | Profile                  | Communication assurance |
| Bio excerpt         | Profile (LLM-summarized) | Context                 |
| Top match factors   | ML engine explainability | Why this match          |
| "View Profile"      | Full profile page        | Deep dive               |
| "Request Match"     | Booking initiation       | Primary CTA             |

**Confidence Interval Display**:

For guides with fewer than 50 ratings, the system shows a confidence indicator:

```
94% match ████████░░ (High confidence)
87% match █████░░░░░ (Medium confidence — newer guide)
```

**Profile Deep-Dive Screen**:

```
┌─────────────────────────────────────────────────────┐
│  ← Back                                            │
│                                                     │
│  [Large Photo]                                     │
│  Kem S. — 94% match                               │
│  ★ 4.9 (127 reviews) | Guide since 2019          │
│                                                     │
│  Languages: English (Native), Thai (Native),        │
│             Mandarin (Conversational)               │
│                                                     │
│  ──────────────────────────────────────────────    │
│                                                     │
│  ABOUT                                             │
│  "I grew up in Chiang Mai's old city and have      │
│   been guiding for 8 years. I specialize in        │
│   food tours that take you beyond the night        │
│   market — into family kitchens and local          │
│   morning markets."                               │
│                                                     │
│  SPECIALTIES                                       │
│  [Food tours] [Cooking classes] [Market visits]   │
│  [Cultural sites] [Photography spots]              │
│                                                     │
│  MATCH FACTORS                                     │
│  ✓ Food interest alignment: 97%                    │
│  ✓ Pace preference match: Moderate pace            │
│  ✓ Culture depth alignment: High                   │
│  ⚠ Budget note: Avg tour $85 (your budget: $120+) │
│                                                     │
│  RECENT REVIEWS                                    │
│  "Kem's food tour was the highlight of our        │
│   Thailand trip." — Sarah M. (UK)                │
│  "Amazing hidden gems we never would have found   │
│   on our own." — James L. (AU)                   │
│                                                     │
│  ──────────────────────────────────────────────    │
│                                                     │
│  AVAILABILITY                                      │
│  [Aug 15] [Aug 16] [Aug 18] [Aug 20]             │
│                                                     │
│  [      Request This Guide — $85/person      ]     │
└─────────────────────────────────────────────────────┘
```

**Selection Flow**:

```
[Tourist taps "Request Match"]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Request Confirmation Modal                        │
│                                                     │
│  "Send match request to Kem? She'll have 24 hours  │
│   to confirm. You'll be notified immediately        │
│   when she responds."                             │
│                                                     │
│  Tour date: [Aug 15 ▼]                            │
│  Group size: [2 adults]                           │
│  Special requests: [________________]              │
│                                                     │
│  [Cancel]                    [Send Request →]      │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Request Sent — Awaiting Guide Confirmation        │
│                                                     │
│  ⏳ Kem has 24 hours to respond                    │
│                                                     │
│  "While you wait, browse more guides or adjust     │
│   your interest profile."                          │
│                                                     │
│  [Browse More Guides] [Adjust Interests]          │
└─────────────────────────────────────────────────────┘
```

**Guide Decision States**:

| State             | Tourist Experience                                                     | Timeout Behavior      |
| ----------------- | ---------------------------------------------------------------------- | --------------------- |
| Guide confirms    | Push notification + email: "Kem confirmed!"                            | —                     |
| Guide declines    | "Kem is unavailable. Here are 3 similar guides:"                       | —                     |
| Guide no-response | "No response after 24h. Request another guide or browse alternatives." | Auto-expire after 24h |
| Tourist cancels   | Refund if payment captured; release guide slot                         | —                     |

### 1.3 Booking Flow

**Post-Match Confirmation Sequence**:

```
[Guide Confirms Match]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Booking Screen                                     │
│                                                     │
│  Guide: Kem S.                                     │
│  Date: Aug 15, 2026                               │
│  Duration: 6 hours                                 │
│  Includes: Transportation, all food tastings       │
│                                                     │
│  Group breakdown:                                   │
│  • 2 adults × $85 = $170                          │
│  • Platform fee (15%): $25.50                     │
│  • Total: $195.50                                  │
│                                                     │
│  [    Confirm Booking — $195.50          ]         │
│                                                     │
│  By confirming, you agree to WanderLess Terms      │
│  and Cancellation Policy                           │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Payment (Stripe / Local Payment Methods)          │
│                                                     │
│  • Credit/Debit Card                              │
│  • PromptPay QR (Thai users)                       │
│  • Apple Pay / Google Pay                          │
│                                                     │
│  [    Pay $195.50                        ]         │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Booking Confirmed                                  │
│                                                     │
│  ✓ Payment processed                               │
│  ✓ Guide notified                                  │
│  ✓ Itinerary planning begins                      │
│                                                     │
│  Next: Collaborate with Kem on your itinerary      │
│                                                     │
│  [View Booking] [Message Kem] [Browse Experiences] │
└─────────────────────────────────────────────────────┘
```

**Payment Flow Details**:

| Step | Actor                     | Action        | System Response                               |
| ---- | ------------------------- | ------------- | --------------------------------------------- |
| 1    | Tourist confirms booking  | Tap "Confirm" | Capture payment intent (Stripe)               |
| 2    | Tourist completes payment | Stripe SDK    | Funds held in escrow                          |
| 3    | System processes          | —             | Guide notified, booking record created        |
| 4    | Guide confirms itinerary  | —             | Escrow released to guide within 48h post-tour |
| 5    | Cancellation              | Policy check  | Partial/full refund per policy                |

**Booking Record Schema**:

```python
booking = {
    'booking_id': 'uuid',
    'tourist_id': 'uuid',
    'guide_id': 'uuid',
    'destination': 'chiang_mai',
    'tour_date': 'date',
    'duration_hours': 6,
    'group_size': 2,
    'gross_value': 170.00,
    'platform_fee': 25.50,
    'guide_payout': 144.50,
    'payment_status': 'held_escrow',
    'booking_status': 'confirmed',
    'itinerary_id': 'uuid | null',
    'created_at': 'timestamp',
}
```

### 1.4 Pre-Tour Communication

**Communication Channels**:

| Channel               | Use Case                      | Translator?          |
| --------------------- | ----------------------------- | -------------------- |
| In-app messaging      | Itinerary planning, check-ins | Yes — auto-translate |
| WhatsApp (opt-in)     | Urgent on-day contact         | No (native)          |
| Platform notification | Booking updates, reminders    | N/A                  |

**Itinerary Collaboration**:

After booking, tourist and guide collaborate on the itinerary:

```
┌─────────────────────────────────────────────────────┐
│  Itinerary Planning with Kem                        │
│                                                     │
│  Kem's suggested itinerary (pending your input):    │
│                                                     │
│  09:00 — Pick up at hotel                        │
│  09:30 — Warorot Market (morning market)          │
│  11:00 — cooking class prep (ingredients shop)    │
│  12:30 — Lunch at local favorite                 │
│  14:00 — Temple visit (Doi Suthep area)          │
│  16:00 — Coffee at artisan roaster               │
│  18:00 — Drop off at hotel                      │
│                                                     │
│  Total travel time: ~45 min (within constraint)   │
│  Satisfaction score: 94/100 (predicted)           │
│                                                     │
│  [Edit Itinerary] [Approve Itinerary]            │
└─────────────────────────────────────────────────────┘
```

**Itinerary Optimizer Inputs**:

| Input                   | Tourist Provides     | Guide Provides | System Computes       |
| ----------------------- | -------------------- | -------------- | --------------------- |
| Available time          | Yes                  | —              | —                     |
| Start/end locations     | Yes                  | —              | —                     |
| POI preferences         | From interest vector | —              | Match to POI database |
| Opening hours           | —                    | —              | From POI database     |
| Energy curve            | From pace preference | —              | Modeled by ML         |
| Weather sensitivity     | From profile         | —              | Weather API forecast  |
| Guide's local knowledge | —                    | Yes            | Constraint validation |

**Pre-Tour Checklist**:

```
┌─────────────────────────────────────────────────────┐
│  Pre-Tour Checklist                                 │
│                                                     │
│  ☑ Booking confirmed ($195.50 paid)               │
│  ☑ Itinerary approved by you                      │
│  ☑ Kem has your contact details                   │
│  ☐ Day-of reminder (sent 24h before)              │
│  ☐ Kem's phone number available (in-app only)      │
│                                                     │
│  Questions for Kem? [Send message]                  │
│                                                     │
│  [View Full Itinerary] [Cancel Booking]            │
└─────────────────────────────────────────────────────┘
```

### 1.5 During-Tour Experience

**Tour Execution Flow**:

```
[Morning of Tour Day]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  08:00 — Day-of Notification                       │
│  "Kem is expecting you at 09:00 at Warorot Market │
│   main entrance. Tap for directions."               │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  In-Tour Tracking (Tourist View)                   │
│                                                     │
│  Current: Warorot Market                          │
│  Next stop: Cooking class location                  │
│  ETA to next: 8 minutes                           │
│                                                     │
│  [Message Kem] [Emergency] [View Full Itinerary]  │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  At Each Stop — Tourist Actions                    │
│                                                     │
│  • View stop details, history, significance        │
│  • Rate current experience (1-5 quick tap)        │
│  • Flag concern (guide quality, wrong location)    │
│  • Request detour (guide approval required)        │
└─────────────────────────────────────────────────────┘
```

**Dynamic Re-Routing (Weather/Closure)**:

```
[POI Closed or Weather Alert]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Itinerary Update                                  │
│                                                     │
│  ⚠ Doi Suthep Temple closed for ceremony          │
│                                                     │
│  Alternative suggested:                              │
│  • Doi Pui Temple (nearby, open) — 15 min extra   │
│  • Skip this stop, extend lunch — no extra time   │
│                                                     │
│  [Accept Alternative] [Skip Stop] [Contact Kem]   │
└─────────────────────────────────────────────────────┘
```

**End-of-Tour**:

```
[Kem ends tour, drops tourist at hotel]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Tour Complete — How was it?                        │
│                                                     │
│  Rate your experience with Kem:                   │
│                                                     │
│  Overall: ★ ★ ★ ★ ☆ (4.0)                        │
│                                                     │
│  [Submit Rating & Review]                          │
└─────────────────────────────────────────────────────┘
```

### 1.6 Rating and Feedback

**Post-Tour Rating Schema**:

```python
rating = {
    'rating_id': 'uuid',
    'booking_id': 'uuid',
    'tourist_id': 'uuid',
    'guide_id': 'uuid',
    'overall_rating': 4.0,  # 1-5
    'match_accuracy': 4.0,   # Did the guide match profile?
    'itinerary_quality': 4.0,  # Was the plan good?
    'communication': 5.0,   # Guide responsiveness
    'local_knowledge': 5.0,  # Guide expertise
    'text_review': 'string | null',
    'would_recommend': True,
    'explicit_feedback': {   # Free-form tags
        'positive': ['food amazing', 'great stories'],
        'negative': ['pace was fast'],
    },
    'rating_submitted_at': 'timestamp',
}
```

**Review Prompts (Guided)**:

```
┌─────────────────────────────────────────────────────┐
│  Share your experience                              │
│                                                     │
│  What stood out? (select up to 3)                  │
│  □ Food quality                                   │
│  □ Cultural insights                               │
│  □ Kem's knowledge                                │
│  □ Hidden gems                                    │
│  □ Perfect pace                                   │
│  □ Great recommendations                          │
│                                                     │
│  Anything that could be better?                   │
│  [____________________________]                    │
│                                                     │
│  [Skip Review]          [Submit Review]            │
└─────────────────────────────────────────────────────┘
```

**Feedback Impact on ML System**:

| Rating Type           | Impact on Matching                  | Impact on Guide Profile         |
| --------------------- | ----------------------------------- | ------------------------------- |
| Low match accuracy    | Tourist future matches recalibrated | Guide specialty score adjusted  |
| Low itinerary quality | Satisfaction predictor retrained    | Guide planning score adjusted   |
| Communication issues  | Guide communication score reduced   | Flagged for coaching            |
| High local knowledge  | —                                   | Guide specialty score increased |

### 1.7 Re-Engagement

**Repeat Tourist Flow**:

```
[Returning Tourist Opens App]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  "Welcome back, Sarah                               │
│                                                     │
│   Your interest profile from Feb shows you loved   │
│   food tours. Want to explore Northern Thai cuisine │
│   again, or try something new?"                    │
│                                                     │
│  [Same Preferences] [Adjust Interests] [Browse]     │
└─────────────────────────────────────────────────────┘
         │
         ▼ (Same Preferences)
┌─────────────────────────────────────────────────────┐
│  We've updated your matches!                       │
│  • 12 new guides in Chiang Mai                    │
│  • Your top match from Feb (Kem) is available     │
│                                                     │
│  [Re-book Kem] [Browse New Matches] [Explore Bangkok] │
└─────────────────────────────────────────────────────┘
```

**Re-Engagement Triggers**:

| Trigger                     | Timeframe | Message                                                  |
| --------------------------- | --------- | -------------------------------------------------------- |
| Repeat visit to same city   | 30+ days  | "Kem is in your new city — Bangkok"                      |
| New city added to platform  | 60+ days  | "We're now in Penang! Here's your match"                 |
| Guide available in new city | 90+ days  | "Your favorite guide from Chiang Mai now covers Bangkok" |
| Seasonal reminder           | Annual    | "A year ago you explored Thailand — back this season?"   |

**Profile Update Path**:

```
[Tourist selects "Adjust Interests"]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Update Your Preferences                            │
│                                                     │
│  Sliders pre-filled with current values            │
│  Slider labels show current value                  │
│                                                     │
│  Food:     [=========●==] 7                        │
│  Culture:  [====●========] 4                        │
│  Adventure:[===●=========] 2                        │
│  Pace:     [=====●======] 5                        │
│  Budget:   [======●=====] 4                        │
│                                                     │
│  [Save Changes]                                     │
└─────────────────────────────────────────────────────┘
```

---

## 2. Guide Journey

### 2.1 Discovery and Signup

**Guide Acquisition Channels**:

| Channel              | Conversion Mechanism                          | CAC |
| -------------------- | --------------------------------------------- | --- |
| Tourist referral     | Satisfied tourists recommend to guide friends | $0  |
| Partner outreach     | Hotels, hostels, tourism boards refer guides  | $0  |
| Inbound web          | "Become a guide" CTA on site                  | $0  |
| Industry events      | Tourism meetups, guide associations           | $0  |
| Competitor departure | Guides leaving Klook/Viator                   | $0  |

**Guide Signup Flow**:

```
[Guide Visits "Become a Guide" Page]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  "Share your expertise with travelers               │
│   who'll love what you love"                       │
│                                                     │
│  Why guides join WanderLess:                       │
│  • Better-matched tourists (not just any tourist)  │
│  • 85% of booking value (15% platform fee)        │
│  • Free to start, premium tools at $14.99/month   │
│                                                     │
│  [Apply to Become a Guide]                         │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Guide Application                                  │
│                                                     │
│  • Full name, location (city/district)              │
│  • Languages spoken (with proficiency)              │
│  • Years of guiding experience                     │
│  • Tour guide license number (Thailand: TAT ID)   │
│  • Phone number, email                             │
│  • Short bio (500 chars)                           │
│  • Photo (professional or candid)                 │
│                                                     │
│  [Submit Application]                              │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Application Under Review                          │
│                                                     │
│  ⏳ Our team reviews applications within 48 hours   │
│                                                     │
│  You'll receive an email once approved.            │
└─────────────────────────────────────────────────────┘
```

**Guide Application Schema**:

```python
guide_application = {
    'application_id': 'uuid',
    'full_name': 'string',
    'location': {'city': 'string', 'district': 'string'},
    'languages': [{'code': 'en', 'name': 'English', 'proficiency': 'native|fluent|conversational'}],
    'years_experience': 'int',
    'license_number': 'string | null',  # TAT license for Thailand
    'license_verified': 'bool',
    'bio': 'string (max 500)',
    'photo_url': 'string',
    'status': 'pending_review | approved | rejected',
    'submitted_at': 'timestamp',
}
```

### 2.2 Profile Creation

**Guide Profile Builder**:

After approval, guides complete their profile:

```
┌─────────────────────────────────────────────────────┐
│  Build Your Guide Profile                           │
│                                                     │
│  STEP 1: Your Specialties                          │
│                                                     │
│  Select up to 5:                                  │
│  [x] Food tours                                   │
│  [x] Cooking classes                              │
│  [ ] Temple tours                                 │
│  [ ] Adventure / Trekking                         │
│  [ ] Night markets                               │
│  [ ] Photography tours                            │
│  [ ] Art & crafts                                │
│  [ ] Nature & wildlife                           │
│                                                     │
│  [Continue →]                                     │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  STEP 2: Your Guiding Style                       │
│                                                     │
│  Pace:  [---●-----] Slow and relaxed              │
│         [-----●---] Fast and efficient            │
│                                                     │
│  Group size: [---●-----] Solo travelers preferred  │
│              [-------●-] Up to 4                  │
│              [-------●-] Up to 8                  │
│                                                     │
│  Communication: [---●-----] Quiet and observant   │
│                 [-----●---] Enthusiastic storyteller│
│                                                     │
│  [Continue →]                                     │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  STEP 3: Service Details                          │
│                                                     │
│  Tour types offered (can offer multiple):          │
│  ┌─────────────────────────────────────────────┐   │
│  │ Half-day (4 hours)                          │   │
│  │ Price: $[___] /person                      │   │
│  │ Max group: [_]                              │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │ Full-day (8 hours)                          │   │
│  │ Price: $[___] /person                      │   │
│  │ Max group: [_]                              │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  What's included:                                  │
│  [x] Transportation                               │
│  [x] All food tastings                           │
│  [ ] Entry fees                                  │
│  [x] Water and snacks                            │
│                                                     │
│  [Continue →]                                     │
└─────────────────────────────────────────────────────┘
```

**Guide Profile Vector**:

The system constructs a guide specialty vector from the profile:

```python
guide_profile = {
    'guide_id': 'uuid',
    'specialty_vector': 'float[64]',  # Compressed from specialties + bio
    'demographics': {
        'age_group': 'int',
        'nationality': 'string',
        'languages': ['string'],
    },
    'guiding_style': {
        'pace': 'int 1-5',
        'group_size_tolerance': 'int 1-5',
        'communication_style': 'int 1-5',  # Reserved → enthusiastic
    },
    'service_details': {
        'tour_types': [{'type': 'half_day', 'price': 85, 'max_group': 4}],
        'includes': ['transportation', 'food_tastings'],
    },
    'experience_years': 'int',
    'license_verified': 'bool',
    'profile_completeness': 'float',  # 0.0 to 1.0
    'created_at': 'timestamp',
}
```

### 2.3 Availability Management

**Availability Calendar**:

```
┌─────────────────────────────────────────────────────┐
│  Kem's Availability                                │
│                                                     │
│  August 2026                                       │
│  ┌───┬───┬───┬───┬───┬───┬───┐                     │
│  │Mon│Tue│Wed│Thu│Fri│Sat│Sun│                     │
│  ├───┼───┼───┼───┼───┼───┼───┤                     │
│  │   │   │   │   │ 1 │ 2 │ 3 │                     │
│  │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │10 │  ← Green = available │
│  │11 │12 │13 │14 │15[█]│16 │17 │  ← [█] = booked    │
│  │18 │19 │20[█]│21 │22 │23 │24 │                     │
│  │25 │26 │27 │28 │29 │30 │31 │                     │
│  └───┴───┴───┴───┴───┴───┴───┘                     │
│                                                     │
│  [Edit Availability] [Sync with Calendar]            │
└─────────────────────────────────────────────────────┘
```

**Availability Actions**:

| Action          | Guide Selects         | System Response                     |
| --------------- | --------------------- | ----------------------------------- |
| Block date      | Single/multiple dates | Removed from matching pool          |
| Set recurring   | Weekly pattern        | Applied automatically               |
| Calendar sync   | iCal/Google Cal       | Real-time import of external blocks |
| Emergency block | Same-day              | Notify matched tourists + re-match  |

### 2.4 Match Requests (Incoming)

**Guide Notification Flow**:

```
[New Match Request Received]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  🔔 New Match Request — 94% compatibility!         │
│                                                     │
│  Sarah M. (UK) wants to tour with you             │
│                                                     │
│  Trip details:                                     │
│  • Aug 15, 2026 — Full day                        │
│  • 2 adults                                       │
│  • Food + Culture interests (aligned with you)     │
│                                                     │
│  Her priorities:                                   │
│  • Food focus (slider: 9/10)                      │
│  • Moderate pace                                  │
│  • Budget: $120+                                  │
│                                                     │
│  ⚠ You have 24 hours to respond                   │
│                                                     │
│  [View Sarah's Full Profile]                        │
│  [Accept] [Decline]                               │
└─────────────────────────────────────────────────────┘
```

**Guide Decision Screen**:

```
┌─────────────────────────────────────────────────────┐
│  Reviewing Sarah's Request                         │
│                                                     │
│  Compatibility: 94%                                │
│                                                     │
│  Sarah is looking for:                            │
│  • Food-focused experience (your specialty ✓)      │
│  • Moderate pace (your style ✓)                   │
│  • Cultural immersion (your forte ✓)              │
│                                                     │
│  Her background:                                  │
│  • First-time visitor to Chiang Mai               │
│  • Stayed at: [Show on map]                      │
│  • Traveling solo                                 │
│                                                     │
│  Your notes from past tourists:                   │
│  "Great conversationalist, loved hidden gems..."   │
│                                                     │
│  [Accept — Proceed to Itinerary]                   │
│  [Accept — Need to Modify Tour Details]            │
│  [Decline — Provide Reason]                        │
└─────────────────────────────────────────────────────┘
```

**Guide Decline Reasons**:

| Reason              | Tourist Notification                 | System Action             |
| ------------------- | ------------------------------------ | ------------------------- |
| Date unavailable    | "Kem is unavailable that day"        | Offer alternatives        |
| Group size mismatch | "Kem prefers smaller groups"         | Re-match to similar guide |
| Style mismatch      | "Kem feels this isn't the right fit" | No penalty to guide       |
| Emergency           | "Kem has an emergency"               | Expedited re-matching     |

### 2.5 Tour Planning with Itinerary Optimizer

**Itinerary Builder Interface**:

```
┌─────────────────────────────────────────────────────┐
│  Plan Sarah's Tour — Aug 15                         │
│                                                     │
│  [AI-Assisted] Suggested itinerary based on         │
│  Sarah's interests + your expertise:               │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ 09:00  Pick up at hotel                    │   │
│  │ 09:30  Warorot Market ★ 4.8               │   │
│  │        "Iconic morning market"             │   │
│  │        Est. 90 min | Walking              │   │
│  │        [Remove] [Edit duration]            │   │
│  └─────────────────────────────────────────────┘   │
│                        ↓                            │
│  ┌─────────────────────────────────────────────┐   │
│  │ 11:00  Cooking class prep                  │   │
│  │        "Ingredient shopping"               │   │
│  │        Est. 60 min | Walking              │   │
│  │        [Remove] [Edit duration]            │   │
│  └─────────────────────────────────────────────┘   │
│                        ↓                            │
│  ┌─────────────────────────────────────────────┐   │
│  │ 12:00  Lunch at Ridley's                   │   │
│  │        ★ 4.6 | $25/person avg             │   │
│  │        Est. 75 min | 5 min drive          │   │
│  │        [Remove] [Edit]                     │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  [+ Add Stop]                                      │
│                                                     │
│  ─────────────────────────────────────────────     │
│  Total duration: 6.5 hours                         │
│  Travel time: 45 min                               │
│  Satisfaction score: 94/100 (predicted)           │
│                                                     │
│  ⚠ Over budget for tourist's $120                 │
│    Current: $85 + extras = $110                   │
│                                                     │
│  [Save Draft] [Send to Tourist]                    │
└─────────────────────────────────────────────────────┘
```

**Itinerary Approval Sequence**:

```
[Guide sends itinerary]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Sarah receives itinerary draft                     │
│                                                     │
│  "Kem has proposed an itinerary for Aug 15:        │
│   6 hours, $85 + food at own expense              │
│   View and approve or suggest changes."            │
│                                                     │
│  [View Itinerary] [Request Changes]               │
└─────────────────────────────────────────────────────┘
         │
         ▼
[Tourist approves]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Itinerary Locked                                  │
│                                                     │
│  ✓ Both parties have approved                      │
│  ✓ Guide receives booking confirmation             │
│  ✓ Payment held in escrow                         │
└─────────────────────────────────────────────────────┘
```

### 2.6 During-Tour Execution

**Guide Tour-Day Interface**:

```
┌─────────────────────────────────────────────────────┐
│  Today's Tour: Sarah M.                            │
│                                                     │
│  Current stop: Warorot Market                       │
│  Arrived: 09:32 | Next: 10:45                     │
│                                                     │
│  Itinerary:                                        │
│  ✓ 09:00 Pick up (completed)                     │
│  → 09:30 Warorot Market (current)                 │
│  □ 11:00 Cooking class prep                       │
│  □ 12:30 Lunch at Ridley's                        │
│  □ 14:00 Doi Suthep Temple                       │
│  □ 16:00 Artisan coffee                          │
│                                                     │
│  [Mark Complete] [Add Unplanned Stop]              │
│  [Message Tourist] [Report Issue]                   │
└─────────────────────────────────────────────────────┘
```

**Unplanned Stop Addition**:

```
[Guide taps "Add Unplanned Stop"]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Add Stop                                          │
│                                                     │
│  Search or select:                                 │
│  □ View on map                                     │
│  □ Recent stops other guides added                 │
│                                                     │
│  Stop name: [________________]                     │
│  Est. duration: [60] min                          │
│  Est. cost to tourist: [$0] or [$__]/person       │
│                                                     │
│  Reason:                                           │
│  [Based on tourist's interests] ▼                 │
│                                                     │
│  [Cancel] [Add Stop]                               │
└─────────────────────────────────────────────────────┘
```

### 2.7 Post-Tour Settlement

**Settlement Flow**:

```
[Tour marked complete by guide]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Tour Complete — Settlement Processing              │
│                                                     │
│  Booking: Sarah M. — Aug 15, 2026                 │
│  Gross value: $170 (2 × $85)                      │
│  Platform fee (15%): $25.50                       │
│  Your payout: $144.50                             │
│                                                     │
│  💰 Payout initiated                               │
│  Expected: 48 hours (TrueMoney / Bank transfer)    │
│                                                     │
│  Tourist has been prompted to leave a review.      │
└─────────────────────────────────────────────────────┘
```

**Payout Methods and Timing**:

| Method               | Availability  | Timing   | Fees         |
| -------------------- | ------------- | -------- | ------------ |
| TrueMoney            | Thailand      | 48 hours | None         |
| Bank transfer (Thai) | Thailand      | 48 hours | THB 30       |
| International wire   | All countries | 3-5 days | $15          |
| PayPal               | All countries | 24 hours | 2.9% + $0.30 |

### 2.8 Growth Mechanics

**Guide Progression System**:

| Stage       | Tours Completed | Badge          | Benefits               |
| ----------- | --------------- | -------------- | ---------------------- |
| New         | 0-4             | New Guide      | Discovery placement    |
| Established | 5-19            | Verified Guide | Standard matching      |
| Experienced | 20-49           | Top Guide      | Priority matching      |
| Expert      | 50-99           | Expert Guide   | Premium tools unlocked |
| Master      | 100+            | Master Guide   | Platform featured      |

**Premium Tools Tiers**:

| Tier         | Price     | Unlock       | Features                                                                |
| ------------ | --------- | ------------ | ----------------------------------------------------------------------- |
| Free         | $0        | All guides   | Basic calendar, messaging, payouts                                      |
| Professional | $14.99/mo | 20+ bookings | Analytics dashboard, priority matching, business insights               |
| Expert       | $49.99/mo | 50+ bookings | AI itinerary suggestions, multi-destination coverage, dedicated support |

**Guide Analytics Dashboard**:

```
┌─────────────────────────────────────────────────────┐
│  Your Performance — July 2026                      │
│                                                     │
│  Bookings: 12 (↑ 20% vs June)                     │
│  Revenue: $1,530 (↑ 15% vs June)                 │
│  Avg rating: 4.8                                   │
│  Repeat tourists: 3                                │
│                                                     │
│  Your tourists by interest:                       │
│  Food: ████████████ 70%                          │
│  Culture: ██████ 35%                              │
│  Adventure: ██ 10%                                │
│                                                     │
│  [View Full Analytics] [Marketing Tools]           │
└─────────────────────────────────────────────────────┘
```

---

## 3. Business Partner Journey

### 3.1 Onboarding

**Partner Types**:

| Partner Type       | Examples                         | Primary Value      |
| ------------------ | -------------------------------- | ------------------ |
| Restaurants        | Local eateries, food stalls      | Tourist food spend |
| Activity providers | Cooking schools, craft workshops | Activity bookings  |
| Retail             | Souvenir shops, local crafts     | Tourist shopping   |
| Hotels/Hostels     | Boutique properties, hostels     | Tourist referrals  |
| Tourism bodies     | DMO, tourism associations        | Ecosystem building |

**Partner Application**:

```
[Business Visits "Partner With Us" Page]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Partner with WanderLess                           │
│                                                     │
│  Reach travelers matched to your offerings          │
│                                                     │
│  How it works:                                     │
│  1. Tourists are matched to partners based on      │
│     their interests                               │
│  2. Guides include partners in itineraries        │
│  3. Tourists visit — you pay 5-10% commission     │
│                                                     │
│  No upfront cost. Pay only when tourists visit.   │
│                                                     │
│  [Apply to Partner]                               │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Partner Application                               │
│                                                     │
│  Business name: [________________]                 │
│  Type: [Restaurant ▼]                             │
│  Location: [Chiang Mai ▼] [Map pin]               │
│  Contact email: [________________]                 │
│  Phone: [________________]                         │
│  Website (optional): [________________]            │
│                                                     │
│  Categories (select all that apply):              │
│  [x] Local Thai cuisine                          │
│  [ ] Vegetarian/vegan options                     │
│  [ ] Cooking classes                             │
│  [ ] Cultural experiences                        │
│  [ ] Shopping                                   │
│                                                     │
│  [Submit Application]                             │
└─────────────────────────────────────────────────────┘
```

### 3.2 Profile and Offering Setup

**Partner Portal**:

```
┌─────────────────────────────────────────────────────┐
│  Partner Dashboard — Ridley's Kitchen              │
│                                                     │
│  [Overview] [Visits] [Payments] [Settings]       │
│                                                     │
│  This month:                                       │
│  • Tourists referred: 23                          │
│  • Visits completed: 18                          │
│  • Revenue from referrals: $540                  │
│  • Commission owed: $40.50 (7.5%)               │
│                                                     │
│  Top-performing guides:                           │
│  1. Kem S. — 8 visits                            │
│  2. Noot T. — 5 visits                          │
│  3. Boom P. — 3 visits                          │
│                                                     │
│  [View Tourist Insights] [Update Menu]           │
└─────────────────────────────────────────────────────┘
```

**Partner Profile Fields**:

| Field               | Type          | Displayed To            |
| ------------------- | ------------- | ----------------------- |
| Business name       | string        | Tourists (in itinerary) |
| Photo               | image         | Tourists                |
| Description         | text          | Tourists                |
| Cuisine/category    | multi-select  | Matching algorithm      |
| Price range         | enum ($-$$$$) | Tourists                |
| Hours               | schedule      | Itinerary optimizer     |
| Location            | geo           | Guide route planning    |
| Average visit spend | float         | Commission calculation  |

### 3.3 Guide Matching/Invitation

**Partner Guide Connection**:

```
┌─────────────────────────────────────────────────────┐
│  Invite Guides to Feature Your Business            │
│                                                     │
│  Recommended guides for Ridley's:                   │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ Kem S. ★ 4.9 (127 reviews)                │   │
│  │ 8 tours/month include Ridley's             │   │
│  │ [Invite to Partner] [View Profile]         │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │ Noot T. ★ 4.8 (84 reviews)               │   │
│  │ 3 tours/month include Ridley's             │   │
│  │ [Invite to Partner] [View Profile]         │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  [Search All Guides]                              │
└─────────────────────────────────────────────────────┘
```

**Guide Partnership Request**:

```
[Guide receives invitation]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Ridley's Kitchen wants to partner with you        │
│                                                     │
│  "Ridley's would like to be featured in your      │
│   food tours. As a partner, they pay 7.5%         │
│   commission on tourist visits you bring."        │
│                                                     │
│  Commission rate: 7.5%                            │
│  Avg tourist spend: $25                           │
│  Estimated monthly contribution: $15-30          │
│                                                     │
│  [Accept Partnership] [Decline] [Learn More]      │
└─────────────────────────────────────────────────────┘
```

### 3.4 Visit Tracking

**Visit Attribution**:

```python
visit = {
    'visit_id': 'uuid',
    'partner_id': 'uuid',
    'guide_id': 'uuid',
    'booking_id': 'uuid',
    'tourist_id': 'uuid',
    'visit_timestamp': 'timestamp',
    'tourist_spend_estimate': 25.00,  # Guide enters actual spend
    'commission_rate': 0.075,
    'commission_amount': 1.88,
    'settlement_status': 'pending | paid',
    'paid_at': 'timestamp | null',
}
```

**Guide Visit Recording**:

```
[Guide ends tour with partner visit]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Record Visit                                       │
│                                                     │
│  Partner: Ridley's Kitchen                        │
│  Tourist group: 2 adults                          │
│                                                     │
│  Total bill (optional): $[____]                    │
│  Guide tip: [included / separate]                 │
│                                                     │
│  Note: [________________]                          │
│                                                     │
│  [Skip] [Record Visit]                            │
└─────────────────────────────────────────────────────┘
```

### 3.5 Payment Settlement

**Partner Commission Settlement**:

| Settlement        | Frequency      | Method                    |
| ----------------- | -------------- | ------------------------- |
| Commission        | Monthly (15th) | Bank transfer / TrueMoney |
| Minimum threshold | $10            | Below waived              |

**Partner Statement**:

```
┌─────────────────────────────────────────────────────┐
│  July 2026 Statement — Ridley's Kitchen             │
│                                                     │
│  Opening balance: $0.00                            │
│                                                     │
│  Jul 3  — Kem S. — 2 tourists — $52 spend        │
│  Jul 5  — Kem S. — 2 tourists — $48 spend        │
│  Jul 8  — Noot T. — 1 tourist — $25 spend       │
│  ...                                               │
│                                                     │
│  Gross tourist spend: $540                        │
│  Commission (7.5%): $40.50                        │
│  Net payable: $499.50                              │
│                                                     │
│  Payment on Aug 15: $499.50                        │
└─────────────────────────────────────────────────────┘
```

### 3.6 Performance Analytics

**Partner Insights Dashboard**:

```
┌─────────────────────────────────────────────────────┐
│  Tourist Insights — Ridley's Kitchen               │
│                                                     │
│  Tourist demographics:                             │
│  • Nationalities: US (40%), UK (25%), AU (15%)   │
│  • Age groups: 26-35 (45%), 36-45 (30%)          │
│  • Avg trip duration: 6 nights                    │
│                                                     │
│  What tourists say about you:                     │
│  • "Best meal in Chiang Mai" — 12 reviews        │
│  • "Kem recommended this place" — 8 reviews      │
│  • "Authentic local food" — 15 reviews           │
│                                                     │
│  Conversion:                                       │
│  • Tourists who viewed profile: 45               │
│  • Tourists who visited: 23 (51%)               │
│                                                     │
│  [Export Data] [Request Report]                   │
└─────────────────────────────────────────────────────┘
```

---

## 4. Group Formation Flow

### 4.1 How Tourists Are Clustered

**Group Formation Engine Overview**:

The system runs K-Means clustering on tourist feature vectors daily to identify compatible groups for shared experiences.

**Input Features for Clustering**:

| Feature                      | Type        | Range           | Weight |
| ---------------------------- | ----------- | --------------- | ------ |
| Interest vector (compressed) | float[64]   | Embedding space | High   |
| Pace preference              | ordinal     | 1-5             | Medium |
| Budget tier                  | ordinal     | 1-5             | Medium |
| Age group                    | categorical | 6 bins          | Low    |
| Language                     | categorical | ISO 639-1       | Medium |
| Trip duration                | continuous  | days            | Low    |
| Group size preference        | ordinal     | 1-5             | Medium |
| Flexibility score            | continuous  | 0-1             | Low    |

**Clustering Algorithm**:

```python
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

# Daily batch process
features = StandardScaler().fit_transform(tourist_feature_matrix)

# Optimal k determined by silhouette score (3-8 tourists per group)
optimal_k = KMeans(
    n_clusters=find_optimal_k(features, min_size=3, max_size=8),
    random_state=42,
    n_init=10
).fit_predict(features)

# DBSCAN for outlier detection (solo-preferred)
outliers = DBSCAN(eps=1.5, min_samples=5, metric='cosine').fit_predict(features)
```

### 4.2 Group Size Constraints

| Constraint               | Value                  | Rationale                                              |
| ------------------------ | ---------------------- | ------------------------------------------------------ |
| Minimum group size       | 3 tourists             | Below = awkward pairing, no group dynamics             |
| Maximum group size       | 8 tourists             | Above = logistical complexity, diluted guide attention |
| Solo detection threshold | Silhouette score < 0.2 | Force solo if feature compatibility too low            |

**Group Size Ranges**:

| Range        | Use Case             | Common Formation                    |
| ------------ | -------------------- | ----------------------------------- |
| 3-4 tourists | Intimate group tours | Friends traveling together, couples |
| 5-6 tourists | Standard small group | Solo travelers matched together     |
| 7-8 tourists | Larger group tours   | Compatible solo travelers           |

### 4.3 Opt-In/Opt-Out Mechanics

**Tourist Group Preference**:

```
┌─────────────────────────────────────────────────────┐
│  Group Tour Preferences                             │
│                                                     │
│  For your Aug 10-17 trip to Chiang Mai:            │
│                                                     │
│  Group participation:                              │
│  ○ I'd prefer a private tour (solo)                │
│  ● Open to joining a group (recommended)          │
│                                                     │
│  If grouped, comfortable with:                    │
│  ☑ Couples/small groups (2-4)                     │
│  ☑ Other solo travelers                           │
│  ☑ Larger groups (up to 8)                       │
│                                                     │
│  ⚠ Group tours offer 20% discount per person      │
│                                                     │
│  [Save Preferences]                               │
└─────────────────────────────────────────────────────┘
```

**Opt-Out Consequences**:

| Scenario              | Tourist Experience       | Match Quality Impact        |
| --------------------- | ------------------------ | --------------------------- |
| Tourist opts for solo | Private match only       | Standard matching           |
| Silhouette < 0.2      | Solo suggested by system | Higher match score possible |
| No compatible group   | Solo fallback after 48h  | Standard matching           |

### 4.4 Group Communication

**For Grouped Tourists**:

```
┌─────────────────────────────────────────────────────┐
│  🎉 You're matched with 2 other travelers!          │
│                                                     │
│  Your group for Aug 15:                           │
│  • You (Food + Culture, moderate pace)           │
│  • Lisa K. from Australia (Food focus)            │
│  • Tom H. from UK (Culture + Adventure)          │
│                                                     │
│  Your guide: Kem S. — 94% match                   │
│                                                     │
│  [Group Chat (optional)] [View Itinerary]         │
└─────────────────────────────────────────────────────┘
```

**Group Chat Feature** (Optional):

| Feature              | Description                        |
| -------------------- | ---------------------------------- |
| In-app group chat    | Among grouped tourists before tour |
| Message history      | Persists until tour completion     |
| Guide included       | Can respond to questions           |
| Language translation | Auto-translate messages            |
| Mute/leave           | Tourist can exit group             |

### 4.5 Dynamic Rebalancing

**Rebalancing Triggers**:

| Trigger                | Condition                 | Action                                |
| ---------------------- | ------------------------- | ------------------------------------- |
| Group member cancels   | Size drops below 3        | Notify group + offer solo or re-match |
| New compatible tourist | Silhouette score improves | Offer to join existing group          |
| Guide unavailable      | Original guide cancels    | Full re-match + notify group          |
| Weather disruption     | POI closure               | Re-optimize itinerary (not re-group)  |

**Group Dissolution Notification**:

```
┌─────────────────────────────────────────────────────┐
│  Group Update                                      │
│                                                     │
│  Tom had to cancel his Aug 15 tour due to a      │
│  flight change.                                   │
│                                                     │
│  Your options:                                    │
│  • Continue as a group of 2 with Lisa            │
│    (20% discount still applies)                   │
│  • Private tour with Kem (full price)            │
│  • Re-match with a new group                     │
│                                                     │
│  [Keep Group of 2] [Go Private] [Re-match]       │
└─────────────────────────────────────────────────────┘
```

---

## 5. Key User Flows (Critical Paths)

### 5.1 First-Time Tourist to First Booking

**Happy Path**:

```
[1. Discovery]
Tourist searches "find local guide Chiang Mai"
  → Finds WanderLess via organic search
  → Visits landing page, sees "matched by who, not where"

[2. Activation]
Tourist downloads app / visits web
  → Creates account (Google SSO: 30 seconds)
  → Completes 5-slider interest declaration (3-5 min)
  → System generates feature vector

[3. First Match]
System runs matching engine
  → Tourist sees top 5 matches with scores
  → Tourist browses 2-3 profiles
  → Tourist taps "Request Match" on guide #1

[4. Guide Response]
Guide receives notification
  → Guide reviews tourist profile (94% match)
  → Guide accepts within 24h

[5. Payment]
Tourist receives confirmation
  → Tourist views booking details + price
  → Tourist enters payment (Stripe: 1 min)
  → Funds held in escrow

[6. Itinerary Planning]
Guide creates itinerary
  → AI suggests route based on tourist interests
  → Guide customizes / approves
  → Tourist reviews and approves (or requests changes)

[7. Tour Execution]
Day-of: notifications, guide contact, tour tracking
  → Tour completes, guide marks complete
  → Escrow released to guide (48h)

[8. Feedback]
Tourist receives rating prompt
  → Tourist submits 5-star rating + text review
  → Rating feeds back into matching model

Total time: 24-72 hours (guide response is the variable)
Total interactions: 8-12 app screens
Drop-off risk points: Slider completion (40% abandonment), payment (15% drop)
```

### 5.2 Repeat Tourist to Booking

**Flow**:

```
[1. Re-Open App]
Tourist opens WanderLess
  → System detects returning user
  → Greets by name, offers to reuse preferences

[2. Quick Re-Book]
"Welcome back! Kem is available Aug 15 again"
  → Tourist taps "Re-book Kem"
  → Confirms date + group size
  → Payment auto-filled from last time

[3. New City / New Guide]
"Traveling to Bangkok? Here are your matches"
  → System applies same interest vector to new city
  → New guide pool scored
  → Top matches displayed

Total time: 2-3 minutes
Conversion rate: 70%+ (prior trust established)
```

### 5.3 New Guide to First Match

**Flow**:

```
[1. Discovery]
Guide hears about WanderLess from hostel partner
  → Visits "become a guide" page
  → Sees value prop: better tourists, not just any tourists

[2. Application]
Guide submits application
  → Includes TAT license verification
  → Profile + specialties + bio
  → 48h review by WanderLess team

[3. Profile Activation]
Guide approved
  → Completes profile builder (10-15 min)
  → Sets availability calendar
  → Views "preview" of their profile as tourist sees it

[4. First Match Request]
Tourist requests match with guide
  → Guide receives push notification
  → Guide reviews tourist profile + compatibility
  → Guide accepts

[5. First Tour]
Guide collaborates on itinerary
  → Guide executes tour
  → Guide receives first payout
  → Guide receives first review

Time to first booking: 3-14 days (dependent on tourist demand)
Guide activation: 60% complete profile after approval
```

### 5.4 Guide to Business Partner Connection

**Flow**:

```
[1. Guide Initiates]
Guide visits Partner section in app
  → Searches for restaurant/shop they've worked with
  → Sends partnership invitation

[2. Partner Accepts]
Partner receives email/notification
  → Partner creates account / logs in
  → Reviews partnership terms (7.5% commission)
  → Accepts invitation

[3. Integration]
Partner appears in guide's itinerary builder
  → Guide can add partner to tourist itineraries
  → Visit tracking auto-enabled

[4. Value Realization]
Tourists visit partner via guide's itinerary
  → Guide records visit
  → Partner sees traffic in dashboard
  → Monthly commission settlement

Time to first visit: 7-21 days (dependent on guide's tour schedule)
```

---

## 6. Touchpoints and Channels

### 6.1 Mobile App Flows

**App Architecture**:

| Platform    | Technology              | Key Flows                 |
| ----------- | ----------------------- | ------------------------- |
| iOS         | React Native or Flutter | Full functionality        |
| Android     | React Native or Flutter | Full functionality        |
| Mobile web  | PWA                     | Discovery + basic booking |
| Desktop web | Responsive              | Full functionality        |

**App Navigation Structure**:

```
┌─────────────────────────────────────────────────────┐
│  [Logo]    [Search]           [Notifications] [Profile] │
└─────────────────────────────────────────────────────┘
         │
         ├── Discover (Home)
         │    ├── Top matches
         │    ├── Popular guides
         │    └── Group opportunities
         │
         ├── Search
         │    ├── By destination
         │    ├── By specialty
         │    └── By availability
         │
         ├── My Trips
         │    ├── Upcoming
         │    ├── Past
         │    └── Saved guides
         │
         ├── Messages
         │    ├── Guide conversations
         │    └── Group chats
         │
         └── Profile
              ├── Interests
              ├── Payment methods
              ├── Reviews given
              └── Settings
```

### 6.2 Communication Channels

**Channel Matrix**:

| Channel            | Tourist ↔ Guide      | Guide ↔ Platform | Partner ↔ Platform |
| ------------------ | -------------------- | ---------------- | ------------------ |
| In-app messaging   | Yes (auto-translate) | Yes              | Yes                |
| Push notifications | Yes                  | Yes              | Yes                |
| Email              | Booking updates      | Alerts           | Statements         |
| WhatsApp (opt-in)  | Urgent only          | —                | —                  |
| SMS                | —                    | —                | —                  |

**Translation Strategy**:

```
[Message sent in Thai by guide]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Original (Thai):                                  │
│  "วันนี้เราจะไปตลาดเช้านะ อย่าลืมใส่รองเท้าที่สะดวก"  │
│                                                     │
│  Translated (English):                             │
│  "Today we'll go to the morning market.            │
│   Remember to wear comfortable shoes."             │
│                                                     │
│  [Original] [Translate] [Reply]                    │
└─────────────────────────────────────────────────────┘
```

### 6.3 Payment Flows

**Tourist Payment Methods**:

| Method                 | Markets  | Processing Time | Fees             |
| ---------------------- | -------- | --------------- | ---------------- |
| Credit/Debit (Visa/MC) | Global   | Instant         | 2.9% + $0.30     |
| Apple Pay              | iOS      | Instant         | Included in 2.9% |
| Google Pay             | Android  | Instant         | Included in 2.9% |
| PromptPay QR           | Thailand | Instant         | 1.5%             |
| TrueMoney              | Thailand | Instant         | 1.5%             |

**Guide Payout Methods**:

| Method             | Markets  | Processing Time | Fees         |
| ------------------ | -------- | --------------- | ------------ |
| TrueMoney          | Thailand | 48 hours        | None         |
| Thai bank transfer | Thailand | 48 hours        | THB 30       |
| International wire | Global   | 3-5 days        | $15          |
| PayPal             | Global   | 24 hours        | 2.9% + $0.30 |

**Escrow Policy**:

| Stage                | Hold Status      | Release Trigger              |
| -------------------- | ---------------- | ---------------------------- |
| Booking confirmed    | Funds held       | —                            |
| 48h before tour      | Funds still held | —                            |
| Tour marked complete | Funds released   | Guide confirmation           |
| 24h after tour       | —                | Auto-release if guide silent |
| Cancellation         | Refund triggered | Tourist or guide cancel      |

### 6.4 Review Flows

**Tourist Reviews Guide**:

```
[Post-tour: 1-24 hour window]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Rate Your Tour with Kem                            │
│                                                     │
│  Overall experience: ★ ★ ★ ★ ☆                    │
│                                                     │
│  How well did Kem match your interests?            │
│  ★ ★ ★ ★ ★ (Perfect match)                        │
│                                                     │
│  Itinerary quality:                                │
│  ★ ★ ★ ★ ☆                                        │
│                                                     │
│  Communication:                                    │
│  ★ ★ ★ ★ ★                                         │
│                                                     │
│  What made this tour special?                     │
│  [The hidden food stalls — amazing!_____]         │
│                                                     │
│  [Submit Review]                                   │
└─────────────────────────────────────────────────────┘
```

**Guide Responds to Review**:

```
[Guide receives review notification]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Sarah left a review:                              │
│                                                     │
│  ★★★★★ — "Kem's food tour was the highlight      │
│  of our Thailand trip. The hidden food stalls     │
│  were incredible!"                                │
│                                                     │
│  [Write a Response]                              │
│                                                     │
│  Response preview:                                  │
│  "Thank you Sarah! It was a pleasure showing      │
│   you the real Chiang Mai food scene..."          │
│                                                     │
│  [Save and Publish]                               │
└─────────────────────────────────────────────────────┘
```

---

## 7. Edge Cases

### 7.1 No Matching Guides in Area

**Scenario**: Tourist searches in location with <3 active guides.

```
┌─────────────────────────────────────────────────────┐
│  Limited Matches Available in Pai                   │
│                                                     │
│  We're still building our guide network in Pai.    │
│                                                     │
│  Currently available: 2 guides                    │
│  (Minimum for group matching: 3)                  │
│                                                     │
│  Your options:                                     │
│  • View the 2 available guides (matching still    │
│    applies, but group formation unavailable)       │
│  • Expand search to Chiang Mai (45 min away)      │
│  • Join waitlist for Pai coverage               │
│                                                     │
│  [Show Available Guides] [Expand to Chiang Mai]    │
│  [Join Waitlist]                                  │
└─────────────────────────────────────────────────────┘
```

**System Response**:

- Guide matching runs with lower coverage threshold
- Group formation disabled
- Tourist notified of limitations
- Waitlist captured for market expansion priority

### 7.2 Guide Cancels

**Guide Cancellation Flow**:

```
[Guide cancels booking]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Booking Cancelled by Kem                          │
│                                                     │
│  Kem had an emergency and cannot guide on Aug 15. │
│  We're sorry for the inconvenience.               │
│                                                     │
│  Your options:                                     │
│  • Auto-match with similar guide (94% match)      │
│    [New guide: Noot T. — 91% match]              │
│    ⏱ Guide responds within 2 hours               │
│                                                     │
│  • Choose from top matches yourself               │
│  • Full refund (processed within 5-7 days)       │
│                                                     │
│  [Let Us Find a Replacement] [Choose Myself]     │
│  [Request Refund]                                  │
└─────────────────────────────────────────────────────┘
```

**Guide Cancellation Penalties**:

| Prior Notice       | Penalty                        |
| ------------------ | ------------------------------ |
| >72h before tour   | None (no penalty)              |
| 24-72h before tour | 1 warning                      |
| <24h before tour   | 2 warnings + review flag       |
| No-show            | 3 warnings + suspension review |

### 7.3 Weather Disruption

**Weather Alert Flow**:

```
[Weather API detects rain forecast]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  ⚠ Weather Alert for Aug 15                        │
│                                                     │
│  Heavy rain forecast (80% chance) for afternoon. │
│  Your current itinerary includes outdoor stops.     │
│                                                     │
│  Suggested alternatives:                           │
│  • Move temple visit to morning (before rain)     │
│  • Replace outdoor market with cooking class     │
│  • Add indoor alternatives (museum, craft shop)   │
│                                                     │
│  Kem will contact you to confirm changes.          │
│                                                     │
│  [Accept Suggestions] [Contact Kem] [Keep Original]│
└─────────────────────────────────────────────────────┘
```

**Rain Mitigation Strategies**:

| POI Type       | Indoor Alternative    | Decision Timing |
| -------------- | --------------------- | --------------- |
| Temple/Outdoor | Cooking class         | 24h before      |
| Market visit   | Mall/Artisan workshop | Same day        |
| Trekking       | Spa/Wellness          | 24h before      |

### 7.4 Tourist No-Show

**Guide No-Show Protocol**:

```
[Guide marks tourist no-show]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  Report No-Show                                     │
│                                                     │
│  Tourist didn't arrive within 30 min of pickup    │
│  time.                                             │
│                                                     │
│  Guide actions:                                    │
│  • Attempted to contact tourist: [Yes / No]      │
│  • Waited at pickup: [__] minutes                 │
│                                                     │
│  [Cancel Tour — Full Refund to Guide]             │
│  [Convert to Private Tour — Guide keeps booking]  │
│  [Contact Tourist First]                           │
└─────────────────────────────────────────────────────┘
```

**No-Show Resolution**:

| Scenario                            | Tourist Impact        | Guide Compensation |
| ----------------------------------- | --------------------- | ------------------ |
| Guide waited 30+ min, tried contact | Warning on account    | Full payout        |
| Guide didn't attempt contact        | No penalty to tourist | Guide penalty      |
| Miscommunication                    | Review case           | Partial payout     |

### 7.5 Group Size Not Met

**Group Formation Failure**:

```
┌─────────────────────────────────────────────────────┐
│  Group Tour Update                                  │
│                                                     │
│  We couldn't form a group of 3+ for your Aug 15  │
│  tour preference.                                  │
│                                                     │
│  Your options:                                     │
│  • Private tour (full price, your own schedule)   │
│  • Wait 48h for more compatible tourists         │
│  • Join a different group forming for same day    │
│                                                     │
│  Group discount (20%) not applicable for private. │
│                                                     │
│  [Go Private] [Wait for Group] [Find Another Date]│
└─────────────────────────────────────────────────────┘
```

**Re-Formation Window**:

- System attempts re-matching every 4 hours
- Tourist can opt out at any time and book private
- No penalty for group preference not fulfilled

### 7.6 Language Barrier Escalation

**Translation Failure Path**:

```
[Guide sends message — translation confidence < 60%]
         │
         ▼
┌─────────────────────────────────────────────────────┐
│  ⚠ Translation Uncertain                           │
│                                                     │
│  Kem wrote:                                        │
│  [Original Thai text]                              │
│                                                     │
│  Our translation:                                   │
│  "Please be ready at 8:45 AM. We will go to..."   │
│                                                     │
│  [Mark as Helpful] [Report Translation Error]      │
│                                                     │
│  Need more help? [Contact Support] [Call Guide]   │
└─────────────────────────────────────────────────────┘
```

**Escalation Path**:

1. **Level 1**: Tourist flags unclear message → Guide receives clarification prompt
2. **Level 2**: Tourist requests call → In-app voice translation (future)
3. **Level 3**: Human interpreter → Support team bridges communication

---

## 8. Information Architecture

### 8.1 Key Screens

**Tourist App Screens**:

| Screen       | Purpose              | Primary Actions                  |
| ------------ | -------------------- | -------------------------------- |
| Onboarding 1 | Welcome + value prop | Get started                      |
| Onboarding 2 | Account creation     | Sign in / sign up                |
| Onboarding 3 | Interest declaration | Adjust 5 sliders                 |
| Onboarding 4 | Travel context       | Enter destination + dates        |
| Home         | Dashboard            | Browse matches, view trips       |
| Match list   | Top 5 matches        | View profile, request match      |
| Profile      | Guide detail         | Read bio, reviews, availability  |
| Booking      | Confirm details      | Select date, confirm             |
| Payment      | Capture funds        | Enter card, pay                  |
| Messages     | Chat with guide      | Send messages, receive updates   |
| Itinerary    | Plan/approve         | View, edit, approve              |
| Tour active  | Day-of tracking      | View stops, contact guide        |
| Rating       | Post-tour feedback   | Submit stars + text              |
| Profile      | User settings        | Edit interests, payment, history |

**Guide App Screens**:

| Screen            | Purpose           | Primary Actions                     |
| ----------------- | ----------------- | ----------------------------------- |
| Dashboard         | Overview          | View pending requests, today's tour |
| Requests          | Incoming matches  | Accept, decline, view tourist       |
| Calendar          | Availability      | Block dates, sync external          |
| Itinerary builder | Plan tour         | Add stops, submit to tourist        |
| Active tour       | Day-of execution  | Mark complete, add stops            |
| Earnings          | Payout tracking   | View history, update payout method  |
| Analytics         | Performance       | View stats, tourist insights        |
| Partner           | Business partners | Invite, view visits                 |

**Partner Portal Screens**:

| Screen    | Purpose           | Primary Actions              |
| --------- | ----------------- | ---------------------------- |
| Dashboard | Overview          | View visits, revenue         |
| Visit log | Attribution       | Review individual visits     |
| Payments  | Settlement        | View statements, update bank |
| Guides    | Partner guides    | Invite, manage               |
| Insights  | Tourist analytics | View demographics            |
| Settings  | Profile           | Update details               |

### 8.2 Data Displayed at Each Step

**Tourist Decision Points**:

| Step         | Data Displayed                                | Source            | Update Frequency |
| ------------ | --------------------------------------------- | ----------------- | ---------------- |
| Match list   | Score, photo, rating, languages, bio          | Profile + ML      | Real-time        |
| Profile view | Full bio, reviews, specialties, match factors | Profile + reviews | Daily            |
| Availability | Dates guide can book                          | Calendar          | Real-time        |
| Itinerary    | Route, timing, POI details                    | Optimizer         | On change        |
| Booking      | Price, cancellation policy                    | Booking engine    | Static           |
| Payment      | Total, breakdown                              | Booking engine    | Static           |

**Guide Decision Points**:

| Step              | Data Displayed                                 | Source           | Update Frequency |
| ----------------- | ---------------------------------------------- | ---------------- | ---------------- |
| Request review    | Tourist profile, interests, compatibility      | ML + profile     | Real-time        |
| Itinerary builder | POI database, tourist preferences, constraints | POI DB + profile | Real-time        |
| Active tour       | Route, timing, next stop                       | Optimizer        | Real-time        |
| Settlement        | Gross, fees, net                               | Booking engine   | Post-tour        |

### 8.3 Decision Points for Users

**Tourist Decision Tree**:

```
Tourist opens app
         │
         ▼
    Any trips? ───No───→ Browse destinations
         │Yes                      │
         ▼                         ▼
    View upcoming trips       Interest declaration
         │                         │
         ▼                         ▼
    Any pending requests?    System generates matches
         │Yes                      │
         ▼                         ▼
    Wait for guide response  Browse + select guide
         │No/expired                │
         ▼                         ▼
    Request new guide        Request match
         │                         │
         ▼                         ▼
    Guide accepts? ─No──→ Browse alternatives
         │Yes                       │
         ▼                         ▼
    Confirm booking          Payment + escrow
         │                         │
         ▼                         ▼
    Plan itinerary ◄────────┘
         │
         ▼
    Tour executes
         │
         ▼
    Rate + review
```

**Guide Decision Tree**:

```
Guide opens app
         │
         ▼
    Any requests? ───No───→ View calendar
         │Yes                   │
         ▼                      ▼
    Review tourist profile  Update availability
         │                      │
         ▼                      ▼
    Accept/Decline ──Decline──→ Select reason
         │Yes                    │
         ▼                      ▼
    Build itinerary        Submit to tourist
         │                      │
         ▼                      ▼
    Tourist approves? ─No──→ Modify itinerary
         │Yes                    │
         ▼                      ▼
    Execute tour
         │
         ▼
    Mark complete + payout
```

---

## Appendix A: Data Schemas Summary

### Tourist Profile Schema

```python
tourist_profile = {
    'tourist_id': 'uuid',
    'interest_vector': 'float[64]',  # Compressed interest embedding
    'demographics': {
        'age_group': 'string',
        'nationality': 'string',
        'languages': ['string'],
    },
    'preferences': {
        'budget_tier': 'int 1-5',
        'pace_preference': 'int 1-5',
        'group_size_preference': 'int 1-5',
        'travel_style': 'string',
    },
    'travel_context': {
        'destinations': ['string'],
        'trip_dates': {'start': 'date', 'end': 'date'},
        'trip_type': 'string',
    },
    'account': {
        'email': 'string',
        'name': 'string',
        'created_at': 'timestamp',
        'last_active': 'timestamp',
    },
    'premium_status': 'bool',
}
```

### Guide Profile Schema

```python
guide_profile = {
    'guide_id': 'uuid',
    'specialty_vector': 'float[64]',  # Compressed specialty embedding
    'demographics': {
        'age_group': 'string',
        'nationality': 'string',
        'languages': [{'code': 'string', 'proficiency': 'string'}],
    },
    'guiding_style': {
        'pace': 'int 1-5',
        'group_size_tolerance': 'int 1-5',
        'communication_style': 'int 1-5',
    },
    'service_details': {
        'tour_types': [{
            'type': 'string',
            'duration_hours': 'int',
            'price': 'float',
            'max_group': 'int',
            'includes': ['string'],
        }],
    },
    'credentials': {
        'license_number': 'string',
        'license_verified': 'bool',
        'years_experience': 'int',
    },
    'reputation': {
        'rating_mean': 'float',
        'rating_count': 'int',
        'review_count': 'int',
    },
    'account': {
        'email': 'string',
        'name': 'string',
        'photo_url': 'string',
        'created_at': 'timestamp',
    },
    'premium_tier': 'string | null',  # null, 'professional', 'expert'
}
```

### Booking Schema

```python
booking = {
    'booking_id': 'uuid',
    'tourist_id': 'uuid',
    'guide_id': 'uuid',
    'destination': 'string',
    'tour_date': 'date',
    'duration_hours': 'float',
    'group_size': 'int',
    'gross_value': 'float',
    'platform_fee': 'float',
    'guide_payout': 'float',
    'payment_status': 'string',  # held_escrow | released | refunded
    'booking_status': 'string',  # pending | confirmed | in_progress | completed | cancelled
    'itinerary_id': 'uuid | null',
    'group_id': 'uuid | null',  # If part of group tour
    'created_at': 'timestamp',
    'confirmed_at': 'timestamp | null',
    'completed_at': 'timestamp | null',
}
```

### Group Schema

```python
tourist_group = {
    'group_id': 'uuid',
    'destination': 'string',
    'tour_date': 'date',
    'guide_id': 'uuid | null',  # Assigned guide
    'member_ids': ['uuid'],  # Tourist IDs
    'status': 'string',  # forming | confirmed | dissolved
    'silhouette_score': 'float',  # Group cohesion
    'created_at': 'timestamp',
}
```

---

## Appendix B: API Surface (High-Level)

### Tourist-Facing Endpoints

| Endpoint                                   | Method | Purpose                     |
| ------------------------------------------ | ------ | --------------------------- |
| `/api/v1/tourists/me`                      | GET    | Get current tourist profile |
| `/api/v1/tourists/me`                      | PATCH  | Update preferences          |
| `/api/v1/tourists/me/interest-vector`      | PUT    | Update interest sliders     |
| `/api/v1/tourists/{id}/matches`            | GET    | Get top N guide matches     |
| `/api/v1/tourists/{id}/matches/{guide_id}` | POST   | Request match with guide    |
| `/api/v1/tourists/me/bookings`             | GET    | List tourist's bookings     |
| `/api/v1/tourists/me/bookings/{id}`        | GET    | Booking details             |
| `/api/v1/tourists/me/bookings`             | POST   | Create booking              |
| `/api/v1/tourists/me/bookings/{id}/cancel` | POST   | Cancel booking              |
| `/api/v1/tourists/me/ratings`              | POST   | Submit tour rating          |
| `/api/v1/tourists/me/messages`             | GET    | List conversations          |

### Guide-Facing Endpoints

| Endpoint                                | Method   | Purpose                      |
| --------------------------------------- | -------- | ---------------------------- |
| `/api/v1/guides/me`                     | GET      | Get current guide profile    |
| `/api/v1/guides/me`                     | PATCH    | Update profile               |
| `/api/v1/guides/me/availability`        | GET/POST | Manage availability          |
| `/api/v1/guides/me/requests`            | GET      | List incoming match requests |
| `/api/v1/guides/me/requests/{id}`       | POST     | Accept/decline request       |
| `/api/v1/guides/me/itineraries`         | GET/POST | Manage itineraries           |
| `/api/v1/guides/me/tours/{id}/complete` | POST     | Mark tour complete           |
| `/api/v1/guides/me/earnings`            | GET      | View payout history          |
| `/api/v1/guides/me/partners`            | GET/POST | Manage partner connections   |

### Partner-Facing Endpoints

| Endpoint                                 | Method | Purpose                    |
| ---------------------------------------- | ------ | -------------------------- |
| `/api/v1/partners/me`                    | GET    | Get partner profile        |
| `/api/v1/partners/me`                    | PATCH  | Update profile             |
| `/api/v1/partners/me/visits`             | GET    | List attributed visits     |
| `/api/v1/partners/me/payments`           | GET    | View settlement statements |
| `/api/v1/partners/me/guides`             | GET    | List partner guides        |
| `/api/v1/partners/me/guides/{id}/invite` | POST   | Invite guide to partner    |

---

## Appendix C: Glossary

| Term                    | Definition                                                                   |
| ----------------------- | ---------------------------------------------------------------------------- |
| **Compatibility Score** | ML-calculated 0-100% match score between tourist and guide                   |
| **Content Score**       | Component of compatibility from interest vector similarity (40%)             |
| **Collab Score**        | Component from collaborative filtering on historical ratings (40%)           |
| **Context Score**       | Component from contextual features (availability, weather) (20%)             |
| **Feature Vector**      | 64-dimensional embedding representing tourist interests or guide specialties |
| **Silhouette Score**    | Cluster quality metric (-1 to 1) measuring cohesion within group             |
| **Escrow**              | Funds held by platform until tour completion, then released to guide         |
| **Match Request**       | Tourist's formal invitation to a specific guide for a specific date          |
| **Group Formation**     | K-Means clustering process that groups compatible tourists for shared tours  |
| **Itinerary Optimizer** | Constraint satisfaction solver that sequences POIs for maximum satisfaction  |

---

_Document Version: 1.0_
_Last Updated: 2026-04-26_
_Author: Analysis Specialist_
_Phase: 01 — Analysis_
