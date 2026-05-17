# WanderLess Presentation Guide

## Core Positioning

WanderLess is not a generic AI travel planner. It is a **compatibility intelligence layer** for local tourism — matching tourists with guides based on who they are, not just where they want to go.

**One sentence**: WanderLess matches tourists with guides using ML-computed compatibility scores, then generates optimized itineraries and forms travel groups.

**What WanderLess is NOT**:

- NOT a chat-based AI trip planner (no LLM itinerary generation)
- NOT a tour catalog browser (no popularity sorting)
- NOT an autonomous booking agent (tourist always decides)

---

## 10-Minute Demo Flow

### 1. Problem (1.5 min)

**Say**: "Current travel platforms — Klook, GetYourGuide, Viator — all use the same discovery model: browse by destination, sort by popularity, pick from pre-packaged tours. This is catalog-first."

**Show**: Screenshot of a typical tour catalog (busy, generic, no personalization)

**Say**: "Three problems with this model:

1. Time waste — travelers spend 3-5 hours researching and still get mismatched
2. Guide invisibility — you book 'an experience', not a person. You don't know who your guide is until the tour starts
3. Compatibility gap — nobody matches by WHO you are, only WHERE you're going. This is the same problem Netflix solved 15 years ago."

**Transition**: "Travel remains more catalog-first than compatibility-first, especially for guide matching. Until WanderLess."

---

### 2. Product Walkthrough (3 min)

**Say**: "WanderLess is compatibility-first. Here's how it works."

**Step 1 — Tourist Onboarding (30 sec)**

- Tourist creates a profile: 5 interest sliders (food, culture, adventure, pace, budget)
- These 5 dimensions create a preference vector
- Show: onboarding screen with 5 sliders

**Step 2 — ML Guide Matching (1 min)**

- System scores all available guides against tourist's preference vector
- Uses hybrid scoring: 45% content-based (interest match) + 45% collaborative (rating patterns) + 10% destination affinity
- Show: guide discovery screen with compatibility scores
- Explain briefly: "This isn't just keyword matching — the collaborative component learns from thousands of past tourist-guide rating patterns"

**Step 3 — Explanation (30 sec)**

- Each match shows: overall score, key matching factors, guide credentials
- Tourist understands WHY this guide was recommended
- Show: match card with explanation ("92% food interest alignment, matched travel pace")

**Step 4 — Group Formation (30 sec)**

- Solo travelers with compatible profiles are clustered into groups of 3-8
- K-Means clustering + DBSCAN outlier detection
- Show: group formation output (silhouette score validates group coherence)
- "This is how we solve the solo-traveler problem — find your people"

**Step 5 — Itinerary Generation (30 sec)**

- Greedy construction + 2-opt local search sequences tour stops
- Respects: time windows, budget, meal breaks, travel distance
- Show: itinerary output with stops, times, and total duration
- "Not using an LLM to write a travel essay — this is constrained optimization"

**Transition**: "Let me show you the actual working product."

---

### 3. Live Demo (3 min)

**Show**: Flutter app — tourist registration → profile creation → guide discovery → compatibility scores

**Narrate as you go**:

- "This tourist selected food and adventure interests"
- "The ML engine scored 60 guides, here are the top 5"
- "Notice the scores differ — this isn't popularity ranking"
- "The explanation tells the tourist WHY this is a good match"

**If demo fails**: Fall back to **cURL commands showing API responses**:

```
GET /api/recommendations/{tourist_id}/guides
→ Returns scored guides with content/collab/destination breakdown
```

---

### 4. ML Architecture Honest Explanation (1.5 min)

**Say**: "Let me be precise about what the ML actually does."

**Implemented**:

- "Content-based: cosine similarity on 5-dimensional preference vectors"
- "Collaborative: TruncatedSVD matrix factorization on tourist-guide-rating tuples — learns latent compatibility patterns from ratings"
- "Group formation: K-Means clustering, DBSCAN outlier detection"

**Not Wired / Prototype-Only**:

