"""
Dynamic Pricing — WanderLess Tourism

Grab/Uber-style demand-based pricing for tour bookings.
Adjusts prices based on:
- Demand surge (time of day, day of week, holidays)
- Guide popularity (rating, experience, demand history)
- Location/destination popularity
- Seasonality (peak tourist seasons)
- Group size multipliers

All prices in THB. Base prices configurable via environment.
"""

from __future__ import annotations

import logging
import math
from datetime import datetime, timedelta
from typing import Optional

import numpy as np

logger = logging.getLogger("wanderless.ml.pricing")

# ─── Base tour price catalogue (THB) ───────────────────────────────────────────

BASE_PRICES: dict[str, float] = {
    "food": 1200.0,
    "culture": 1000.0,
    "adventure": 1800.0,
    "nature": 1500.0,
    "mixed": 1300.0,
    "nightlife": 900.0,
    "shopping": 800.0,
    "wellness": 1100.0,
}

# Default if interest not in catalogue
DEFAULT_BASE_PRICE = 1200.0

# ─── Demand multipliers ─────────────────────────────────────────────────────────

# Time-of-day surge (hour → multiplier), peak evening hours get surge
_HOURLY_SURGE: dict[int, float] = {
    6: 0.85, 7: 0.90, 8: 1.00, 9: 1.05,
    10: 1.10, 11: 1.15, 12: 1.10, 13: 1.05,
    14: 1.05, 15: 1.10, 16: 1.15, 17: 1.20,
    18: 1.35, 19: 1.50, 20: 1.55, 21: 1.50,
    22: 1.30, 23: 1.10, 0: 0.90, 1: 0.80,
    2: 0.75, 3: 0.75, 4: 0.80, 5: 0.80,
}

# Day-of-week multiplier (0=Monday, 6=Sunday)
_DOW_MULTIPLIER: dict[int, float] = {
    0: 1.00,  # Monday — standard
    1: 0.95,  # Tuesday — low demand
    2: 0.95,  # Wednesday — low demand
    3: 1.00,  # Thursday — building
    4: 1.20,  # Friday — weekend starts
    5: 1.35,  # Saturday — peak
    6: 1.30,  # Sunday — still high
}

# Thai / regional public holiday surcharge (list of "MM-DD" strings)
_HOLIDAY_SURGE = {
    "01-01": 1.40,  # New Year
    "04-06": 1.35,  # Chakri Memorial Day
    "04-13": 1.50,  # Songkran (Thai New Year)
    "04-14": 1.50,  # Songkran
    "04-15": 1.45,  # Songkran
    "05-01": 1.30,  # Labour Day
    "05-04": 1.30,  # Coronation Day
    "06-03": 1.30,  # Queen Sirikit's Birthday
    "07-22": 1.35,  # Asanha Bucha
    "07-23": 1.50,  # Khao Phansa (start of Buddhist Lent)
    "08-12": 1.40,  # Queen's Birthday
    "10-13": 1.35,  # King Chulalongkorn Day
    "12-05": 1.45,  # King's Birthday / National Day
    "12-10": 1.35,  # Constitution Day
    "12-31": 1.50,  # New Year's Eve
}

# Peak season multipliers (month → multiplier)
_PEAK_SEASON: dict[int, float] = {
    1: 1.20,   # January — peak international travel
    2: 1.25,   # February — Chinese New Year, peak
    3: 1.15,   # March — pre-Songkran
    4: 0.85,   # April — Songkran (some slowdown mid-month)
    5: 0.80,   # May — off-peak, very hot
    6: 0.90,   # June — school holidays start
    7: 1.00,   # July — summer break
    8: 1.10,   # August — peak summer
    9: 0.90,   # September — off-peak
    10: 1.15,  # October — cool season begins, festivals
    11: 1.30,  # November — peak season starts
    12: 1.40,  # December — peak holiday season
}

# ─── Guide popularity adjustments ──────────────────────────────────────────────

