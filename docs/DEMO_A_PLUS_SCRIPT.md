# WanderLess Demo A+ Script

**Purpose**: This document is the authoritative demo script for the MGMT655 presentation. It covers the full 10-minute story, required equipment, primary flow, backup cURL plan, and demo kill list.

---

## Demo Thesis

"WanderLess helps a traveller in Laos choose the right guide and experience — not by generating an itinerary with AI, but by matching who you are to who can show you around."

The demo focuses on the **tourist decision-support journey**.

---

## 1. Pre-Demo Equipment Checklist

- [ ] Backend running on port 8000 (`cd backend && uv run python main.py`)
- [ ] Flutter app installed or emulator ready
- [ ] Seed data loaded (tourist `tourist_test_1@test.com` / `test123`)
- [ ] Tourist account pre-logged or ready to register
- [ ] Backup laptop with cURL commands open if Flutter fails
- [ ] Laos destination pre-selected in seed data

---

## 2. Demo Flow (10 Minutes)

### Part 1: Problem (1.5 min)

**Say**: "Open Klook or Viator. Search 'Luang Prabang tours.' You get 40 listings. Sort by popularity. What do you actually know about the guide? Nothing. You know the price and the star rating. You don't know if this guide speaks your language at your pace, shares your interests, or has a track record that fits you.

This is catalog-first. It has three failures: time waste, guide invisibility, and compatibility gap.

WanderLess is compatibility-first. Let me show you."

---

### Part 2: Tourist Onboarding (1 min)

**Show**: Flutter app — new tourist registers or logs in.

**Say**: "This tourist enters five dimensions: food interest, culture interest, adventure interest, pace preference, and budget. These create a preference vector — a mathematical fingerprint of who this traveller is."

**Tap through**: Register → Enter name → Select 5 interest sliders → Confirm profile.

---

### Part 3: Guide Recommendation (2 min)

**Show**: Discover screen with top-5 ranked guides for Luang Prabang.

**Say**: "The ML engine scores all available guides against this traveller's preference vector. The top 5 ranked guides are shown with compatibility scores.

Notice: these are not sorted by popularity. They are sorted by who fits this traveller."

**Tap a guide card**: Show score breakdown:

- "88% food interest alignment"
- "Pace match: moderate"
- "Language: English spoken"
- "Completion rate: 97%"

**Say**: "Each score is explained. The tourist understands WHY this guide was recommended. Not a black box — an explained recommendation."

---

### Part 4: Group Formation (1 min)

**Show**: Group formation screen (if stable) or API response.

**Say**: "Solo travellers with compatible profiles are clustered into groups of 3–8 using K-Means clustering. DBSCAN handles outliers — if you don't fit a group, you're flagged as a solo candidate.

This solves the solo-traveler problem: find your people before you travel."

**Show**: Silhouette score as evidence of group coherence.

---

### Part 5: Itinerary Planning (1.5 min)

**Show**: Itinerary screen with stops for Luang Prabang.

**Say**: "Once a guide is selected, the system sequences the tour stops using a constrained optimizer: greedy construction + 2-opt local search.

It respects time windows, meal breaks, travel distances, and budget. Not an AI writing a travel essay — constrained optimization that produces a feasible, efficient route."

**Show**: Wat Xieng Thong → Mount Phousi → Luang Prabang Night Market → Kuang Si Waterfall — with times, travel between stops, and total duration.

---

### Part 6: Safety and Trust (1 min)

**Show**: Safety score for selected guide.

**Say**: "Before booking, the tourist sees a safety decision-support score. This is NOT a travel advisory. It is not automated blocking. It surfaces the signals: licence tier, completion rate, incident flags.

The tourist decides. We give them the information to decide well."

---

### Part 7: Pricing (30 sec)

**Show**: Pricing quote.

**Say**: "The pricing engine returns a dynamic quote based on guide tier, duration, group size, and destination. The commission is 15–18% — lower than Viator's ~20%. The value is match quality, not just transaction facilitation."

---

### Part 8: Close (1 min)

**Say**: "The compounding insight: more tours → more rating tuples → better collaborative filtering → better matches → higher satisfaction → more repeat bookings → more data.

We're starting in Luang Prabang to prove this at small scale. If the pilot validates — match-to-booking conversion above 15%, post-tour satisfaction above 4.3/5 — the playbook scales to Vientiane, Vang Vieng, and 5–8 Lao cities.