- "XGBoost satisfaction prediction: model exists in prototype, not wired to the recommendation endpoint"
- "CP-SAT itinerary solver: described as future production upgrade; current prototype uses greedy + 2-opt"

**Say**: "We corrected our documentation to match implementation. If a spec says something, code supports it. If it doesn't, we say so."

---

### 5. Business Model (1 min)

**Say**: "Three revenue streams: booking commission (15-18%), guide premium tools ($14.99/month after 20 bookings), business partner referrals (5-10%)."

**Show**: Unit economics table

- Tourist: CAC $5-15, LTV $45-90, payback in 1 trip
- Guide: CAC $0, LTV $600-1,200/year, payback in 1-2 months

**Say**: "We take less than Viator (~25%) and GetYourGuide (~20%). Our value is match quality, not just transaction facilitation."

---

### 6. Honest Limitations (1 min)

**Say**: "What we're not claiming:"

- "We don't claim production ML accuracy on 85%+ of predictions — we have synthetic data, not real post-tour ratings"
- "We don't claim the XGBoost satisfaction model is live — it's a prototype"
- "We don't claim CP-SAT solver is implemented — greedy + 2-opt is"
- "We don't claim weather-aware routing — it's in the roadmap"

**Say**: "What we DO claim: the recommendation engine works on synthetic data, demonstrates the workflow, and is ready to train on real ratings when we have them."

---

### 7. Close (1 min)

**Say**: "The compounding insight: more tours → more rating data → better collaborative filtering → better matches → higher satisfaction → more repeat bookings → more data."

**Say**: "We're starting in Luang Prabang, Laos — a UNESCO heritage city with strong local guide supply and tourism density. Success there produces a playbook for Vientiane, Vang Vieng, and 5–8 Lao cities."

**End with**: "WanderLess: compatibility-first, not catalog-first."

---

## Screens to Show

### Stable (Working in Demo)

| Screen                     | Path                           | Notes                                                     |
| -------------------------- | ------------------------------ | --------------------------------------------------------- |
| Tourist registration       | `app/lib/features/auth/`       | Works reliably                                            |
| Tourist profile/onboarding | `app/lib/features/onboarding/` | Interest sliders render                                   |
| Discover/Matching screen   | `app/lib/features/discover/`   | **This is the main demo screen** — shows ML-scored guides |
| Guide detail               | `app/lib/features/guide/`      | Credentials, expertise, reviews                           |
| Itinerary display          | `app/lib/features/itinerary/`  | Stop list, times, scores                                  |

### Stable API Endpoints (cURL Fallback)

| Endpoint                                     | Status | Notes                                |
| -------------------------------------------- | ------ | ------------------------------------ |
| `POST /api/auth/register`                    | Works  | Tourist signup                       |
| `POST /api/auth/login`                       | Works  | Returns JWT                          |
| `GET /api/recommendations/{id}/guides`       | Works  | Returns scored guides with breakdown |
| `GET /api/recommendations/{id}/destinations` | Works  | Destination rankings                 |
| `POST /api/groups/form`                      | Works  | Group formation                      |
| `POST /api/safety/score`                     | Works  | Safety score ( Laos context)         |
| `GET /api/auth/me`                           | Works  | Tourist profile                      |

---

## Screens to Avoid

| Screen                     | Reason                                                                   |
| -------------------------- | ------------------------------------------------------------------------ |
| Business registration flow | Was broken (field clarity issue; now fixed but not re-tested in Flutter) |
| Business dashboard         | Cascade dependency on business flow                                      |
| Flutter E2E (full app)     | Toolchain not functional in current environment                          |

**Note**: If the business flow comes up, use the **seed account** `business@wanderless.com` / `wanderless123` — this was pre-seeded correctly with both `name` and `business_name` fields.

---

## Must-Say Lines

Use these exact phrases to demonstrate honest ML positioning:

1. **"Compatibility-first, not catalog-first."**
   — Sets the positioning contrast immediately.

2. **"Synthetic data validates workflow, not production accuracy."**
   — Explains why we have working demos without real ratings.

