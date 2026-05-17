# Payment and Escrow Specification

## 1. Purpose

WanderLess holds tourist payments in escrow during tour planning and execution, releasing funds to the guide upon completion. This creates trust for both parties: tourists aren't charged for incomplete tours; guides aren't left unpaid after delivering an experience. Escrow also enables the platform to collect commission before guide payout.

## 2. User Problem Solved

**Tourist**: Fears paying upfront for a guide they haven't met, risking a no-show or poor experience with no recourse. Escrow means their money is held safely until the tour is complete or the platform mediates a dispute.

**Guide**: Fears completing a tour and then being ghosted by the tourist, with no way to collect payment. Escrow means the tourist's funds are already held — the guide just needs to deliver.

**Business Partner**: Benefits from tourists who arrive with pre-booked itineraries, as they arrive as paying customers rather than browsers. Escrow enables tracking of referred visits for commission settlement.

**Platform Operator**: Escrow is the mechanism for collecting the platform's 15-18% commission before guide payout. Without escrow, commission collection relies on trust and invoicing — both prone to leakage.

## 3. User Roles Affected

| Role              | Payment Action                                    |
| ----------------- | ------------------------------------------------- |
| Tourist           | Deposits funds at booking; authorizes release     |
| Guide             | Receives payout after completion; subject to hold |
| Business Partner  | Receives referral commission on confirmed visits  |
| Platform Operator | Collects commission at release; handles disputes  |

## 4. Core Workflow

### Booking and Escrow Flow

```
Tourist browses → Tourist books → Tourist pays (funds held in escrow)
    ↓
Tour confirmed → Guide delivers tour → Guide marks complete
    ↓
Tourist confirms completion OR 72-hour auto-confirm → Funds released
    ↓
Platform commission deducted → Guide payout issued → Business partner referral credited (if applicable)
```

### Detailed Booking States

| State              | Tourist Action         | Guide Action           | Platform Action                            | Funds    |
| ------------------ | ---------------------- | ---------------------- | ------------------------------------------ | -------- |
| `PENDING_PAYMENT`  | Submitted booking req  | —                      | Guide notified of request                  | None     |
| `FUNDS_HELD`       | Paid; awaiting confirm | Confirm acceptance     | Escrow account holds funds                 | Tourist  |
| `CONFIRMED`        | —                      | Accepted booking       | Guide calendar updated                     | Escrow   |
| `IN_PROGRESS`      | —                      | Conducting tour        | Active booking flag                        | Escrow   |
| `PENDING_COMPLETE` | —                      | Marked complete        | Awaiting tourist confirmation              | Escrow   |
| `COMPLETED`        | Confirmed OR timeout   | —                      | Commission deducted; guide paid            | Released |
| `DISPUTED`         | Raised dispute         | Responds               | Ops review; partial/full refund            | Held     |
| `CANCELLED`        | Cancelled before start | Confirmed cancellation | Refund policy applied; commission reversed | Refunded |

### Cancellation and Refund Policy

| Cancellation Timing       | Refund to Tourist | Commission Retained |
| ------------------------- | ----------------- | ------------------- |
| > 72 hours before tour    | 100%              | 0%                  |
| 24-72 hours before tour   | 50%               | 50%                 |
| < 24 hours before tour    | 0% (no-show)      | 100%                |
| Guide cancels (any time)  | 100%              | 0%                  |
| Platform-initiated cancel | Case-by-case      | Case-by-case        |

### Commission Collection

At `COMPLETED` state:

```
gross_booking_value = booking_amount
platform_commission = gross_booking_value * commission_rate  # 15-18%
guide_payout = gross_booking_value - platform_commission
```

Commission is held by the platform. Guide receives `guide_payout` via bank transfer or e-wallet (planned).

## 5. Data Inputs

| Field                     | Type    | Source                     | Prototype Status |
| ------------------------- | ------- | -------------------------- | ---------------- |
| `booking_id`              | UUID    | Booking creation           | Implemented      |
| `tourist_id`              | UUID    | Auth layer                 | Implemented      |
| `guide_id`                | UUID    | Booking request            | Implemented      |
| `booking_amount`          | Decimal | Itinerary price + options  | Implemented      |
| `commission_rate`         | Decimal | Business config            | Implemented      |
| `commission_amount`       | Decimal | Calculated                 | Implemented      |
| `guide_payout_amount`     | Decimal | Calculated                 | Implemented      |
| `escrow_status`           | enum    | Booking state machine      | Implemented      |
| `partner_id`              | UUID    | Business partner (if any)  | Implemented      |
| `partner_referral_amount` | Decimal | Calculated                 | Planned          |
| `refund_amount`           | Decimal | Cancellation policy        | Planned          |
| `payment_method`          | enum    | Tourist payment instrument | Planned          |
| `payment_provider_txn`    | string  | Stripe/PayNow/TouchnGo ref | Planned          |

## 6. Decision Logic

### Escrow State Machine

Transitions are driven by events from tourist, guide, and platform:

```
PENDING_PAYMENT
  └── tourist pays → FUNDS_HELD

FUNDS_HELD
  ├── guide rejects → CANCELLED (auto-refund)
  └── guide accepts → CONFIRMED

CONFIRMED
  ├── guide marks complete → PENDING_COMPLETE
  └── tourist cancels (24-72h) → CANCELLED (50% refund)
  └── tourist cancels (>72h) → CANCELLED (100% refund)
  └── guide cancels → CANCELLED (100% refund)

PENDING_COMPLETE
  ├── tourist confirms → COMPLETED (commission + payout)
  └── 72h timeout → COMPLETED (commission + payout, auto-confirm)
  └── tourist disputes → DISPUTED

DISPUTED
  └── ops resolves → COMPLETED or CANCELLED
```