WanderLess: compatibility-first, not catalog-first."

---

## 3. Primary Demo Screens

| Screen               | Path                             | What to Show                                  |
| -------------------- | -------------------------------- | --------------------------------------------- |
| Tourist registration | `app/lib/features/auth/`         | New account creation                          |
| Interest onboarding  | `app/lib/features/onboarding/`   | 5 sliders → preference vector                 |
| Guide discover       | `app/lib/features/discover/`     | **Primary demo screen** — top-5 ranked guides |
| Guide detail         | `app/lib/features/guide_detail/` | Score breakdown, credentials                  |
| Group formation      | `app/lib/features/groups/`       | K-Means clusters, silhouette score            |
| Itinerary            | `app/lib/features/itinerary/`    | Stop sequence, times, total                   |
| Safety score         | `app/lib/features/discover/`     | Score + risk flags                            |

---

## 4. Demo Kill List

See `docs/DEMO_KILL_LIST.md` for the full list. Key screens to AVOID:

| Screen / Claim                  | Reason                                            |
| ------------------------------- | ------------------------------------------------- |
| Business registration flow      | Known broken; not re-tested                       |
| Business dashboard              | Placeholder data; looks fake                      |
| Static notifications            | Not connected; looks fake                         |
| Payment card flow               | No real payment; prototype state machine only     |
| XGBoost satisfaction prediction | Not wired to recommendation API                   |
| CP-SAT itinerary                | Not implemented; greedy + 2-opt is current        |
| Official licence verification   | Not integrated with MICT or any government system |
| Satisfaction score if not live  | Only show if endpoint confirmed working           |

---

## 5. Backup Demo — cURL Reference

If Flutter app fails, use these commands. Open this file on the backup laptop: `docs/DEMO_A_PLUS_SCRIPT.md`

### Health Check

```bash
curl http://localhost:8000/api/health
```

**Expected**: `{"status":"healthy"}`

### Login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"tourist_test_1@test.com","password":"test123"}'
```

**Expected**: `{"access_token":"...","token_type":"bearer"}`

### Guide Recommendations

```bash
curl http://localhost:8000/api/recommendations/T650C5838/guides \
  -H "Authorization: Bearer {token}"
```

**Expected**: Ranked list with `compatibility_score`, `content_score`, `collab_score`, `destination_boost`

### Safety Score (Laos guide)

```bash
curl -X POST http://localhost:8000/api/safety/score \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "plan_data": {
      "destination": "Luang Prabang",
      "tour_date_start": "2026-06-15T09:00:00",
      "tour_date_end": "2026-06-15T17:00:00",
      "transport_mode": "local_transport",
      "proposed_stops": [
        {"name": "Wat Xieng Thong", "venue_type": "temple", "duration_hours": 1.5},
        {"name": "Mount Phousi", "venue_type": "viewpoint", "duration_hours": 1.0},
        {"name": "Luang Prabang Night Market", "venue_type": "market", "duration_hours": 1.0},
        {"name": "Kuang Si Waterfall", "venue_type": "nature", "duration_hours": 2.0}
      ],
      "age_group": "26-35",
      "pace_preference": "moderate",
      "adventure_interest": 0.6
    }
  }'
```

### Pricing Quote

```bash
curl -X POST http://localhost:8000/api/pricing/quote \
  -H "Content-Type: application/json" \
  -d '{
    "interest": "culture",
    "duration_hours": 4,
    "group_size": 3,
    "tour_date": "2026-06-15",
    "tour_hour": 9,
    "guide_id": "G001",
    "destination": "Luang Prabang",
    "currency": "USD"
  }'
```

### Group Formation

```bash
curl -X POST http://localhost:8000/api/groups/form \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "destination": "Luang Prabang",
    "tourist_ids": ["T650C5838", "T650C5839", "T650C5840"],
    "min_group_size": 3,
    "max_group_size": 8
  }'
```

---

## 6. Presentation Machine Checklist

Before the presentation starts:

- [ ] Backend dependencies installed (`uv sync`)
- [ ] Seed data loaded
- [ ] Backend running on port 8000
- [ ] Flutter app points to correct API base URL (`http://localhost:8000`)
- [ ] Demo user credentials ready
- [ ] Backup cURL commands open on second device
- [ ] Laos destination set in seed data
- [ ] No legacy Thailand references anywhere in UI or API responses
- [ ] Figma or screenshot backup ready if Flutter has issues