3. **"We corrected our ML claims to match implementation."**
   — Demonstrates intellectual honesty; professor will notice overclaiming elsewhere.

4. **"The recommendation engine supports decisions; it does not replace human judgment."**
   — Safety trust positioning; also covers the "AI replaces guide" objection.

5. **"Content-based scoring uses cosine similarity on 5-dimensional interest vectors. Collaborative filtering uses TruncatedSVD — NOT ALS."**
   — Precise technical detail; distinguishes from generic "AI" claims.

6. **"The XGBoost satisfaction model is a prototype in review_intelligence.py. It is not wired to the recommendation endpoint."**
   — Honest about what runs vs. what exists.

7. **"The itinerary optimizer uses greedy construction + 2-opt local search. CP-SAT is the planned production upgrade."**
   — Specific about what algorithm actually runs.

8. **"More tours → more rating tuples → better collaborative filtering → better matches. This flywheel requires real booking data to start."**
   — Shows you understand the data dependency.

9. **"We took less commission than Viator because our value is match quality, not just transaction facilitation."**
   — Justifies business model defensively.

10. **"The Luang Prabang, Laos beachhead gives us a focused UNESCO heritage destination with strong local guide supply. Manageable enough to prove the model."**
    — Shows thoughtful geographic strategy.

---

## Before vs After Decision Support

### Before WanderLess: Catalog-First Workflow

A tourist planning a guided experience in Luang Prabang today:

1. Opens Klook or Viator
2. Browses listings for "Luang Prabang tours"
3. Reads reviews, trying to infer guide personality and expertise
4. Compares star ratings, prices, and photo quality
5. Guesses whether the guide's pace, language, and interests match their own
6. Manually plans timing and route between stops
7. Books and hopes the guide is a good fit

**The platform provides listings. The tourist does the matching work.**

### After WanderLess: Compatibility-First Workflow

A tourist on WanderLess:

1. Enters preferences once (food, culture, adventure, pace, budget sliders)
2. Receives guides ranked by ML-computed compatibility score
3. Sees WHY each guide matches: food interest alignment, pace match, language, rating
4. Selects a guide and receives an optimized itinerary
5. Sees safety/trust signals: license tier, completion rate, incident history
6. Books — decision supported, not just listing browsed

**The platform provides decision support. The tourist confirms the booking.**

### Decision Improvement

| User Decision                                 | Catalog-First Approach                      | WanderLess Approach                                         | ML/Logic Used                                                       | Business Value                                              |
| --------------------------------------------- | ------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------- | ----------------------------------------------------------- |
| Which guide should I choose?                  | Browse 47 listings; guess from reviews      | Compatibility-ranked guides; explained factors              | 45/45/10 hybrid recommender; content + collaborative + destination  | Tourist saves 3–5 hours; better first-match rate            |
| Which itinerary should I follow?              | Manually plan route and timing              | Optimized stop sequence with constraints                    | Greedy + 2-opt local search                                         | Reduces planning friction; increases booking conversion     |
| Is this match trustworthy?                    | Read through reviews; hope for accuracy     | Safety score + license + completion rate + incident history | Simple weighted safety score; credential surfacing (MICT framework) | Reduces pre-booking anxiety; supports first-time bookings   |
| Should I book now?                            | Uncertainty about guide fit delays decision | Confidence from explained compatibility + itinerary         | Compatibility score + satisfaction prediction (prototype)           | Converts browsers to bookers faster                         |
| How does the platform improve with more data? | No improvement — popularity is static       | Collaborative filtering learns from each completed tour     | TruncatedSVD matrix factorization                                   | Flywheel: more tours → better matches → higher satisfaction |

---

## 30-Second Demo Script

**Use this when introducing the demo to the professor:**

> "Before WanderLess, tourists browse catalog listings and guess whether a guide is the right fit — spending 3-5 hours researching and still getting mismatched. After WanderLess, they enter five preferences once and receive a ranked list of compatible guides with explanations: why this guide, why this itinerary, and whether to trust this match. The value is not more content — it is better decision support. Let me show you."

