"""
Itinerary Optimization Engine — WanderLess Tourism

Constrained route optimization for travel itineraries.

MVP approach: greedy construction + 2-opt local search.
This produces high-quality itineraries for groups of up to 20 places
within a day, matching what OTAs call "smart ordering" — sufficient
for an MVP demo. CP-SAT / full Orienteering Problem solver can replace
this for production scale (see Slide 12 notes in the pitch deck).

Algorithm:
1. Score candidate places (weighted sum of preference fit, safety, rating,
   uniqueness, minus cost/travel-friction/crowd risk penalties)
2. Filter infeasible options (closed, unsafe timing, budget breach)
3. Greedy construction: pick highest-scoring feasible place, add to
   route respecting time windows and travel time, repeat
4. 2-opt local search: swap edges to reduce total travel time while
   respecting all constraints
"""

from __future__ import annotations

import logging
import math
from dataclasses import dataclass, field
from typing import Optional

import numpy as np

logger = logging.getLogger("wanderless.ml.itinerary")

# ─── Data types ────────────────────────────────────────────────────────────────


@dataclass
class Place:
    """A candidate place to visit within an itinerary."""

    id: str
    name: str
    lat: float
    lng: float
    category: str  # e.g. "temple", "restaurant", "museum"
    tags: list[str] = field(default_factory=list)

    # Opening hours in minutes-from-midnight (0–1439)
    open_time: int = 0      # e.g. 540 = 09:00
    close_time: int = 1440  # e.g. 1080 = 18:00

    visit_duration: int = 60  # minutes

    # Cost in local currency unit
    cost: float = 0.0

    # Crowd level 0–1 (0 = empty, 1 = packed)
    crowd_level: float = 0.5

    # Safety score 0–1 (1 = very safe)
    safety_score: float = 0.8

    # Average rating 1–5
    rating: float = 4.0

    # Whether this is a unique/exclusive place
    uniqueness: float = 0.5  # 0–1

    # Preference fit for the current traveller 0–1
    preference_fit: float = 0.5

    # Optional constraints
    is_unsafe_at_night: bool = False
    requires_booking: bool = False


@dataclass
class ItineraryRequest:
    """Parameters for building an itinerary."""

    # Traveller profile
    preference_vector: dict[str, float] = field(default_factory=dict)
    # e.g. {"food": 0.9, "culture": 0.7, "adventure": 0.2,
    #        "safety": 0.9, "budget": 0.4, "pace": 0.5}

    budget_max: float = 500.0

    start_location_lat: float = 0.0
    start_location_lng: float = 0.0

    day_start_minute: int = 540  # 09:00
    day_end_minute: int = 1320   # 22:00

    # Meal break windows (minutes from midnight)
    lunch_window_start: int = 720   # 12:00
    lunch_window_end: int = 840     # 14:00
    dinner_window_start: int = 1080  # 18:00
    dinner_window_end: int = 1260    # 21:00

    meal_duration: int = 60  # minutes

    # Weights for scoring (sum not required to be 1)
    w_preference: float = 1.5
    w_safety: float = 1.5
    w_rating: float = 1.0
    w_uniqueness: float = 0.5
    w_cost_penalty: float = 0.5   # higher = more cost-averse
    w_crowd_penalty: float = 1.0  # higher = more crowd-averse


@dataclass
class ItineraryStop:
    """A place in the final route."""

    place: Place
    arrival_minute: int
    departure_minute: int
    travel_from_prev_minutes: int = 0
    score: float = 0.0


@dataclass
class Itinerary:
    """Optimized day itinerary."""

    stops: list[ItineraryStop]
    total_cost: float
    total_travel_minutes: int
    safety_score_avg: float
    preference_score_avg: float
    crowd_risk_avg: float

    def to_display(self) -> dict:
        """Format for API response and Flutter display."""
        rows = []
        for stop in self.stops:
            h, m = divmod(stop.arrival_minute, 60)
            dep_h, dep_m = divmod(stop.departure_minute, 60)
            rows.append({
                "time": f"{h:02d}:{m:02d}",
                "departure": f"{dep_h:02d}:{dep_m:02d}",
                "name": stop.place.name,
                "category": stop.place.category,
                "duration_minutes": stop.place.visit_duration,
                "cost": stop.place.cost,
                "safety": stop.place.safety_score,
                "rating": stop.place.rating,
                "crowd_level": stop.place.crowd_level,
                "travel_from_prev_min": stop.travel_from_prev_minutes,
            })

        # Summary metrics
        total_minutes = 0
        if self.stops:
            last = self.stops[-1]
            total_minutes = (last.departure_minute - self.stops[0].arrival_minute)

        return {
            "rows": rows,
            "summary": {
                "n_stops": len(self.stops),
                "total_cost": self.total_cost,
                "total_travel_min": self.total_travel_minutes,
                "total_time_min": total_minutes,
                "safety_score": round(self.safety_score_avg, 2),
                "preference_score": round(self.preference_score_avg, 2),
                "crowd_risk": round(self.crowd_risk_avg, 2),
            }
        }


