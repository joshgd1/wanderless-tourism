# Commission Settlement Specification

## 1. Purpose

Commission settlement is the engine that converts completed tours into platform revenue. Every completed booking triggers an automated calculation of the platform's cut, the guide's net payout, and any business partner referral fees. Accurate settlement enables the guide premium tier model, partner revenue sharing, and transparent financial reporting.

## 2. User Problem Solved

**Tourist**: Wants to know their payment was processed fairly — not overcharged, and refundable if the experience is cancelled.

**Guide**: Needs to understand exactly what the platform takes, when they get paid, and what affects their net earnings. Needs transparent commission reporting for tax and business records.

**Business Partner**: Needs reliable tracking of referred tourist visits so referral commissions are accurate and timely.

**Platform Operator**: Needs automated, auditable commission calculation so the business model doesn't require manual invoice reconciliation for every booking. Needs accurate financial reporting for investor transparency.

## 3. User Roles Affected

| Role              | Settlement Role                                    |
| ----------------- | -------------------------------------------------- |
| Tourist           | Pays booking amount; receives refund if applicable |
| Guide             | Receives net payout after commission deducted      |
| Business Partner  | Receives referral fee on qualified visits          |
| Platform Operator | Collects commission; manages financial operations  |

## 4. Core Workflow

### Commission Trigger

A completed booking (`COMPLETED` state) triggers settlement:

```
booking.completed_at = NOW()
gross_amount = booking.total_price  # amount tourist paid

# Platform commission
platform_commission_rate = booking.commission_rate  # 15-18% from booking config
platform_commission_amount = gross_amount * platform_commission_rate

# Guide payout
guide_payout_amount = gross_amount - platform_commission_amount

# Partner referral fee (if business partner included in itinerary)
if booking.has_partner_referral:
    partner_referral_rate = booking.partner_referral_rate  # 5-10%
    partner_referral_amount = gross_amount * partner_referral_rate
    # Partner is paid separately; does not reduce guide payout

# Settlement record created
settlement = {
    booking_id: booking.id,
    gross_amount,
    platform_commission_amount,
    guide_payout_amount,
    partner_referral_amount,
    settled_at: NOW(),
    settlement_status: PENDING
}
```

### Settlement States

| State      | Description                                   |
| ---------- | --------------------------------------------- |
| `PENDING`  | Tour completed; awaiting guide confirmation   |
| `APPROVED` | Guide confirmed payout amount                 |
| `PAID`     | Guide payout transferred (or queued)          |
| `DISPUTED` | Guide or partner challenged settlement amount |
| `ADJUSTED` | Settlement modified (partial refund, etc.)    |
| `PAID_OUT` | All parties received funds                    |

### Payout Schedule

- **Guide payout**: Initiated within 48 hours of tour completion confirmation.
- **Partner referral**: Paid monthly, contingent on minimum threshold (e.g., $50 SGD).
- **Platform commission**: Retained by platform; reconciled daily.

### Guide Premium Tier Impact

Higher-volume guides qualify for reduced commission rates:

| Guide Tier | Commission Rate | Threshold                         |
| ---------- | --------------- | --------------------------------- |
| `free`     | 18%             | Default (0-19 bookings)           |
| `pro`      | 15%             | 20+ completed bookings            |
| `expert`   | 12%             | 50+ completed bookings + NPS > 50 |

Commission rate is determined at booking time based on guide's current tier.

## 5. Data Inputs

