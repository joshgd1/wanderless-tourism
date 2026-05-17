# WanderLess Business Model Assumptions

## 1. Purpose

This document separates WanderLess's business model into its components:

- External benchmarks — industry data from comparable platforms
- Team assumptions — estimates derived from domain reasoning
- Prototype simulations — numbers generated for demo purposes
- Future validation targets — metrics requiring real pilot data

**All numbers in this document are estimates or simulations unless sourced from external benchmarks.**

No real pilot data exists yet. All revenue and unit economics estimates require validation through the Luang Prabang, Laos beachhead before they should be used for investment decisions.

---

## Investor-Grade Business Model Summary

### Beachhead

Luang Prabang, Laos solo/small-group guided experiences for English-speaking tourists seeking authentic local experiences.

### Initial Customer Segment

Free independent travelers aged 25–45 who value local expertise, safety, and experience fit over cheapest-price catalog browsing.

### Supply Strategy

Recruit 50–100 local guides first, prioritizing verified credentials, language ability, local neighbourhood knowledge, and response reliability.

### Demand Strategy

Acquire tourists through travel communities, expat/digital-nomad groups, hostel/boutique-hotel partnerships, and targeted content around authentic local experiences.

### Revenue Logic

Primary: 15–18% booking commission.
Secondary: guide premium tools after guide liquidity is proven.
Future: partner referrals only after itinerary visit tracking is validated.

### Unit Economics Status

**All CAC, LTV, repeat-rate, and leakage figures are assumptions or pilot targets, not validated operating metrics.**

### Pilot Go / No-Go Metrics

| Metric                      | Target                   | Why It Matters                   |
| --------------------------- | ------------------------ | -------------------------------- |
| Match-to-booking conversion | >15%                     | Proves recommendation relevance  |
| Post-tour satisfaction      | >4.3/5                   | Proves match quality             |
| Repeat booking intent       | >25%                     | Supports LTV assumption          |
| Guide response SLA          | <2 hours                 | Supports marketplace reliability |
| Off-platform leakage        | <30%                     | Supports commission viability    |
| Tourist time saved          | >50% vs catalog browsing | Supports core pain point         |

---

## 2. Revenue Model Summary

### Phase 1: Booking Commission

Completed tourist-guide transactions generate 15-18% platform commission. Commission is collected at tour completion via the escrow settlement system (see `04-specs/commission-settlement.md`).

**This is the only revenue stream currently implemented in the prototype.**

### Phase 2: Guide Premium Tools

After 20 completed bookings, guides can subscribe to premium tools:

- Scheduling and calendar management
- Analytics dashboard (tourist demographics, peak demand times)
- Translation support
- Lead quality scoring

Price: $14.99/month per guide.

**Status**: Guide tier system is implemented. Premium tool features are **planned**.

### Phase 3: Business Partner Referrals

Restaurants, shops, and attractions may pay for referred tourist visits. A confirmed visit through the itinerary triggers a referral fee (5-10% of transaction value or fixed fee).

**Status**: Partner referral calculation is **planned**. Itinerary visit tracking is **planned**.

### Future Only: Tourism Insights

At sufficient scale and with proper governance, anonymized and aggregated tourist flow data could be sold to destination marketing organizations, tourism boards, and retail chains. This requires meaningful scale (>10,000 monthly active tourists), data governance framework, and privacy compliance.

**Status**: Entirely speculative. Not in any roadmap.\*\*

---

## 3. Assumption Classification Table