# ─── Haversine distance ────────────────────────────────────────────────────────

def _haversine_minutes(lat1: float, lng1: float, lat2: float, lng2: float) -> int:
    """Approximate travel time in minutes between two lat/lng points.

    Uses haversine great-circle distance and assumes average city travel
    speed of 20 km/h (walking + road routing overhead).
    """
    R = 6371.0  # Earth radius km
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    dist_km = R * c
    # 20 km/h city average → minutes
    return max(1, int(round(dist_km / 20.0 * 60)))


# ─── Hard constraint filters ───────────────────────────────────────────────────

def _apply_hard_filters(
    places: list[Place],
    request: ItineraryRequest,
    current_minute: int,
) -> list[Place]:
    """Remove places that violate hard constraints at current time."""
    feasible = []
    for p in places:
        # Check if place is open for enough duration at current time
        if current_minute < p.open_time or current_minute + p.visit_duration > p.close_time:
            continue
        # Budget check
        if p.cost > request.budget_max:
            continue
        # Night-unsafe check
        end_of_visit = current_minute + p.visit_duration
        if p.is_unsafe_at_night and end_of_visit > 1260:  # after 21:00
            continue
        # Don't add meal breaks inside lunch/dinner windows — handled in builder
        feasible.append(p)
    return feasible


# ─── Scoring ─────────────────────────────────────────────────────────────────

def _score_place(place: Place, request: ItineraryRequest) -> float:
    """Compute composite score for a place given request preferences."""
    w = request

    preference = place.preference_fit
    safety = place.safety_score
    rating_norm = (place.rating - 1) / 4.0  # normalize 1–5 → 0–1
    uniqueness = place.uniqueness

    # Penalty terms (higher = worse)
    # Budget penalty: 0 if cost=0, approaches 1 as cost → budget_max
    cost_penalty = min(1.0, place.cost / max(w.budget_max, 1))
    crowd_penalty = place.crowd_level

    score = (
        w.w_preference * preference
        + w.w_safety * safety
        + w.w_rating * rating_norm
        + w.w_uniqueness * uniqueness
        - w.w_cost_penalty * cost_penalty
        - w.w_crowd_penalty * crowd_penalty
    )
    return max(0.0, score)


# ─── Greedy itinerary builder ─────────────────────────────────────────────────

def _greedy_build(
    places: list[Place],
    request: ItineraryRequest,
) -> list[ItineraryStop]:
    """Greedy construction: pick highest-score feasible place at each step."""
    if not places:
        return []

    remaining = list(places)
    current_lat = request.start_location_lat
    current_lng = request.start_location_lng
    current_minute = request.day_start_minute
    day_end = request.day_end_minute

    stops: list[ItineraryStop] = []
    total_cost = 0.0

    while remaining and current_minute < day_end:
        # Filter feasible places at current time
        feasible = _apply_hard_filters(remaining, request, current_minute)
        if not feasible:
            # Advance time to next opening or meal window
            current_minute = _advance_to_next_opening(feasible, remaining, current_minute, day_end, request)
            if current_minute is None:
                break

        # Score remaining feasible places
        for p in feasible:
            p.preference_fit = _compute_preference_fit(p, request)

        scored = [(p, _score_place(p, request)) for p in feasible]
        scored.sort(key=lambda x: x[1], reverse=True)

        placed = False
        for place, score in scored:
            travel = _haversine_minutes(current_lat, current_lng, place.lat, place.lng)
            arrival = current_minute + travel

            # Check meal window — insert meal if we're in a meal window
            arrival = _maybe_insert_meal(arrival, request, stops)

            # Check venue still open after travel
            if arrival + place.visit_duration > place.close_time:
                continue
            if arrival + place.visit_duration > day_end:
                continue

            departure = arrival + place.visit_duration

            stop = ItineraryStop(
                place=place,
                arrival_minute=arrival,
                departure_minute=departure,
                travel_from_prev_minutes=travel,
                score=score,
            )
            stops.append(stop)
            total_cost += place.cost
            current_lat, current_lng = place.lat, place.lng
            current_minute = departure
            remaining.remove(place)
            placed = True
            break

        if not placed:
            break

    return stops


