# WanderLess Demo Kill List

**Purpose**: This document lists every screen, claim, and feature that must NOT be shown in the primary demo, and the safe alternative to use instead.

---

## Rule: When in doubt, use cURL.

A working cURL command is more reliable than a working UI. If a screen is uncertain, use the API response instead.

---

## Kill List

| Screen / Claim                  | Risk                                              | Demo Decision                      | Safe Alternative                             |
| ------------------------------- | ------------------------------------------------- | ---------------------------------- | -------------------------------------------- |
| Business registration flow      | Field clarity issue; not re-tested                | Do not show                        | Use tourist flow only                        |
| Business dashboard              | Placeholder-only data; no real content            | Do not show                        | Describe it as "future phase"                |
| Static notifications            | No backend connection; looks fake                 | Do not show                        | Skip notifications                           |
| Payment card / checkout mock    | No real payment; prototype state machine          | Do not show as real                | Say "booking request submitted, not charged" |
| XGBoost satisfaction prediction | Not wired to recommendation API                   | Do not show                        | Say "future ranking signal"                  |
| CP-SAT itinerary                | Not implemented                                   | Do not show                        | Show greedy + 2-opt output                   |
| Official licence verification   | Not integrated with MICT or any government system | Do not imply official verification | Say "credential surfacing"                   |
| 85%+ accuracy claim             | Not validated in production                       | Do not mention                     | "Target requiring real data"                 |
| $300B TAM                       | Overclaim                                         | Do not mention                     | Luang Prabang / Laos beachhead               |
| Weather-aware routing           | Not implemented                                   | Do not show                        | Say "production roadmap"                     |
| Admin routes                    | Require manual setup; not demo-stable             | Do not show                        | Skip admin entirely                          |
| Guide-side acceptance flow      | Secondary; may be unstable                        | Show only if pre-tested            | Tourist decision journey is primary          |
| Dynamic re-routing              | Not implemented                                   | Do not show                        | Static itinerary sequence only               |

---

## Prototype / Future Features (Say, Don't Show)

| Feature                    | What to Say                                                             | Don't Show                 |
| -------------------------- | ----------------------------------------------------------------------- | -------------------------- |
| XGBoost satisfaction model | "Architecture-stage prototype; not wired to live recommendation API"    | The screen or API response |
| CP-SAT solver              | "Described as future production upgrade; greedy + 2-opt is current"     | CP-SAT UI                  |
| Guide premium tools        | "Phase 2 revenue; after 20 bookings per guide"                          | Dashboard                  |
| Business partner referrals | "Phase 3 revenue; after itinerary visit tracking"                       | Partner screen             |
| Real licence verification  | "Credential surfacing; commercial deployment requires MICT integration" | Government database screen |

---

## Synthetic / Placeholder Screens (Label Clearly)

| Screen                              | How to Handle                                                         |
| ----------------------------------- | --------------------------------------------------------------------- |
| Any screen using seed data only     | Say "synthetic pilot data; real deployment needs live guide profiles" |
| Guide cards with placeholder images | Acknowledge "demo data"                                               |
| Dashboard with no real KPIs         | Do not show; say "analytics dashboard is future phase"                |

---

## Demo Kill List Quick Reference

**DO NOT SHOW**:

1. Business registration / dashboard
2. Payment flow
3. CP-SAT
4. XGBoost (unless wired)
5. Official licence verification
6. Any legacy market reference (Chiang Mai, Thailand, Bangkok, STB, TAT, THB)
7. Admin routes

**DO SAY** (for future features):

- "This is a future phase"
- "Architecture-stage prototype"
- "Credential surfacing, not government verification"
- "Greedy + 2-opt; CP-SAT is production upgrade"
