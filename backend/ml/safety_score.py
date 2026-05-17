"""
Safety Score Engine — WanderLess Tourism

Rule-based ML scoring for trip plan safety assessment.
Computes 7 factors automatically from trip plan data and external signals,
then applies the weighted formula:

Score = 0.30·Area + 0.20·Route + 0.15·Time + 0.10·Transport
      + 0.10·Weather + 0.10·Venue + 0.05·TravellerFit

Each factor is scored 0–100. Thresholds:
  80–100: Safe  (green)
  60–79:  Caution (amber)
  <60:   Risky  (red)
"""

from __future__ import annotations

import logging
import math
from datetime import datetime, time
from typing import Any

logger = logging.getLogger("wanderless.ml.safety_score")

# Factor weights
_WEIGHTS = {
    "Area": 0.30,
    "Route": 0.20,
    "Time": 0.15,
    "Transport": 0.10,
    "Weather": 0.10,
    "Venue": 0.10,
    "TravellerFit": 0.05,
}

# Destination base safety index (0–100)
# In production this would come from an external safety API or database
_DESTINATION_SAFETY: dict[str, float] = {
    "singapore": 95,
    "kuala lumpur": 78,
    "bali": 80,
    "tokyo": 95,
    "seoul": 92,
    "hong kong": 88,
    "taipei": 90,
    "manila": 65,
    "ho chi minh city": 68,
    "hanoi": 70,
    "phnom penh": 62,
    "luang prabang": 82,
    "siem reap": 75,
    "penang": 81,
    "johor bahru": 65,
    "hoi an": 80,
}

# Transport mode risk profile (0–100, higher = safer)
_TRANSPORT_SAFETY: dict[str, float] = {
    "private_car": 90,
    "taxi": 80,
    "ride_hailing": 82,
    "bus": 72,
    "minibus": 68,
    "songthaew": 65,
    "motorcycle": 45,
    "bicycle": 55,
    "walking": 70,
    "ferry": 75,
    "speedboat": 60,
    "train": 88,
    "tram": 85,
    "metro": 90,
    "boat": 72,
    "van": 70,
    "limousine": 88,
}

# Venue type risk profile (0–100, higher = safer)
_VENUE_SAFETY: dict[str, float] = {
    "hotel": 90,
    "restaurant": 85,
    "temple": 88,
    "museum": 90,
    "gallery": 88,
    "market": 75,
    "night_market": 72,
    "shopping_mall": 85,
    "street_food": 78,
    "beach": 80,
    "park": 82,
    "waterfall": 70,
    "mountain": 65,
    "forest": 68,
    "cave": 62,
    "theme_park": 85,
    "zoo": 82,
    "aquarium": 85,
    "tower": 88,
    "observation_deck": 88,
    "rooftop": 78,
    "club": 65,
    "bar": 68,
    "spa": 85,
    "cooking_class": 85,
    "homestay": 80,
    "guesthouse": 78,
    "hostel": 75,
    "resort": 88,
    "national_park": 72,
    "wildlife sanctuary": 70,
    "volunteer_center": 82,
    "community_center": 82,
    "co_working": 85,
}

# Peak hour risk reduction (0–100 scale, time factor multiplier)
_PEAK_HOUR_RISK: list[tuple[int, int, float]] = [
    # (start_hour, end_hour, multiplier) — multiplier applied to base time score
    (22, 6, 0.70),   # Late night: 30% reduction
    (6, 9, 0.85),    # Early morning: 15% reduction
    (9, 12, 1.0),    # Morning: full score
    (12, 14, 0.95),  # Midday heat: slight reduction
    (14, 17, 1.0),   # Afternoon: full score
    (17, 20, 0.90),  # Evening rush: 10% reduction
    (20, 22, 0.95),  # Night: slight reduction
]

# Age group risk modifier (multiplier on traveller fit score)
_AGE_RISK_MODIFIER: dict[str, float] = {
    "18-25": 1.0,
    "26-35": 1.0,
    "36-45": 0.90,
    "46-55": 0.80,
    "56-65": 0.70,
    "65+": 0.60,
}