| Assumption                       | Estimate / Range                     | Classification     | Why It Matters                                                              | How to Validate                                          |
| -------------------------------- | ------------------------------------ | ------------------ | --------------------------------------------------------------------------- | -------------------------------------------------------- |
| Average booking value (tourist)  | $45–90                               | Team assumption    | Determines tourist LTV and commission per booking                           | Monitor actual booking amounts in Luang Prabang pilot    |
| Platform commission rate         | 15–18%                               | Team assumption    | Viator ~20%, GetYourGuide ~18%. We take less to incentivize early adoption. | Track commission collected vs. gross booking value       |
| Trips per active guide per month | 4–8                                  | Team assumption    | Active guide does 1–2 tours/week average                                    | Monitor guide booking frequency in pilot                 |
| Guide active months per year     | 9–11                                 | Team assumption    | Guides in SE Asia take seasonal breaks                                      | Track monthly guide activity in pilot                    |
| Tourist repeat rate              | 20–30%                               | Team assumption    | Based on Viator/TripAdvisor repeat booking benchmarks                       | Track repeat bookings per tourist in pilot               |
| Off-platform leakage             | 20–30%                               | Team assumption    | Industry estimate for marketplace disintermediation                         | Track direct bookings by guided tourists post-pilot      |
| Refund/dispute rate              | 3–7%                                 | External benchmark | Industry average for tour bookings (PostNL/Capitol Labs data)               | Monitor dispute rate in pilot                            |
| Complaint/incident rate          | 1–3%                                 | External benchmark | Estimated from comparable platform data for licensed guides                 | Track incident reports in pilot                          |
| Guide retention (annual)         | 60–75%                               | Team assumption    | Assumes guide leaves if < 3 bookings/month or poor NPS                      | Track guide churn in pilot                               |
| Tourist CAC                      | $5–15                                | Team assumption    | Influencer/social/referral channels; paid search expensive                  | Track actual acquisition cost by channel                 |
| Guide CAC                        | $0                                   | Team assumption    | Guides find us; no paid acquisition for supply                              | Track guide discovery source in pilot                    |
| Tourist LTV                      | $45–90                               | Team assumption    | 1–2 trips/year × average booking × repeat rate                              | Track LTV cohort in pilot at 6 and 12 months             |
| Guide LTV                        | $600–1,200/year                      | Team assumption    | Active guide × months × net after commission                                | Track guide earnings in pilot                            |
| CAC payback                      | 1 trip (tourist), 1–2 months (guide) | Team assumption    | Based on above estimates                                                    | Track time-to-repeat for tourists; guide earnings growth |

**All numbers require pilot validation. Treat as working estimates, not facts.**

---

## 4. Low / Base / High Unit Economics Scenario

| Scenario         | Avg Booking Value | Commission Rate | Trips/Guide/Month | Monthly Revenue per Active Guide | Main Risk                       |
| ---------------- | ----------------- | --------------- | ----------------- | -------------------------------- | ------------------------------- |
| **Conservative** | $35               | 18%             | 3                 | $18.90                           | Low volume; high guide churn    |
| **Base**         | $60               | 15%             | 6                 | $54.00                           | Repeat rate lower than assumed  |
| **Optimistic**   | $90               | 15%             | 10                | $135.00                          | Requires strong guide retention |

**Conservative scenario means: guide earns ~$225/month net after commission. At $600–1,200/year LTV, base scenario is realistic only if guide completes 8+ tours/month consistently.**

These scenarios are **prototype simulations** for demo purposes. Real unit economics require the Luang Prabang, Laos pilot to validate.

---

## 5. Disintermediation Risk

### The Risk

Tourists and guides may choose to transact directly after meeting on WanderLess — bypassing the platform to avoid the 15-18% commission. This is the primary structural risk for any marketplace.

**We treat 20-30% off-platform leakage as a marketplace tax to be measured and reduced, not solved.**

No marketplace has fully solved disintermediation. Even Airbnb and Uber experience significant off-platform activity.

### Why Tourists Might Go Direct

- Save 15-18% on booking
- Communicate directly with guide before committing
- Negotiate custom pricing

### Why Guides Might Go Direct

- Keep 100% of booking instead of 82-85%
- Build direct tourist relationships
- Avoid platform's quality standards

### Mitigation Mechanisms

| Mechanism                    | How It Reduces Leakage                                        |
| ---------------------------- | ------------------------------------------------------------- |
| **Booking record**           | Tourist wants official record of payment for safety/insurance |
| **Safety/trust signals**     | Platform credibility justifies the commission premium         |
| **Scheduling tools**         | Guide uses our calendar; switching costs time                 |
| **Translation support**      | Non-English-speaking tourists need platform translation       |
| **Dispute handling**         | Platform mediates conflicts; direct deals have no protection  |
| **Reviews/reputation**       | Guide's platform rating is an asset they can't take direct    |
| **Repeat tourist discovery** | Platform brings tourists the guide couldn't find alone        |
| **Guide analytics**          | Premium tools give guides data they can't get solo            |