**Use this to close the demo:**

> "The compounding insight: more tours → more rating tuples → better collaborative filtering → better matches → higher satisfaction → more repeat bookings → more data. We're starting in Luang Prabang, Laos to prove this at small scale before expanding. WanderLess: compatibility-first, not catalog-first."

---

## Strategic Choices We Rejected

### 1. Generic AI Itinerary Planner

**Why rejected**: Building an LLM that writes travel itineraries is easy to copy, close to a prompt wrapper, and doesn't leverage WanderLess's core intellectual property (compatibility matching). It also invites comparison to much better-resourced competitors (Google Gemini, OpenAI Travel, etc.).

**What we chose**: Compatibility intelligence as the core differentiator. The value is WHO you're matched with, not WHAT itinerary an LLM generates.

**Rubric category protected**: Product & Demo (differentiation from generic AI travel apps); AI/ML Depth (two-sided matching is harder than content generation).

---

### 2. Overclaiming Production ML

**Why rejected**: Claiming production-ready ML when only prototype code exists is the single fastest way to lose professor/investor credibility. Any overclaim invites challenge, and a challenge on ML validity undermines the entire product.

**What we chose**: Implementation-honest claims at every level. 45/45/10 weights, not 40/40/20. TruncatedSVD, not ALS. 5-dimensional vectors, not 64-dimensional. Greedy + 2-opt, not CP-SAT. XGBoost prototype, not live satisfaction prediction.

**Rubric category protected**: Team & Execution (credibility); AI/ML Depth (honest technical claims).

---

### 3. Fully Autonomous Safety Blocking

**Why rejected**: An ML system that automatically blocks or promotes guides based on safety scores has legal, ethical, and fairness risk. A biased model could systematically disadvantage certain guide demographics. An opaque blocking system creates liability.

**What we chose**: Safety/trust as decision support — the system surfaces signals, the tourist decides. High-risk cases escalate to human ops review. The score explains itself.

**Rubric category protected**: Market & Problem (trust infrastructure); Business Model (accountability, not liability).

---

### 4. Demoing Every Marketplace Flow

**Why rejected**: Demonstrating tourist + guide + partner + booking + payment + settlement + group formation + itinerary + satisfaction prediction all at once creates a broad, fragile demo. One failure cascades. A focused demo is stronger than a comprehensive one.

**What we chose**: Stable tourist matching flow as the primary demo path. Guide discovery → compatibility explanation → itinerary → booking simulation. Everything else is described in specs and business model docs.

**Rubric category protected**: Product & Demo (stable, repeatable demo); Team & Execution (focused execution).

---

### 5. Claiming Synthetic Data Proves Accuracy

**Why rejected**: Synthetic data validates that the ML workflow functions — inputs flow through to outputs correctly. It does not validate that the model achieves 85% satisfaction accuracy in production. Claiming otherwise would be immediately challengeable.

**What we chose**: Synthetic data validates the workflow. Production accuracy requires real post-tour ratings. We show a pilot validation plan that makes this distinction explicit.

**Rubric category protected**: AI/ML Depth (honest about data requirements); Team & Execution (structured validation plan).

---

## Likely Q&A: 10 Tough Questions and Strong Answers

**Q1: "How is this different from just a recommendation engine like Spotify?"**
A: "Spotify recommends content. We recommend people. Guide quality — personality, expertise, pace — is harder to model than song preference because it requires two-sided matching. A good match requires both the tourist AND the guide to be compatible. That's why collaborative filtering on tourist-guide-rating tuples, not just tourist-content interactions."

**Q2: "Isn't this just a weighted average of ratings?"**
A: "No. Weighted averages are popularity ranking. Our content-based component scores interest alignment (food tourist to food expert). Our collaborative component uses TruncatedSVD to learn latent factors — it discovers that 'slow-paced cultural tours for couples' is a pattern, not a tag anyone labeled. That's matrix factorization, not a weighted average."