| Field                        | Type     | Source                           | Prototype Status |
| ---------------------------- | -------- | -------------------------------- | ---------------- |
| `booking_id`                 | UUID     | Completed booking                | Implemented      |
| `gross_amount`               | Decimal  | Booking.total_price              | Implemented      |
| `platform_commission_rate`   | Decimal  | Guide tier config                | Implemented      |
| `platform_commission_amount` | Decimal  | Calculated                       | Implemented      |
| `guide_payout_amount`        | Decimal  | Calculated                       | Implemented      |
| `partner_id`                 | UUID     | Itinerary business stops         | Implemented      |
| `partner_referral_rate`      | Decimal  | Partner agreement                | Planned          |
| `partner_referral_amount`    | Decimal  | Calculated                       | Planned          |
| `settlement_status`          | enum     | Settlement state machine         | Implemented      |
| `settled_at`                 | datetime | Completion timestamp             | Implemented      |
| `payout_method`              | enum     | Guide preference (bank/e-wallet) | Planned          |
| `payout_reference`           | string   | Payment provider reference       | Planned          |
| `refund_amount`              | Decimal  | Cancellation policy applied      | Planned          |
| `refund_commission_reversal` | Decimal  | Proportional to refund           | Planned          |

## 6. Decision Logic

### Commission Rate Determination

```python
def get_commission_rate(guide) -> Decimal:
    if guide.tier == "expert" and guide.nps > 50:
        return Decimal("0.12")
    elif guide.completed_bookings >= 20:
        return Decimal("0.15")
    else:
        return Decimal("0.18")
```

### Settlement Calculation on Booking Completion

```python
def settle_booking(booking):
    guide = booking.guide
    rate = get_commission_rate(guide)
    gross = booking.total_price
    commission = gross * rate
    guide_net = gross - commission

    # Create settlement record
    settlement = Settlement(
        booking_id=booking.id,
        gross_amount=gross,
        platform_commission_amount=commission,
        guide_payout_amount=guide_net,
        settlement_status="PENDING",
        settled_at=datetime.utcnow()
    )

    # If itinerary includes partner stops, calculate referral
    for stop in booking.itinerary.stops:
        if stop.partner_id:
            partner = stop.partner
            referral = gross * partner.referral_rate
            settlement.partner_referral_amount += referral

    settlement.save()
    return settlement
```

### Refund-Adjusted Settlement

If a dispute results in a partial refund after payout:

```python
def adjust_settlement(settlement, refund_amount):
    # Proportional commission reversal
    refund_ratio = refund_amount / settlement.gross_amount
    commission_reversal = settlement.platform_commission_amount * refund_ratio
    guide_reversal = settlement.guide_payout_amount * refund_ratio

    settlement.platform_commission_amount -= commission_reversal
    settlement.guide_payout_amount -= guide_reversal
    settlement.refund_amount = refund_amount
    settlement.settlement_status = "ADJUSTED"

    # Queue recovery from guide if already paid
    if settlement.payout_status == "PAID_OUT":
        queue_guide_recovery(guide_reversal, settlement.guide_id)
```

## 7. Prototype Status

| Capability                    | Status          | Notes                                                       |
| ----------------------------- | --------------- | ----------------------------------------------------------- |
| Commission calculation        | **Implemented** | On booking completion; rate from guide tier                 |
| Guide payout calculation      | **Implemented** | `gross - commission`                                        |
| Settlement record creation    | **Implemented** | `Settlement` model; status tracking                         |
| Guide tier-based rates        | **Implemented** | 18%/15%/12% tiers; NPS threshold planned                    |
| Partner referral calculation  | **Planned**     | Itinerary partner stops tracked; referral amount calculated |
| Payout scheduling             | **Planned**     | 48-hour payout initiation                                   |
| Payout method (bank/e-wallet) | **Planned**     | Guide preference; Wise/PayNow integration                   |
| Refund commission reversal    | **Planned**     | Proportional reversal on partial refund                     |
| Dispute adjustment workflow   | **Planned**     | Ops dashboard; audit log                                    |
| NPS threshold enforcement     | **Planned**     | NPS calculation from post-tour ratings                      |
| Tax reporting (1099/IR8A)     | **Planned**     | Guide earning reports for tax compliance                    |
| Financial reconciliation      | **Planned**     | Daily escrow account reconciliation                         |

**Note**: Payout to guides does not occur in the prototype. The settlement calculation and record creation are demonstrated; actual fund transfer is a planned production feature.