### Dispute Resolution Logic (Planned)

Disputes are manually reviewed by platform ops. Decision rules:

- **Tourist no-show**: Full refund to guide; tourist account flagged.
- **Guide no-show**: Full refund to tourist; guide completion rate decremented.
- **Quality dispute**: Partial refund negotiated; commission adjusted proportionally.
- **Safety incident**: Booking cancelled; full refund; incident report filed.

## 7. Prototype Status

| Capability                   | Status          | Notes                                                                 |
| ---------------------------- | --------------- | --------------------------------------------------------------------- |
| Booking state machine        | **Implemented** | `PENDING_PAYMENT` through `COMPLETED` states in backend               |
| Escrow state tracking        | **Implemented** | `escrow_status` field in booking model                                |
| Commission calculation       | **Implemented** | 15-18% rate stored in config; calculated at completion                |
| Guide payout calculation     | **Implemented** | `booking_amount - commission_amount`                                  |
| Auto-confirm (72h timeout)   | **Planned**     | Cron job to auto-confirm pending tours after 72h                      |
| Cancellation policy engine   | **Planned**     | Policy rules applied to refund amount                                 |
| Payment provider integration | **Planned**     | Stripe for card; PayNow for Singapore; local payment methods for Laos |
| Partner referral tracking    | **Planned**     | Itinerary visit tracking; commission settlement                       |
| Dispute workflow             | **Planned**     | Ops dashboard; manual resolution; audit log                           |
| E-wallet payout              | **Planned**     | Guide receives via Wise, PayNow, or e-wallet                          |
| Chargeback handling          | **Planned**     | Payment provider dispute process; guide notified                      |

**Note**: No actual payment processing occurs in the prototype. The booking flow demonstrates the state machine and commission calculation logic using simulated payment amounts.

## 8. Production Upgrade Path

- **Payment provider**: Integrate Stripe Connect or equivalent marketplace payment API that natively supports split payments (platform commission + guide payout).
- **Regional payment methods**: PayNow (Singapore), KIP (Laos), GCash (Philippines), DANA (Indonesia).
- **FX handling**: Multi-currency support with real-time conversion; guide payout in local currency.
- **PCI compliance**: Use payment provider's hosted fields; never store raw card details.
- **Escrow accounting**: Separate escrow trust account; reconcile daily with payment provider.
- **Audit trail**: Every state transition logged with timestamp, actor, and reason.
- **Tax handling**: Withholding tax calculation for guide payouts in applicable jurisdictions.

## 9. Edge Cases

- **Tourist pays but guide is unavailable**: Guide rejects within 24 hours; auto-refund issued.
- **Guide completes tour but tourist is unreachable**: 72-hour auto-confirm releases funds; platform contacts tourist for post-tour rating.
- **Multiple bookings for same time slot**: Guide can only confirm one; others auto-cancelled with full refund.
- **Currency mismatch**: Tourist pays in USD; guide payout in local currency (LAK for Laos). FX conversion at tour completion date.
- **Partial tour completion**: Guide shows 3 of 5 planned stops. Platform ops reviews and may issue partial refund.
- **Payment provider outage**: Booking can be initiated but payment cannot be processed; guide notified of delay.
- **Commission on refund**: If refund is issued, platform commission is proportionally reversed. No commission on funds that don't reach escrow.

## 10. Risks and Mitigations

| Risk                                                    | Mitigation                                                                                  |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| **Privacy**: Financial data                             | PCI-DSS compliance via payment provider; never store raw card data                          |
| **Fraud**: Fake booking to extract guide payout         | Booking amount held in escrow; guide completes tour before release; completion rate tracked |
| **Trust**: Guide disappears after payment               | 72-hour hold before guide can withdraw; guide payout via tracked bank account               |
| **Safety**: Tourist injured during tour                 | Incident flag in dispute workflow; insurance referral (planned); emergency contact in-app   |
| **Bias**: New guide pays same commission as established | Premium tier (planned) reduces commission for high-volume guides                            |
| **Operational**: Payment provider insolvency            | Funds held in segregated escrow account per regulatory requirements                         |
| **Compliance**: Money transmission licensing            | Use licensed payment provider; platform does not hold funds long-term                       |
| **Dispute abuse**: Tourist falsely claims no-show       | Guide GPS check-in or photo evidence requirement (planned)                                  |

## 11. Rubric Contribution

### Market & Problem

Payment escrow addresses the trust gap that prevents tourists from booking with unknown guides online. Without escrow, first-time transactions require either blind trust or awkward bank transfers. Escrow makes the first transaction viable.

### Product & Demo

The booking state machine (with escrow status) is demonstrated in the backend API. The commission calculation logic shows the business model is real, not theoretical. This bridges "working demo" to "marketplace with economics."

### Business Model

Escrow is the mechanism that makes 15-18% commission collection possible. Without escrow, the platform relies on post-tour invoicing — which has massive leakage risk. Escrow ensures the platform takes its cut before the guide gets paid.

### Team & Execution

Documenting the full payment flow — including disputes, refunds, and regional payment methods — shows the team understands what production requires beyond the prototype. This is the kind of detail that separates a class project from an investor-ready business plan.

### AI/ML Depth

Booking completion data feeds the collaborative filtering model (completed tours → rating tuples). Payment reliability signals could become part of the guide's trust profile. The payment layer provides the feedback loop that makes matching intelligence improve over time.