def _advance_to_next_opening(
    feasible: list[Place],
    remaining: list[Place],
    current_minute: int,
    day_end: int,
    request: ItineraryRequest,
) -> Optional[int]:
    """Skip to the next time a place opens or a meal window clears."""
    candidates = []
    for p in remaining:
        if p.open_time > current_minute and p.open_time <= day_end:
            candidates.append(p.open_time)
    if candidates:
        return min(candidates)
    return None


def _maybe_insert_meal(current_minute: int, request: ItineraryRequest, stops: list[ItineraryStop]) -> int:
    """If current time is inside a meal window and no meal stop exists today, advance past the meal."""
    # Simple: if we're in a lunch/dinner window and haven't had a meal, skip the window
    is_lunch = request.lunch_window_start <= current_minute <= request.lunch_window_end
    is_dinner = request.dinner_window_start <= current_minute <= request.dinner_window_end

    if not is_lunch and not is_dinner:
        return current_minute

    # Check if a meal stop already exists today
    has_meal = any(s.place.category == "restaurant" or s.place.category == "food"
                   for s in stops if s.place.category in ("restaurant", "food"))
    if has_meal:
        return current_minute

    # Advance past meal window
    if is_lunch:
        return request.lunch_window_end + request.meal_duration
    if is_dinner:
        return request.dinner_window_end + request.meal_duration

    return current_minute


def _compute_preference_fit(place: Place, request: ItineraryRequest) -> float:
    """How well a place matches traveller's stated preference vector."""
    tags = set(place.tags)
    pref = request.preference_vector

    if not pref and not tags:
        return 0.5

    score = 0.0
    # Tag-based matching
    tag_weights = {
        "food": pref.get("food", 0.0),
        "culture": pref.get("culture", 0.0),
        "adventure": pref.get("adventure", 0.0),
        "nature": pref.get("nature", pref.get("adventure", 0.0)),
        "shopping": pref.get("shopping", pref.get("budget", 0.0)),
        "nightlife": pref.get("nightlife", 0.0),
        "wellness": pref.get("relaxation", pref.get("pace", 0.0)),
    }

    matched = 0.0
    total_weight = 0.0
    for tag, weight in tag_weights.items():
        if weight > 0 and tag in tags:
            matched += weight
        total_weight += weight

    if total_weight > 0:
        score = matched / total_weight
    else:
        score = 0.5

    # Budget fit
    budget_fit = 1.0 - min(1.0, place.cost / max(request.budget_max, 1))
    score = 0.7 * score + 0.3 * budget_fit

    return min(1.0, max(0.0, score))


# ─── 2-opt local search ───────────────────────────────────────────────────────

def _two_opt_improve(stops: list[ItineraryStop], request: ItineraryRequest) -> list[ItineraryStop]:
    """2-opt local search to reduce total travel time.

    Repeatedly reverse segments of the route (i, j) to find a shorter
    path. Runs until no improving swap is found or max iterations hit.
    """
    if len(stops) < 3:
        return stops

    improved = True
    iterations = 0
    max_iterations = 100

    while improved and iterations < max_iterations:
        improved = False
        iterations += 1

        for i in range(len(stops) - 2):
            for j in range(i + 2, len(stops)):
                # Try reversing segment [i+1, j]
                new_order = stops[:i + 1] + list(reversed(stops[i + 1:j + 1])) + stops[j + 1:]

                # Check if all constraints still satisfied
                if not _route_feasible(new_order, request):
                    continue

                old_travel = _total_travel_time(stops, request)
                new_travel = _total_travel_time(new_order, request)

                if new_travel < old_travel:
                    stops = new_order
                    improved = True

    return stops


def _route_feasible(stops: list[ItineraryStop], request: ItineraryRequest) -> bool:
    """Check all stops satisfy time windows, meal windows, and day end."""
    prev_lat = request.start_location_lat
    prev_lng = request.start_location_lng
    current = request.day_start_minute

    for stop in stops:
        travel = _haversave_minutes(prev_lat, prev_lng, stop.place.lat, stop.place.lng)
        arrival = current + travel

        # Advance past meal window if needed
        arrival = _maybe_insert_meal(arrival, request, stops[:stops.index(stop)])

        # Venue open?
        if arrival < stop.place.open_time:
            arrival = stop.place.open_time
        if arrival + stop.place.visit_duration > stop.place.close_time:
            return False
        if arrival + stop.place.visit_duration > request.day_end_minute:
            return False
        if arrival + stop.place.visit_duration > stop.place.close_time:
            return False

        current = arrival + stop.place.visit_duration
        prev_lat, prev_lng = stop.place.lat, stop.place.lng

    return True