## 8. Production Upgrade Path

- **Payment API**: Use Stripe Connect or equivalent for split payouts (platform + guide) in a single transaction.
- **Automated payouts**: Guide net paid via bank transfer (Wise), PayNow, or GrabPay within 48 hours.
- **Partner settlement**: Monthly batch payment to partners with itemized referral report.
- **Tax compliance**: Generate IR8A (Singapore) or equivalent for guide earnings above threshold.
- **Chargeback recovery**: If chargeback occurs after guide payout, recover from guide's next payout.
- **Audit trail**: Every settlement state change logged with actor, timestamp, and reason.
- **Financial reporting**: Daily/weekly/monthly commission reports for ops and investors.

## 9. Edge Cases

- **Guide tier changes mid-booking**: Commission rate is locked at booking time, not completion time. A guide who moves from `free` to `pro` between booking and completion is paid at the rate they had at booking.
- **Partner added to itinerary after booking**: Partner referral fee is calculated on the gross booking amount at time of inclusion. If added mid-tour, the referral is tracked on the stop visit, not the booking.
- **Multiple partners in one itinerary**: Each partner receives their own referral fee; total partner payout does not reduce guide payout.
- **Partial refund on disputed booking**: Commission is reversed proportionally. If 30% refund issued, 30% of commission is returned to escrow and 30% deducted from guide payout (if already paid, recovered from next payout).
- **Guide has insufficient balance for recovery**: If chargeback exceeds guide's pending payout, guide account is flagged; future payouts held until balance reconciled.
- **Partner goes inactive**: Unpaid referral fees remain payable for 90 days; after 90 days, fee reverts to platform.
- **Currency mismatch (tourist/guide/partner)**: Settlement calculated in booking currency; guide and partner payouts converted at tour completion date rate.

## 10. Risks and Mitigations

| Risk                                                              | Mitigation                                                                                                  |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Privacy**: Guide earnings exposed                               | Settlement records are private; only guide and ops can view; audit log for compliance                       |
| **Fraud**: Guide fakes completion                                 | Guide must mark complete from confirmed booking; tourist confirmation required; GPS/time evidence (planned) |
| **Trust**: Platform miscalculates commission                      | Settlement record is immutable after creation; disputes filed within 30 days                                |
| **Safety**: Guide disputes payout                                 | Ops review dashboard; guide can challenge within 30 days with evidence                                      |
| **Bias**: High-volume guides get better rates                     | Tier thresholds are published; NPS threshold applies equally                                                |
| **Operational**: Manual reconciliation error                      | Automated calculation with payment provider webhook; daily reconciliation catches drift                     |
| **Compliance**: Unlicensed money transmission                     | Use licensed payment provider for all transfers; platform never holds funds long-term                       |
| **Dispute abuse**: Tourist falsely disputes to recover commission | Completion requires guide confirmation; auto-confirm timeout prevents indefinite hold                       |

## 11. Rubric Contribution

### Market & Problem

Commission settlement makes the business model real and auditable. Investors want to see that 15-18% isn't just a number — it's a mechanically enforceable revenue line. Settlement records demonstrate this.

### Product & Demo

The guide tier system (18%/15%/12% commission) demonstrates how the business model incentivizes quality. Guides who complete more tours pay less commission — directly linking effort to reward. This is a compelling product flywheel.

### Business Model

Settlement is the core business model engine. Without automated settlement, the platform either relies on invoicing (leakage risk) or manual reconciliation (scale limit). Automated settlement enables the 15-18% take rate to actually be collected.

### Team & Execution

Documenting the full settlement logic — including refund adjustments, tier-based rates, and partner referral tracking — shows operational maturity. This is the kind of detail that separates a student project from a fundable business.

### AI/ML Depth

Guide tier (which determines commission rate) is influenced by ML signals: NPS from satisfaction prediction, booking completion rate from the data pipeline. The settlement layer is where ML quality signals translate into guide economic outcomes.
