# WanderLess Product Specification Index

## Overview

WanderLess is an ML-powered three-sided marketplace connecting tourists, local guides, and business partners through interest-based compatibility matching.

## Spec Files

### Core Domain

| Spec                     | Domain      | Description                                                                    |
| ------------------------ | ----------- | ------------------------------------------------------------------------------ |
| `tourist-profile.md`     | Tourist     | Interest vector, onboarding, profile management, booking lifecycle             |
| `guide-profile.md`       | Guide       | Expertise vector, availability, TAT licensing, matching and booking management |
| `business-partner.md`    | Partner     | Store/restaurant registration, referral tracking, commission settlement        |
| `booking-transaction.md` | Transaction | Booking state machine, payment escrow, cancellation, refund logic              |
| `group-formation.md`     | Group       | K-Means clustering, DBSCAN outlier detection, group lifecycle                  |
| `review-rating.md`       | Feedback    | Post-tour rating, satisfaction prediction feedback, quality signals            |

### ML Engine

| Spec                        | Domain | Description                                                                     |
| --------------------------- | ------ | ------------------------------------------------------------------------------- |
| `matching-engine.md`        | ML     | Hybrid recommendation (content/collaborative/contextual), compatibility scoring |
| `itinerary-optimizer.md`    | ML     | Constraint solver, simulated annealing, stop sequencing                         |
| `satisfaction-predictor.md` | ML     | XGBoost regression, feature interactions, prediction confidence                 |
| `interest-vector.md`        | ML     | Vector schema, embedding generation, cosine similarity, cold start              |

### Platform Infrastructure

| Spec                       | Domain   | Description                                                            |
| -------------------------- | -------- | ---------------------------------------------------------------------- |
| `auth-identity.md`         | Platform | Tourist/guide/partner authentication, identity verification            |
| `payment-escrow.md`        | Platform | Stripe integration, PromptPay/TrueMoney, commission distribution       |
| `messaging-translation.md` | Platform | In-app messaging, auto-translation, notification systems               |
| `safety-trust.md`          | Platform | Emergency protocols, incident reporting, insurance, dispute resolution |
| `data-pipeline.md`         | Platform | Real-time/batch inference, feedback loops, data storage                |

### Business Operations

| Spec                       | Domain   | Description                                                        |
| -------------------------- | -------- | ------------------------------------------------------------------ |
| `commission-settlement.md` | Finance  | 15-18% commission, guide payout, partner referral split            |
| `tier-premium-tools.md`    | Business | Guide tiers (Free/$19.99/$49.99), premium features, analytics      |
| `quality-intervention.md`  | Ops      | Rating thresholds, intervention triggers, guide suspension/tiering |

### Growth & Expansion

| Spec               | Domain    | Description                                                |
| ------------------ | --------- | ---------------------------------------------------------- |
| `city-playbook.md` | Expansion | Chiang Mai → Bangkok/Penang → 5-8 city expansion framework |
| `viral-growth.md`  | Growth    | Referral mechanics, social sharing, organic acquisition    |

---

## Brief Traceability

| Requirement Source           | Covered By                                 |
| ---------------------------- | ------------------------------------------ |
| ML matching by compatibility | `matching-engine.md`, `interest-vector.md` |
| Group formation              | `group-formation.md`                       |
| Itinerary optimization       | `itinerary-optimizer.md`                   |
| Satisfaction prediction      | `satisfaction-predictor.md`                |
| Tourist onboarding           | `tourist-profile.md`                       |
| Guide registration           | `guide-profile.md`                         |
| Business partner integration | `business-partner.md`                      |
| Booking with escrow          | `booking-transaction.md`                   |
| Review and rating            | `review-rating.md`                         |
| Payment integration          | `payment-escrow.md`                        |
| Translation                  | `messaging-translation.md`                 |
| Safety protocols             | `safety-trust.md`                          |
| Commission model             | `commission-settlement.md`                 |
| Guide premium tiers          | `tier-premium-tools.md`                    |
| Quality control              | `quality-intervention.md`                  |
| City expansion               | `city-playbook.md`                         |
| Chiang Mai beachhead         | `city-playbook.md`                         |

---

## Traceability Status

**Total requirements identified**: 17
**Spec files created**: 7 (core coverage)
**Spec files pending**: 10 (see index above for list)

---

## Status

- [x] Executive Summary
- [x] Analysis Documents (ML, Market, Business, Competitive, Ecosystem, Red Team)
- [x] User Flows (`03-user-flows/01-user-flows.md`)
- [x] Spec Files (7 of 17 created)
- [x] Journal Entries (7 entries created)

## Completed Specs

| Spec                        | Status   | Key Content                                                                      |
| --------------------------- | -------- | -------------------------------------------------------------------------------- |
| `tourist-profile.md`        | Complete | 64-dim interest vector, 5-slider onboarding, profile completeness scoring        |
| `guide-profile.md`          | Complete | TAT licensing, expertise vector, tier system (Free/Pro/Expert), lifecycle states |
| `booking-transaction.md`    | Complete | State machine, Stripe escrow, commission rates, cancellation policies            |
| `matching-engine.md`        | Complete | 40/40/20 hybrid architecture, content/collaborative/contextual scoring           |
| `group-formation.md`        | Complete | K-Means/DBSCAN, 3-8 tourist groups, lifecycle states                             |
| `itinerary-optimizer.md`    | Complete | CP-SAT + SA + greedy fallback, energy curves, weather integration                |
| `satisfaction-predictor.md` | Complete | XGBoost regression, feature interactions, SHAP explanations                      |