def _parse_time(time_str: str | None) -> time | None:
    """Parse time string like '09:00' into time object."""
    if not time_str:
        return None
    try:
        parts = time_str.split(":")
        return time(int(parts[0]), int(parts[1]))
    except Exception:
        return None


def _parse_date(date_str: str | None) -> datetime | None:
    """Parse date string like '2025-03-15' into datetime."""
    if not date_str:
        return None
    try:
        return datetime.strptime(date_str, "%Y-%m-%d")
    except Exception:
        return None


def _dest_safety_score(destination: str | None) -> float:
    """Factor: Area — destination base safety index."""
    if not destination:
        return 50.0  # Unknown destination → neutral
    dest_lower = destination.lower().strip()
    return _DESTINATION_SAFETY.get(dest_lower, 72.0)  # Default 72 for unknown


def _route_score(proposed_stops: list[dict] | None) -> float:
    """
    Factor: Route — assess route safety from proposed stops.

    Safer routes: fewer stops, moderate total duration,
    mix of known safe venue types, distributed geographically.
    """
    if not proposed_stops or len(proposed_stops) == 0:
        return 75.0  # No stops specified → moderate baseline

    n_stops = len(proposed_stops)

    # Too many stops in one day increases fatigue risk
    if n_stops > 8:
        stop_penalty = min(15.0, (n_stops - 8) * 2.5)
    else:
        stop_penalty = 0.0

    # Check venue type diversity (mixed venues = more robust)
    venue_types = set()
    total_duration = 0.0
    for stop in proposed_stops:
        venue = str(stop.get("venue_type", "")).lower().replace(" ", "_")
        if venue in _VENUE_SAFETY:
            venue_types.add(venue)
        duration = float(stop.get("duration_hours", 1.5))
        total_duration += duration

    # Venue type diversity bonus (up to +8)
    diversity_score = min(8.0, len(venue_types) * 1.5)

    # Duration fatigue factor
    if total_duration > 10:
        fatigue_penalty = min(12.0, (total_duration - 10) * 2)
    else:
        fatigue_penalty = 0.0

    base = 80.0
    return max(40.0, min(100.0, base - stop_penalty + diversity_score - fatigue_penalty))


def _time_score(tour_date_start: str | None, tour_date_end: str | None, proposed_stops: list[dict] | None) -> float:
    """
    Factor: Time — time-of-day and date safety.

    Assesses:
    - Time of day (peak hours vs. safe hours)
    - Season/weather considerations
    """
    score = 80.0  # Base score

    # Time-of-day risk from proposed stops
    if proposed_stops:
        hour_scores = []
        for stop in proposed_stops:
            stop_time = stop.get("start_time") or stop.get("time")
            if stop_time:
                t = _parse_time(stop_time)
                if t:
                    for start_h, end_h, mult in _PEAK_HOUR_RISK:
                        if start_h <= t.hour < end_h or (start_h > end_h and (t.hour >= start_h or t.hour < end_h)):
                            hour_scores.append(mult * 100)
                            break
        if hour_scores:
            avg_mult = sum(hour_scores) / len(hour_scores)
            score = avg_mult

    # Seasonal considerations from date
    if tour_date_start:
        dt = _parse_date(tour_date_start)
        if dt:
            month = dt.month
            # Monsoon season in SE Asia (May–October) slightly reduces score
            if month in (6, 7, 8, 9):
                score *= 0.95
            # Peak tourist season (Nov–Feb) is safest
            elif month in (11, 12, 1, 2):
                score = min(100.0, score * 1.05)

    return max(50.0, min(100.0, score))


def _transport_score(transport_mode: str | None, proposed_stops: list[dict] | None) -> float:
    """
    Factor: Transport — safety of primary transport mode
    and transport between stops.
    """
    if not transport_mode:
        # Infer from stops if no explicit mode
        if proposed_stops and len(proposed_stops) > 1:
            return 70.0  # Mixed transport between stops
        return 75.0  # Default moderate safety

    mode_lower = transport_mode.lower().replace(" ", "_").replace("-", "_")
    return _TRANSPORT_SAFETY.get(mode_lower, 72.0)