def _popularity_multiplier(
    guide_rating: float | None,
    guide_rating_count: int | None,
    booking_demand: float = 0.5,
) -> float:
    """
    Compute guide-specific premium based on rating and demand.
    Returns multiplier in [0.85, 1.60].
    """
    # Base rating contribution (3.0 → 1.0, 5.0 → 1.4)
    if guide_rating is not None:
        rating_mult = 0.6 + (guide_rating - 1.0) * 0.4  # 3.0→1.0, 4.0→1.2, 5.0→1.4
    else:
        rating_mult = 1.0  # no data, use baseline

    # Experience premium (more ratings = proven track record)
    if guide_rating_count is not None:
        if guide_rating_count >= 100:
            exp_mult = 1.12
        elif guide_rating_count >= 50:
            exp_mult = 1.08
        elif guide_rating_count >= 20:
            exp_mult = 1.04
        elif guide_rating_count >= 5:
            exp_mult = 1.00
        else:
            exp_mult = 0.98  # new guide, slight discount
    else:
        exp_mult = 1.0

    # Demand-based pricing: popular guides charge more during high demand
    if booking_demand > 0.75:
        demand_mult = 1.08  # surge pricing for high-demand guides
    elif booking_demand > 0.5:
        demand_mult = 1.03
    elif booking_demand < 0.25:
        demand_mult = 0.96  # discount to attract bookings
    else:
        demand_mult = 1.0

    combined = rating_mult * exp_mult * demand_mult
    return round(max(0.85, min(1.60, combined)), 3)


def _group_size_multiplier(group_size: int) -> float:
    """
    Group size pricing — per-person price adjusts based on group size.
    Solo travelers pay premium; larger groups get volume discount.
    """
    if group_size <= 1:
        return 1.30  # solo premium
    elif group_size == 2:
        return 1.10
    elif group_size == 3:
        return 1.00
    elif group_size == 4:
        return 0.95
    elif group_size <= 6:
        return 0.90
    else:
        return 0.85  # 7+ large group


def _hourly_surge(hour: int) -> float:
    """Get surge multiplier for a given hour of day."""
    return _HOURLY_SURGE.get(hour, 1.0)


def _dow_multiplier(date: datetime) -> float:
    """Get day-of-week multiplier."""
    dow = date.weekday()  # 0=Monday
    return _DOW_MULTIPLIER.get(dow, 1.0)


def _holiday_surge(date: datetime) -> float:
    """Get holiday surge multiplier if date is a known holiday."""
    key = f"{date.month:02d}-{date.day:02d}"
    return _HOLIDAY_SURGE.get(key, 1.0)


def _seasonal_multiplier(date: datetime) -> float:
    """Get seasonal multiplier based on month."""
    return _PEAK_SEASON.get(date.month, 1.0)


# ─── Main pricing engine ────────────────────────────────────────────────────────

DURATION_HOURS_BREAKPOINTS = [(2, 1.0), (4, 0.9), (6, 0.8), (8, 0.7)]


def _duration_discount(hours: float) -> float:
    """Longer tours get per-hour discount after the first tier."""
    discount = 1.0
    for threshold, mult in DURATION_HOURS_BREAKPOINTS:
        if hours > threshold:
            discount = mult
    return discount