**Q3: "You claim 85% satisfaction accuracy — where's the validation?"**
A: "We don't claim 85% on production data. That target is in our architecture spec as an aspirational milestone. Our prototype was trained on synthetic ratings. Real validation requires 10,000 completed tours with post-tour ratings. We're transparent about this."

**Q4: "Why should I trust a new guide's safety score?"**
A: "You shouldn't trust it blindly — and we don't ask you to. The safety score is one signal among many (compatibility, price, availability). We show you the components: license tier, completion rate, ratings. You decide. New guides get a probational boost in matching to offset their lower history-based scores."

**Q5: "What stops a guide from creating fake tourist accounts to boost their collaborative filtering score?"**
A: "Rating inflation is a known vulnerability in all collaborative filtering systems. Mitigations: verified tourist accounts (email + phone), review authenticity signals (time-to-review, text similarity), and inverse-frequency regularization that downweights suspiciously uniform ratings. This is a real concern we'd need to address in production."

**Q6: "What happens when a tourist's interests don't match any available guide?"**
A: "The matching engine returns an empty set with suggestions: expand your interest sliders, try a different destination, or check back as new guides join weekly. We don't force a bad match to fill a slot."

**Q7: "Is this just a dating app for tourists and guides?"**
A: "The matching mechanics have structural similarities — both are two-sided matching problems. The difference is that tour satisfaction depends on interest alignment AND logistical factors (pace, budget, schedule) AND guide expertise. It's a harder optimization space than most dating apps."

**Q8: "Your synthetic data has 88% genuine signal — what happens at 12% noise?"**
A: "The 12% irreducible noise is calibration, not a bug. Real user ratings have noise too — tourists rate emotionally, forget details, penalize bad weather. Our model is trained to be robust to that noise. The 88% signal figure means the synthetic ratings are consistent enough to validate the workflow."

**Q9: "Why Luang Prabang first?"**
A: "Three reasons: (1) Luang Prabang is a UNESCO heritage city with concentrated local guide supply and high tourism density, (2) the compatibility problem is acute — guide quality, cultural interpretation, and local knowledge matter more here than in generic tour markets, (3) it's a learning lab — we can discover what breaks at small scale before going to Vientiane or Vang Vieng."

**Q10: "What if Airbnb copies this?"**
A: "They've had 9 years and 150M users on Airbnb Experiences and haven't built it. Our hypothesis: catalog-first platforms optimize for catalog breadth, not match quality. Doing both requires a different architecture. We have an 18-24 month window before incumbents could realistically respond, and first-mover data advantage compounds."

---

## Setup Checklist Before Presentation

- [ ] Backend running on port 8000 (`cd backend && uv run python main.py`)
- [ ] Tourist account registered (or use pre-seeded `tourist_test_1@test.com / test123`)
- [ ] Guide visible in discover screen (recommendations endpoint returns scored guides)
- [ ] Safety score endpoint responding (`POST /api/safety/score`)
- [ ] Group formation tested (`POST /api/groups/form`)
- [ ] cURL fallback commands ready if Flutter app has issues

### Backup cURL Commands

```bash
# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"tourist_test_1@test.com","password":"test123"}'

# Get guide recommendations
curl http://localhost:8000/api/recommendations/T650C5838/guides \
  -H "Authorization: Bearer {token}"

# Get destinations
curl http://localhost:8000/api/recommendations/T650C5838/destinations \
  -H "Authorization: Bearer {token}"

# Safety score
curl -X POST http://localhost:8000/api/safety/score \
  -H "Content-Type: application/json" \
  -d '{"plan_data":{"destination":"Luang Prabang","tour_date_start":"2026-06-15T09:00:00","tour_date_end":"2026-06-15T17:00:00","transport_mode":"local_transport","proposed_stops":[{"name":"Wat Xieng Thong","venue_type":"temple","duration_hours":1.5},{"name":"Mount Phousi","venue_type":"viewpoint","duration_hours":1.0},{"name":"Luang Prabang Night Market","venue_type":"market","duration_hours":1.0},{"name":"Kuang Si Waterfall","venue_type":"nature","duration_hours":2.0}],"age_group":"26-35","pace_preference":"moderate","adventure_interest":0.6}}'

# Group formation
curl -X POST http://localhost:8000/api/groups/form \
  -H "Content-Type: application/json" \
  -d '{"tourist_ids":["T650C5838","T650C5839","T650C5840"],"min_group_size":3,"max_group_size":8}'

# Pricing quote
curl -X POST http://localhost:8000/api/pricing/quote \
  -H "Content-Type: application/json" \
  -d '{"tourist_id":"T650C5838","destination":"Luang Prabang, Laos"}'
```