def _weather_score(tour_date_start: str | None, destination: str | None) -> float:
    """
    Factor: Weather — weather safety for destination and date.

    In production this would call a weather API.
    For now: rule-based seasonal approximation.
    """
    base = 80.0  # Baseline weather safety

    if tour_date_start:
        dt = _parse_date(tour_date_start)
        if dt:
            month = dt.month
            dest_lower = (destination or "").lower()

            # Monsoon season adjustments
            if dest_lower in ("bali", "luang prabang", "hoi an", "siem reap"):
                if month in (5, 6, 7, 8, 9, 10):
                    base = 65.0  # Monsoon season
                elif month in (11, 12, 1, 2, 3, 4):
                    base = 88.0  # Dry season

            elif dest_lower in ("singapore", "kuala lumpur", "penang", "johor bahru"):
                if month in (9, 10, 11):
                    base = 65.0  # Sumatra monsoon
                else:
                    base = 85.0

            elif dest_lower in ("tokyo", "seoul", "hong kong", "taipei"):
                if month in (6, 7, 8, 9):
                    base = 70.0  # Typhoon season
                else:
                    base = 90.0

    return max(50.0, min(100.0, base))


def _venue_score(proposed_stops: list[dict] | None) -> float:
    """
    Factor: Venue — average safety score of proposed stop venues.
    """
    if not proposed_stops or len(proposed_stops) == 0:
        return 78.0  # No stops → moderate baseline

    scores = []
    for stop in proposed_stops:
        venue = str(stop.get("venue_type", "")).lower().replace(" ", "_").replace("-", "_")
        score = _VENUE_SAFETY.get(venue, 75.0)
        scores.append(score)

    return sum(scores) / len(scores) if scores else 78.0


def _traveller_fit_score(
    tourist: dict | None,
    proposed_stops: list[dict] | None,
    duration_hours: float | None,
) -> float:
    """
    Factor: TravellerFit — how well the tourist's profile
    fits the trip demands.

    Checks: age group, pace preference vs. trip duration,
    adventure interest vs. activity intensity.
    """
    if not tourist:
        return 75.0  # Unknown tourist → moderate

    base = 80.0

    # Age-based adjustment
    age_group = str(tourist.get("age_group", "26-35"))
    age_mod = _AGE_RISK_MODIFIER.get(age_group, 1.0)
    base *= age_mod

    # Duration vs. pace preference
    pace_pref = float(tourist.get("pace_preference", 0.5))  # 0–1, high = fast pace
    duration = duration_hours or 4.0

    # Fast pace preference + very long trip = fatigue risk
    if pace_pref > 0.7 and duration > 8:
        base *= 0.90
    elif pace_pref < 0.3 and duration < 3:
        base *= 0.92  # Slow traveller + very short trip = rushed

    # Adventure interest vs. stop types
    adventure = float(tourist.get("adventure_interest", 0.5))
    if proposed_stops:
        adventure_stops = sum(
            1 for s in proposed_stops
            if str(s.get("venue_type", "")).lower() in
               ("mountain", "cave", "waterfall", "forest", "beach", "wildlife sanctuary")
        )
        if adventure < 0.4 and adventure_stops > 2:
            base *= 0.88  # Non-adventurous tourist with intense itinerary
        elif adventure > 0.7 and adventure_stops == 0:
            base *= 0.95  # Adventure seeker with no adventure stops

    return max(45.0, min(100.0, base))


