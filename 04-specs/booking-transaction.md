# Booking Transaction Specification

## Overview

The booking transaction encompasses the complete lifecycle from tourist request to tour completion, including payment escrow, guide confirmation, and review submission.

## Booking State Machine

```
┌─────────────┐
│   SEARCH    │ (Tourist browses/requests)
└──────┬──────┘
       │ submit_request
       ▼
┌─────────────┐
│  REQUESTED  │ (Guide receives request)
└──────┬──────┘
       │ guide_confirm OR guide_decline
       ▼
┌──────────────┐      ┌────────────┐
│  CONFIRMED   │──────▶│  DECLINED  │
└──────┬───────┘      └────────────┘
       │ tourist_confirm_payment
       ▼
┌─────────────┐
│   PAID      │ (Escrow held)
└──────┬──────┘
       │ tour_date_arrives
       ▼
┌───────────────┐
│ IN_PROGRESS  │ (Tour happening)
└───────┬──────┘
        │ guide_complete
        ▼
┌─────────────┐
│  COMPLETED  │ (Funds released)
└──────┬──────┘
       │ rating_submitted
       ▼
┌─────────────┐
│   RATED    │
└────────────┘

--- CANCELLATION PATHS ---

DECLINED ←──── REQUESTED (guide_decline OR timeout)
CANCELLED ←── CONFIRMED (tourist_cancel OR guide_cancel)
CANCELLED ←── PAID (tourist_cancel with policy penalties)
PARTIAL_REFUND ← PAID (guide_cancel with compensation)
```

## State Definitions

| State          | Description                                | Who Can Transition  |
| -------------- | ------------------------------------------ | ------------------- |
| REQUESTED      | Tourist submitted, awaiting guide response | Guide               |
| CONFIRMED      | Guide accepted, awaiting payment           | Tourist             |
| DECLINED       | Guide declined or timeout                  | System              |
| PAID           | Payment held in escrow                     | System (auto)       |
| IN_PROGRESS    | Tour is active                             | System (time-based) |
| COMPLETED      | Tour finished, funds released              | Guide               |
| RATED          | Tourist submitted review                   | Tourist             |
| CANCELLED      | Booking dissolved                          | Either party        |
| PARTIAL_REFUND | Guide cancelled, partial refund            | System              |

## Request Creation

### Tourist Request Payload

```python
booking_request = {
    guide_id: string,
    tourist_id: string,

    # Date & Time
    requested_date: date,
    requested_start_time: time,
    duration_hours: float,

    # Group
    group_size: int,
    group_members: tourist_id[],  # For group bookings

    # Preferences
    primary_interest: enum["food", "culture", "adventure", ...],
    special_requests: string[],  # Dietary, accessibility, etc.

    # Budget
    budget_range: {min: float, max: float},

    # Flexibility
    date_flexible: boolean,
    time_flexible: boolean,
}
```

### Request Validation

```python
def validate_booking_request(request):
    errors = []

    # Guide exists and active
    if not guide.active:
        errors.append("Guide is not currently available")

    # Guide has availability
    if not guide.is_available(request.date, request.start_time):
        errors.append("Guide not available at requested time")

    # Group size within guide's max
    if request.group_size > guide.max_group_size:
        errors.append(f"Group size exceeds guide max ({guide.max_group_size})")

    # Minimum notice
    hours_until_tour = (request.date - today).total_hours()
    if hours_until_tour < guide.min_booking_notice_hours:
        errors.append(f"Minimum {guide.min_booking_notice_hours}h notice required")

    # Budget alignment
    if request.budget_range.min < guide.average_tour_price * 0.5:
        errors.append("Budget below guide's typical pricing")

    return errors if errors else None
```

## Payment Flow

### Escrow Model

```
Tourist books → Payment captured → Held in escrow → Tour completes → Guide paid

Escrow Provider: Stripe Connect
Account Structure:
- Platform account: WanderLess
- Guide connected accounts: Individual guide Stripe accounts
```

### Payment Capture

```python
def process_payment(booking):
    # Calculate amounts
    total_amount = booking.calculated_price
    platform_commission = total_amount * PLATFORM_COMMISSION_RATE  # 15-18%
    guide_payout = total_amount - platform_commission

    # Capture payment
    payment = stripe.payment_intents.create(
        amount=int(total_amount * 100),  # Cents
        currency="thb",
        customer=tourist.stripe_customer_id,
        payment_method=booking.payment_method_id,
        confirm=True,
        capture_method="automatic",  # Immediate capture
        metadata={
            "booking_id": booking.id,
            "guide_id": booking.guide_id,
        }
    )

    # Hold in escrow (Stripe doesn't release until manual API call)
    return payment
```

### Commission Structure

```python
COMMISSION_RATES = {
    "free_tier": 0.18,      # 18% for guides on free tier
    "professional_tier": 0.15,  # 15% for professional/expert
}

# Business partner referral commission (deducted from guide payout)
PARTNER_REFERRAL_RATE = 0.07  # 7% to partner, from guide's 82-85%
```

### Guide Payout Release

```python
def release_guide_payout(booking):
    if booking.state != "COMPLETED":
        raise ValueError("Can only pay for completed bookings")

    guide_payout = calculate_guide_payout(booking)

    # Transfer to guide's connected account
    transfer = stripe.transfers.create(
        amount=int(guide_payout * 100),
        currency="thb",
        destination=booking.guide.stripe_account_id,
        transfer_group=booking.id,
        metadata={
            "booking_id": booking.id,
            "tourist_id": booking.tourist_id,
        }
    )

    # Record transaction
    Transaction.create(
        type="guide_payout",
        booking_id=booking.id,
        amount=guide_payout,
        stripe_transfer_id=transfer.id,
    )

    return transfer
```