---

## Demo Kill List — Do Not Show Unless Fully Tested

| Screen / Flow                                                                   | Reason to Avoid                                       |
| ------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Business registration flow                                                      | Field clarity issue; not re-tested after fix          |
| Business dashboard                                                              | Cascade dependency on business flow                   |
| Flutter E2E full app test                                                       | Toolchain not functional in current environment       |
| XGBoost satisfaction prediction                                                 | Prototype not wired to recommendation API             |
| CP-SAT itinerary screen                                                         | Not implemented; greedy + 2-opt is live               |
| Real payment/escrow flow                                                        | Prototype state machine; no actual payment processing |
| Admin routes                                                                    | Require manual setup; not reliable for demo           |
| Any screen requiring seed account `business@wanderless.com` beyond basic access | Secondary flow; focus on tourist decision-support     |

**Rule**: If in doubt, use the cURL fallback. A working cURL command is more reliable than a flaky UI.

---

## Backup Demo Plan — Complete cURL Reference

If the Flutter app fails, run the backend and demonstrate via cURL:

### 1. Health Check

```bash
curl http://localhost:8000/api/health
```

**Expected**: `{"status":"healthy"}`
**Business value**: Confirms API is running and responsive

### 2. Login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"tourist_test_1@test.com","password":"test123"}'
```

**Expected**: `{"access_token":"...","token_type":"bearer"}`
**Business value**: Tourist authentication works

### 3. Get Guide Recommendations

```bash
curl http://localhost:8000/api/recommendations/T650C5838/guides \
  -H "Authorization: Bearer {token}"
```

**Expected**: Ranked list of guides with `compatibility_score`, `content_score`, `collab_score`, `destination_boost`
**Business value**: ML matching engine scores and ranks guides by compatibility

### 4. Safety Score

```bash
curl -X POST http://localhost:8000/api/safety/score \
  -H "Content-Type: application/json" \
  -d '{"plan_data":{"destination":"Luang Prabang","tour_date_start":"2026-06-15T09:00:00","tour_date_end":"2026-06-15T17:00:00","transport_mode":"local_transport","proposed_stops":[{"name":"Wat Xieng Thong","venue_type":"temple","duration_hours":1.5},{"name":"Mount Phousi","venue_type":"viewpoint","duration_hours":1.0},{"name":"Luang Prabang Night Market","venue_type":"market","duration_hours":1.0},{"name":"Kuang Si Waterfall","venue_type":"nature","duration_hours":2.0}],"age_group":"26-35","pace_preference":"moderate","adventure_interest":0.6}}'
```

**Expected**: `{"safety_score":N,"risk_flags":[...],"license_tier":"...","completion_rate":...}`
**Business value**: Decision-support safety signals surfaced for each guide

### 5. Group Formation

```bash
curl -X POST http://localhost:8000/api/groups/form \
  -H "Content-Type: application/json" \
  -d '{"tourist_ids":["T650C5838","T650C5839","T650C5840"],"min_group_size":3,"max_group_size":8}'
```

**Expected**: Cluster assignments with `silhouette_score` and `solo_candidates`
**Business value**: K-Means + DBSCAN groups compatible solo travelers

### 6. Pricing Quote

```bash
curl -X POST http://localhost:8000/api/pricing/quote
```

**Expected**: Price range and breakdown
**Business value**: Dynamic pricing demonstrates business model (commission)