def compute_safety_score(plan_data: dict[str, Any]) -> dict[str, Any]:
    """
    Compute safety score for a trip plan.

    Args:
        plan_data: dict with optional keys:
            - destination (str): destination name
            - tourist (dict): tourist profile with age_group, pace_preference,
                              adventure_interest, etc.
            - proposed_stops (list[dict]): list of stops, each with optional
              venue_type, duration_hours, start_time
            - tour_date_start (str): 'YYYY-MM-DD'
            - tour_date_end (str): 'YYYY-MM-DD'
            - duration_hours (float): total planned duration
            - transport_mode (str): primary transport e.g. 'taxi', 'bus'

    Returns:
        dict with:
            - total_score (float): weighted sum 0–100
            - label (str): 'Safe' | 'Caution' | 'Risky'
            - level (str): 'safe' | 'caution' | 'risky'
            - color (str): 'green' | 'amber' | 'red'
            - breakdown (dict): per-factor scores and contributions
            - recommendation (str): plain-language recommendation
    """
    tourist = plan_data.get("tourist", {})
    proposed_stops = plan_data.get("proposed_stops", [])
    destination = plan_data.get("destination")
    tour_date_start = plan_data.get("tour_date_start")
    tour_date_end = plan_data.get("tour_date_end")
    duration_hours = plan_data.get("duration_hours")
    transport_mode = plan_data.get("transport_mode")

    # Compute each factor (0–100)
    area = _dest_safety_score(destination)
    route = _route_score(proposed_stops)
    time_factor = _time_score(tour_date_start, tour_date_end, proposed_stops)
    transport = _transport_score(transport_mode, proposed_stops)
    weather = _weather_score(tour_date_start, destination)
    venue = _venue_score(proposed_stops)
    traveller_fit = _traveller_fit_score(tourist, proposed_stops, duration_hours)

    # Weighted sum
    total_score = (
        _WEIGHTS["Area"] * area
        + _WEIGHTS["Route"] * route
        + _WEIGHTS["Time"] * time_factor
        + _WEIGHTS["Transport"] * transport
        + _WEIGHTS["Weather"] * weather
        + _WEIGHTS["Venue"] * venue
        + _WEIGHTS["TravellerFit"] * traveller_fit
    )
    total_score = round(total_score, 1)

    # Determine label and color
    if total_score >= 80:
        label = "Safe"
        level = "safe"
        color = "green"
    elif total_score >= 60:
        label = "Caution"
        level = "caution"
        color = "amber"
    else:
        label = "Risky"
        level = "risky"
        color = "red"

    # Per-factor contributions (weight × score)
    breakdown = {
        "Area": {
            "score": round(area, 1),
            "weight": _WEIGHTS["Area"],
            "contribution": round(_WEIGHTS["Area"] * area, 2),
        },
        "Route": {
            "score": round(route, 1),
            "weight": _WEIGHTS["Route"],
            "contribution": round(_WEIGHTS["Route"] * route, 2),
        },
        "Time": {
            "score": round(time_factor, 1),
            "weight": _WEIGHTS["Time"],
            "contribution": round(_WEIGHTS["Time"] * time_factor, 2),
        },
        "Transport": {
            "score": round(transport, 1),
            "weight": _WEIGHTS["Transport"],
            "contribution": round(_WEIGHTS["Transport"] * transport, 2),
        },
        "Weather": {
            "score": round(weather, 1),
            "weight": _WEIGHTS["Weather"],
            "contribution": round(_WEIGHTS["Weather"] * weather, 2),
        },
        "Venue": {
            "score": round(venue, 1),
            "weight": _WEIGHTS["Venue"],
            "contribution": round(_WEIGHTS["Venue"] * venue, 2),
        },
        "TravellerFit": {
            "score": round(traveller_fit, 1),
            "weight": _WEIGHTS["TravellerFit"],
            "contribution": round(_WEIGHTS["TravellerFit"] * traveller_fit, 2),
        },
    }

    # Plain-language recommendation
    if level == "safe":
        recommendation = "Your plan looks good — safe to proceed with your trip."
    elif level == "caution":
        recommendation = "Consider reviewing your route and timing. Some improvements could make your trip safer."
    else:
        recommendation = "This plan has elevated risk. We recommend adjusting the itinerary or adding a guide for support."

    logger.info(
        "safety_score.computed",
        extra={
            "destination": destination,
            "total_score": total_score,
            "level": level,
        },
    )

    return {
        "total_score": total_score,
        "label": label,
        "level": level,
        "color": color,
        "breakdown": breakdown,
        "recommendation": recommendation,
    }