def compute_dynamic_price(
    base_interest: str,
    duration_hours: float,
    group_size: int,
    tour_date: str | datetime | None = None,
    tour_hour: int | None = None,
    guide_rating: float | None = None,
    guide_rating_count: int | None = None,
    destination: str | None = None,
    booking_demand: float = 0.5,  # 0-1 guide booking frequency
) -> dict:
    """
    Compute the dynamic price for a tour booking.

    Args:
        base_interest: Primary interest category (food, culture, adventure, etc.)
        duration_hours: Tour duration in hours
        group_size: Number of travelers
        tour_date: Date of tour (ISO string or datetime). Defaults to today.
        tour_hour: Hour of tour start (0-23). If None, uses current hour.
        guide_rating: Guide's average rating (1-5)
        guide_rating_count: Number of ratings the guide has received
        destination: Destination city (currently unused but available for expansion)
        booking_demand: How in-demand this guide is (0=idle, 1=sold-out)

    Returns:
        dict with:
          base_price (THB),
          final_price (THB, after all adjustments),
          total_price (THB, final_price × group_size),
          breakdown (dict of multipliers with values),
          currency (str),
          per_person_price (THB),
          surge_level (low/normal/high/severe),
          expires_at (datetime when this price quote expires, 15 min)
    """
    # Parse date
    if tour_date is None:
        tour_dt = datetime.now()
    elif isinstance(tour_date, str):
        try:
            tour_dt = datetime.fromisoformat(tour_date.replace("Z", "+00:00"))
        except ValueError:
            tour_dt = datetime.now()
    else:
        tour_dt = tour_date

    hour = tour_hour if tour_hour is not None else tour_dt.hour

    # Base price from catalogue
    base_price = BASE_PRICES.get(base_interest.lower(), DEFAULT_BASE_PRICE)

    # 1. Duration discount
    duration_mult = _duration_discount(duration_hours)
    duration_price = base_price * duration_mult

    # 2. Time-of-day surge
    hourly_mult = _hourly_surge(hour)
    hourly_price = duration_price * hourly_mult

    # 3. Day-of-week
    dow_mult = _dow_multiplier(tour_dt)
    dow_price = hourly_price * dow_mult

    # 4. Holiday surcharge
    holiday_mult = _holiday_surge(tour_dt)
    holiday_price = dow_price * holiday_mult

    # 5. Seasonal
    seasonal_mult = _seasonal_multiplier(tour_dt)
    seasonal_price = holiday_price * seasonal_mult

    # 6. Guide popularity
    guide_mult = _popularity_multiplier(guide_rating, guide_rating_count, booking_demand)
    guide_price = seasonal_price * guide_mult

    # 7. Group size
    group_mult = _group_size_multiplier(group_size)
    per_person_price = guide_price * group_mult

    # Final price (rounded to nearest 10 THB for cleaner display)
    final_price = round(per_person_price / 10) * 10
    total_price = round(final_price * group_size / 10) * 10

    # Surge level classification
    combined_surge = hourly_mult * dow_mult * holiday_mult * seasonal_mult
    if combined_surge >= 1.8:
        surge_level = "severe"
    elif combined_surge >= 1.4:
        surge_level = "high"
    elif combined_surge >= 1.15:
        surge_level = "normal"
    else:
        surge_level = "low"

    # Price quote expires in 15 minutes
    expires_at = datetime.now() + timedelta(minutes=15)

    breakdown = {
        "base": round(base_price, 2),
        "duration_mult": round(duration_mult, 3),
        "hourly_mult": round(hourly_mult, 3),
        "dow_mult": round(dow_mult, 3),
        "holiday_mult": round(holiday_mult, 3),
        "seasonal_mult": round(seasonal_mult, 3),
        "guide_mult": round(guide_mult, 3),
        "group_mult": round(group_mult, 3),
    }

    logger.info(
        "pricing.computed",
        extra={
            "interest": base_interest,
            "group_size": group_size,
            "base_price": base_price,
            "final_per_person": final_price,
            "total_price": total_price,
            "surge_level": surge_level,
            "combined_surge": round(combined_surge, 3),
        },
    )

    return {
        "base_price": round(base_price, 2),
        "final_price": float(final_price),
        "total_price": float(total_price),
        "per_person_price": float(final_price),
        "currency": "THB",
        "breakdown": breakdown,
        "surge_level": surge_level,
        "expires_at": expires_at.isoformat(),
        "duration_hours": duration_hours,
        "group_size": group_size,
    }


def compute_booking_quote(
    base_interest: str,
    duration_hours: float,
    group_size: int,
    tour_date: str | None = None,
    tour_hour: int | None = None,
    guide_rating: float | None = None,
    guide_rating_count: int | None = None,
    destination: str | None = None,
    booking_demand: float = 0.5,
) -> dict:
    """
    Public-facing booking quote endpoint.
    Returns the full pricing breakdown and recommendation.
    """
    pricing = compute_dynamic_price(
        base_interest=base_interest,
        duration_hours=duration_hours,
        group_size=group_size,
        tour_date=tour_date,
        tour_hour=tour_hour,
        guide_rating=guide_rating,
        guide_rating_count=guide_rating_count,
        destination=destination,
        booking_demand=booking_demand,
    )

    # Price tier classification
    if pricing["final_price"] < 800:
        tier = "budget"
    elif pricing["final_price"] < 1500:
        tier = "mid"
    else:
        tier = "premium"

    pricing["tier"] = tier

    # Recommendation to tourist
    if pricing["surge_level"] in ("severe", "high"):
        pricing["recommendation"] = (
            f"Prices are currently {pricing['surge_level']} due to demand. "
            f"Booking on a weekday or earlier time could save you up to 30%."
        )
    elif pricing["group_size"] >= 4:
        pricing["recommendation"] = (
            f"Great group rate! Larger groups enjoy a volume discount of "
            f"{int((1 - pricing['breakdown']['group_mult']) * 100)}% per person."
        )
    else:
        pricing["recommendation"] = None

    return pricing