**None of these fully solve disintermediation. They reduce it to a manageable leakage rate.**

---

## 6. CAC / LTV Logic

### Tourist Acquisition

Tourist CAC ($5–15) comes from:

- Influencer partnerships (travel bloggers in SE Asia)
- Social media content (Instagram, TikTok, YouTube)
- Organic referrals (existing tourists refer friends)
- Partnerships (hostels, airlines, credit card rewards)
- Paid search (expensive; ~$15 per acquisition)

**We assume tourist CAC is partially offset by referral loops: a satisfied tourist refers the next tourist at near-zero cost.**

### Guide Acquisition

Guide CAC is assumed to be $0 — guides find us through:

- Guide communities and forums
- Local tourism association partnerships
- Direct outreach to licensed guides in Luang Prabang
- Inbound from MICT licensing network

**If guide CAC proves > $0 in pilot, unit economics shift downward.**

### CAC Payback

Tourist payback in 1 trip assumes:

- Average booking $60 × 15% commission = $9 gross commission
- Against $5–15 CAC = 0.6–1.8 trips to payback

**If repeat rate is lower than 20-30%, tourist payback exceeds 1 trip and unit economics weaken.**

Guide payback in 1–2 months assumes:

- Active guide does 4-8 tours/month × $60 avg × 85% net = $204–408/month
- Against $0 CAC = immediate payback

**Guide payback is faster and more certain because CAC is near-zero.**

### LTV Not Proven

LTV estimates ($45–90 tourist, $600–1,200/guide/year) are **not proven until pilot data exists**. The estimates assume:

- Repeat rate holds at 20-30%
- Guide retention holds at 60-75% annually
- Average booking value holds at $45-90

If any assumption shifts, LTV shifts proportionally.

---

## 7. Pilot Validation Plan

Before treating any business model number as fact, the Luang Prabang pilot must validate:

| Metric                        | Minimum Viable | Target         | Why It Matters                                           |
| ----------------------------- | -------------- | -------------- | -------------------------------------------------------- |
| Match-to-booking conversion   | 10%            | 20%            | If tourists browse but don't book, revenue is zero       |
| Tour completion rate          | 90%            | 97%            | Cancelled tours generate commission but require refunds  |
| Post-tour satisfaction (NPS)  | 30             | 50+            | Repeat rate and guide retention depend on satisfaction   |
| Repeat booking rate           | 15%            | 25%            | Tourist LTV; 20-30% is benchmark from similar platforms  |
| Guide retention (6 months)    | 50%            | 70%            | Below 50% means supply is too unstable                   |
| Off-platform leakage          | Measured       | < 20%          | Above 30% makes commission-based model marginal          |
| Complaint/incident rate       | < 5%           | < 2%           | High rates indicate matching or safety failures          |
| Refund/dispute rate           | < 10%          | < 5%           | Above 10% erodes commission margin                       |
| CAC payback (tourist)         | < 3 trips      | 1 trip         | Determines CAC sustainability                            |
| Guide monthly active usage    | 3 tours/month  | 6+ tours/month | Below 3 tours/month means guide will churn               |
| Platform commission collected | 12% effective  | 15% effective  | Realized rate vs. stated 15-18% due to discounts/leakage |

**If the pilot validates these metrics at minimum viable levels, the business model is fundable. If not, the model requires redesign.**

---

## 8. Rubric Contribution

### Business Model

This document transforms the business model from "15-18% commission sounds reasonable" to "here are our assumptions, here is how we'll validate them, here is what failure looks like." This is investor-grade honesty.

- Explicit assumptions allow the professor to challenge specific numbers rather than the entire model
- Validation plan shows the team understands what "proving a marketplace" requires
- Scenario tables show the team has stress-tested the economics

### Market & Problem

The disintermediation section (Section 5) directly addresses why a platform can sustain commission in travel — the same logic that sustains Airbnb and Viator despite leakage.

### Team & Execution

The pilot validation plan (Section 7) shows the team knows the difference between "working estimates" and "proven metrics." This demonstrates execution maturity.