## Cancellation Policies

### Guide Cancellation Policies

| Policy Type | Full Refund    | Partial Refund  | No Refund      |
| ----------- | -------------- | --------------- | -------------- |
| Flexible    | >24h before    | 12-24h before   | <12h before    |
| Moderate    | >72h before    | 24-72h before   | <24h before    |
| Strict      | >7 days before | 3-7 days before | <3 days before |

### Cancellation Logic

```python
def handle_cancellation(booking, cancelling_party):
    hours_until_tour = booking.hours_until_tour
    policy = booking.guide.cancellation_policy

    if cancelling_party == "tourist":
        refund = calculate_tourist_refund(booking, policy, hours_until_tour)
        # Partial refunds go back to tourist
        process_refund(booking, refund)

    elif cancelling_party == "guide":
        # Guide cancellation penalty
        penalty = calculate_guide_penalty(booking)
        # Penalty deducted from next guide payout
        apply_guide_penalty(booking.guide, penalty)

        # Tourist gets full refund
        process_full_refund(booking)

        # Notify tourist, offer alternative guides
        offer_alternative_guides(booking)
```

### Refund Calculation

```python
def calculate_tourist_refund(booking, policy, hours):
    total = booking.total_amount

    if policy == "flexible":
        if hours >= 24: return total
        if hours >= 12: return total * 0.5
        return 0

    elif policy == "moderate":
        if hours >= 72: return total
        if hours >= 24: return total * 0.5
        return 0

    elif policy == "strict":
        if hours >= 168: return total  # 7 days
        if hours >= 72: return total * 0.5  # 3 days
        return 0
```

## Group Booking

### Group Request Flow

```python
group_booking = {
    primary_booker_id: tourist_id,  # Who initiated
    invited_tourists: tourist_id[],  # Others in group
    total_group_size: int,

    # Group state
    invitations_sent: boolean,
    confirmations_received: {tourist_id: boolean},
    minimum_confirmed: 3,  # MIN_GROUP_SIZE
}
```

### Group Payment Handling

```python
def process_group_payment(group_booking):
    # Primary booker pays for entire group
    total_amount = group_booking.total_price

    # OR: Each member pays their share
    individual_amounts = group_booking.split_equally()

    # Each tourist pays their portion
    for tourist_id, amount in individual_amounts:
        process_individual_payment(tourist_id, amount)

    # All funds held in booking escrow
    return booking
```

## Tour Day Execution

### Check-In

```python
def tourist_checkin(booking):
    booking.tourist_checkin_time = now()

    if booking.tourist_checkin_time > booking.start_time + 30_minutes:
        booking.late_checkin = True
        notify_guide("Tourist is running late")

    return booking

def guide_checkin(booking):
    booking.guide_checkin_time = now()

    # Both checked in = tour can begin tracking
    if booking.tourist_checkin_time and booking.guide_checkin_time:
        booking.state = "IN_PROGRESS"
        start_tour_tracking(booking)

    return booking
```

### During Tour

```python
# Real-time tracking (optional for safety)
during_tour = {
    guide_location: gps_coordinates,
    tourist_location: gps_coordinates,  # If sharing
    current_stop: stop_id,
    next_stop: stop_id,
    elapsed_time: minutes,
    remaining_time: minutes,
    emergency_button_active: boolean,
}
```

### Tour Completion

```python
def guide_complete_tour(booking):
    if booking.state != "IN_PROGRESS":
        raise ValueError("Tour not in progress")

    booking.end_time = now()
    booking.state = "COMPLETED"

    # Release guide payout (async, ~2 business days)
    queue_guide_payout(booking)

    # Trigger satisfaction prediction feedback
    trigger_post_tour_signals(booking)

    # Send rating request to tourist
    send_rating_request(booking)

    return booking
```

## Booking Notifications

### Notification Triggers

```python
notification_events = {
    "booking_requested": ["guide"],
    "booking_confirmed": ["tourist", "guide"],
    "booking_declined": ["tourist"],
    "payment_received": ["tourist", "guide"],
    "reminder_24h": ["tourist", "guide"],
    "reminder_2h": ["tourist", "guide"],
    "tour_started": ["platform"],
    "tour_completed": ["tourist", "guide"],
    "rating_received": ["guide"],
    "booking_cancelled": ["tourist", "guide", "platform"],
    "refund_processed": ["tourist"],
}
```

## Edge Cases

### No-Show Handling

```python
NO_SHOW_WINDOW_MINUTES = 30

def check_no_show(booking):
    if booking.state == "CONFIRMED":
        tour_time = booking.start_time
        current_time = now()

        if current_time > tour_time + NO_SHOW_WINDOW_MINUTES:
            if not booking.tourist_checkin:
                # Tourist no-show
                handle_tourist_no_show(booking)

            if not booking.guide_checkin:
                # Guide no-show
                handle_guide_no_show(booking)
```

### Weather Disruption

```python
def handle_weather_disruption(booking, weather_alert):
    # Offer reschedule or partial refund
    if weather_alert.severity == "severe":
        # Automatic reschedule offer
        offer_reschedule(booking)

    elif weather_alert.severity == "moderate":
        # Guide can suggest alternative indoor stops
        suggest_indoor_alternatives(booking)
```

### Double Booking Prevention

```python
def check_guide_availability(guide_id, date, start_time, duration):
    # Check no overlapping confirmed bookings
    overlapping = Booking.objects.filter(
        guide_id=guide_id,
        date=date,
        state__in=["CONFIRMED", "PAID", "IN_PROGRESS"],
    ).exclude(
        end_time__lte=start_time,
        start_time__gte=end_time,
    )

    return not overlapping.exists()
```