def _total_travel_time(stops: list[ItineraryStop], request: ItineraryRequest) -> int:
    """Sum of all travel times in the route."""
    if not stops:
        return 0
    total = stops[0].travel_from_prev_minutes
    for s in stops[1:]:
        total += s.travel_from_prev_minutes
    return total


# Fix typo in function reference used above
_haversave_minutes = _haversine_minutes


# ─── Main API ─────────────────────────────────────────────────────────────────

def build_itinerary(
    places: list[Place],
    request: ItineraryRequest,
) -> Itinerary:
    """
    Build an optimized day itinerary from a list of candidate places.

    Algorithm (matches Slide 12 — MVP approach):
      1. Score each candidate by preference fit, safety, rating,
         uniqueness, minus cost and crowd penalties
      2. Filter out closed / unsafe / over-budget options
      3. Greedy construction: pick highest-score feasible place at each step,
         respecting time windows, meal breaks, and travel time
      4. 2-opt local search: iteratively reverse route segments to reduce
         total travel time while keeping all constraints satisfied

    Args:
        places: List of candidate Place objects (e.g. from destination catalogue)
        request: ItineraryRequest with traveller preferences and constraints

    Returns:
        Itinerary with ordered stops and summary statistics
    """
    if not places:
        return _empty_itinerary()

    # Step 1: score all places
    for p in places:
        p.preference_fit = _compute_preference_fit(p, request)

    # Step 2: greedy construction
    stops = _greedy_build(places, request)

    # Step 3: 2-opt improvement
    stops = _two_opt_improve(stops, request)

    # Recompute travel times after reordering
    stops = _recompute_travel_times(stops, request)

    # Compute aggregate stats
    if stops:
        total_cost = sum(s.place.cost for s in stops)
        total_travel = sum(s.travel_from_prev_minutes for s in stops)
        safety_avg = sum(s.place.safety_score for s in stops) / len(stops)
        pref_avg = sum(s.place.preference_fit for s in stops) / len(stops)
        crowd_avg = sum(s.place.crowd_level for s in stops) / len(stops)
    else:
        total_cost = 0.0
        total_travel = 0
        safety_avg = 0.0
        pref_avg = 0.0
        crowd_avg = 0.0

    logger.info(
        "itinerary.build",
        extra={
            "n_candidates": len(places),
            "n_stops": len(stops),
            "total_cost": total_cost,
            "total_travel_min": total_travel,
            "safety_score": round(safety_avg, 2),
        },
    )

    return Itinerary(
        stops=stops,
        total_cost=round(total_cost, 2),
        total_travel_minutes=total_travel,
        safety_score_avg=round(safety_avg, 3),
        preference_score_avg=round(pref_avg, 3),
        crowd_risk_avg=round(crowd_avg, 3),
    )


def _recompute_travel_times(stops: list[ItineraryStop], request: ItineraryRequest) -> list[ItineraryStop]:
    """Recompute travel_from_prev_minutes after a route reorder."""
    if not stops:
        return stops

    prev_lat = request.start_location_lat
    prev_lng = request.start_location_lng

    updated = []
    for stop in stops:
        travel = _haversine_minutes(prev_lat, prev_lng, stop.place.lat, stop.place.lng)
        new_stop = ItineraryStop(
            place=stop.place,
            arrival_minute=stop.arrival_minute,  # keep original schedule
            departure_minute=stop.departure_minute,
            travel_from_prev_minutes=travel,
            score=stop.score,
        )
        updated.append(new_stop)
        prev_lat, prev_lng = stop.place.lat, stop.place.lng

    return updated


def _empty_itinerary() -> Itinerary:
    return Itinerary(
        stops=[],
        total_cost=0.0,
        total_travel_minutes=0,
        safety_score_avg=0.0,
        preference_score_avg=0.0,
        crowd_risk_avg=0.0,
    )


# ─── Demo helper ─────────────────────────────────────────────────────────────

def build_demo_itinerary(tokyo_places: list[Place], prefs: dict[str, float]) -> dict:
    """
    Build a full-day Tokyo itinerary for the Slide 13 demo screen.

    Demo: Solo female traveller, food + culture interests,
          halal, high safety priority.
    """
    request = ItineraryRequest(
        preference_vector=prefs,
        budget_max=150.0,
        start_location_lat=35.6762,
        start_location_lng=139.6503,
        day_start_minute=540,   # 09:00
        day_end_minute=1320,    # 22:00
        w_safety=2.0,           # High safety priority
        w_preference=1.5,
        w_rating=1.0,
        w_uniqueness=0.5,
        w_cost_penalty=0.8,
        w_crowd_penalty=1.2,    # Avoid crowds
    )

    itinerary = build_itinerary(tokyo_places, request)
    return itinerary.to_display()
