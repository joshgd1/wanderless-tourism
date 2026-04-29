# Itinerary Optimizer Specification

## Overview

The Itinerary Optimizer sequences tour stops to maximize predicted tourist satisfaction while respecting physical and temporal constraints. Uses constraint optimization with simulated annealing fallback.

## Problem Definition

### Objective

```
maximize Σ satisfaction_score(stop_i, tourist_profile)
subject to:
    Σ duration(stop_i) <= available_time
    distance(start, stop_1) + Σ distance(stop_i, stop_i+1) + distance(stop_n, end) <= max_travel
    stop_i.open_hour <= arrival_time(stop_i) <= stop_i.close_hour
    weather_suitability(stop_i, forecast) == suitable
    energy_curve_compliance(route) == true
```

### Decision Variables

```
route_sequence = [stop_1, stop_2, ..., stop_n]  # Ordered list
arrival_times = [t_1, t_2, ..., t_n]           # Arrival at each stop
```

## Constraints

### Hard Constraints (Must Satisfy)

```python
hard_constraints = {
    # Time Window
    "time": lambda route, times, context: all(
        stop.open_hour <= times[i] <= stop.close_hour
        for i, stop in enumerate(route)
    ),

    # Maximum Tour Duration
    "max_duration": lambda route, times, context:
        times[-1] - times[0] + travel_time(route) <= context.max_hours * 3600,

    # Travel Distance
    "max_distance": lambda route, context:
        total_distance(route) <= context.max_km * 1000,  # meters

    # Weather Suitability
    "weather": lambda route, context:
        all(stop.suitable_for_weather(context.forecast) for stop in route),

    # Minimum Stop Duration
    "min_stop_time": lambda route, times, context:
        all(
            (times[i+1] - times[i]) >= stop.min_visit_duration
            for i, stop in enumerate(route[:-1])
        ),
}
```

### Soft Constraints (Optimize For)

```python
soft_constraints = {
    # Tourist Energy Curve
    "energy_curve": lambda route, times, context:
        # Peak energy morning/evening, dip midday
        score = calculate_energy_fit(route, times, context.tourist.energy_preference)

    # Preference Alignment
    "interest_match": lambda route, times, context:
        avg([
            stop.interest_score(context.tourist.profile)
            for stop in route
        ])

    # Transition Satisfaction
    "smooth_transitions": lambda route, times, context:
        # Minimize jarring transitions (e.g., temple → club)
        score_transition_compatibility(route)
}
```

## Algorithm: Constraint Propagation + Simulated Annealing

### Phase 1: Constraint Propagation (Fast)

```python
def fast_optimize(stops, constraints, context):
    """
    Quick feasibility search using constraint propagation
    Returns: ordered route or None if infeasible
    """
    # Prune stops that violate hard constraints
    feasible_stops = [
        stop for stop in stops
        if all(c(stop) for c in hard_constraints.values())
    ]

    # Greedy ordering by satisfaction/time ratio
    ordered = greedy_sequence(feasible_stops, context)

    if satisfies_all(ordered, hard_constraints):
        return ordered

    return None  # Fall through to SA
```

### Phase 2: Simulated Annealing (Thorough)

```python
def simulated_annealing(route, constraints, context):
    """
    SA for harder instances
    """
    current = route[:]
    best = current[:]
    T = 10000  # Initial temperature
    T_min = 1

    while T > T_min:
        # Generate neighbor
        neighbor = swap_or_reorder(current)

        # Calculate delta
        current_score = score(current, constraints, context)
        neighbor_score = score(neighbor, constraints, context)
        delta = neighbor_score - current_score

        # Accept or reject
        if delta > 0 or random() < exp(delta / T):
            current = neighbor

            if score(current) > score(best):
                best = current[:]

        T *= 0.9995  # Cooling rate

    return best
```

### Phase 3: Greedy Fallback

```python
def greedy_fallback(stops, context):
    """
    Last resort when SA doesn't converge
    """
    remaining = stops[:]
    ordered = []
    current_time = context.start_time
    current_location = context.start_location

    while remaining:
        best = None
        best_score = -inf

        for stop in remaining:
            score = evaluate_stop(stop, current_location, current_time, context)
            if score > best_score:
                best = stop
                best_score = score

        ordered.append(best)
        remaining.remove(best)
        current_time += best.duration
        current_location = best.location

    return ordered
```

## Tourist Energy Curve

```
# Default energy curve (normalized 0-1, 6AM-10PM)
energy_curve = {
    6:  0.3,   # Wake up
    7:  0.5,   # Breakfast
    8:  0.8,   # Morning peak
    9:  0.9,   # Peak
    10: 0.85,
    11: 0.7,   # Declining
    12: 0.5,   # Lunch dip
    13: 0.6,   # Recovery
    14: 0.65,
    15: 0.7,   # Afternoon recovery
    16: 0.75,
    17: 0.8,   # Late afternoon
    18: 0.9,   # Evening peak
    19: 0.7,   # Dinner
    20: 0.5,   # Wind down
    21: 0.3,
    22: 0.1,   # Sleep
}

# Tourists can customize their curve preference
# Algorithm penalizes high-energy activities during low-energy periods
```

## Weather Integration

```python
weather_adjustments = {
    "clear": {"outdoor": 1.0, "indoor": 1.0},
    "cloudy": {"outdoor": 0.9, "indoor": 1.0},
    "rain": {"outdoor": 0.2, "indoor": 1.0},      # Rain gear helps but not ideal
    "storm": {"outdoor": 0.0, "indoor": 1.0},    # Outdoor impossible
    "hot": {"outdoor": 0.7, "indoor": 1.0},      # Heat fatigue
    "cold": {"outdoor": 0.8, "indoor": 1.0},
}

def weather_score(stop, forecast):
    base = stop.base_satisfaction
    weather = forecast[stop.location]

    if stop.is_outdoor:
        return base * weather_adjustments[weather]["outdoor"]
    else:
        return base * weather_adjustments[weather]["indoor"]
```

## Output Format

```json
{
  "itinerary": {
    "stops": [
      {
        "order": 1,
        "stop_id": "stop_456",
        "name": "Pad Thai Cooking Class",
        "location": {"lat": 18.7883, "lng": 98.9853},
        "arrival_time": "09:00",
        "departure_time": "11:30",
        "duration_minutes": 150,
        "satisfaction_score": 0.92,
        "interest_tags": ["food", "culture"],
        "weather_suitability": "clear",
        "notes": "Hands-on cooking with local chef"
      },
      {
        "order": 2,
        "stop_id": "stop_789",
        "name": "Warorot Market",
        "location": {"lat": 18.7867, "lng": 98.9872},
        "arrival_time": "12:00",
        "departure_time": "14:00",
        "duration_minutes": 120,
        "satisfaction_score": 0.78,
        "interest_tags": ["food", "culture"],
        "weather_suitability": "indoor_preferred",
        "notes": "Lunch at market - try Khao Soi"
      }
    ],
    "total_duration_hours": 5.0,
    "total_travel_km": 4.2,
    "total_satisfaction_score": 0.85,
    "energy_fit_score": 0.91
  },
  "route_map": {
    "polyline": "encoded_polyline_string",
    "waypoints": [...]
  }
}
```

## Integration with Guide Workflow

```
guide_planning_flow(tourist_request):
    1. Receive tourist interest profile + constraints
    2. Fetch guide's partner stops (business network)
    3. Run itinerary_optimizer(guide_stops + common_stops, tourist_constraints)
    4. Return proposed itinerary to guide
    5. Guide can reorder/adjust (AI suggestions shown)
    6. Guide finalizes itinerary
    7. Tourist receives and can request changes
    8. Confirmation → booking locked
```

## Performance Requirements

| Metric                     | Target                                |
| -------------------------- | ------------------------------------- |
| Optimization latency (p95) | < 2 seconds                           |
| Optimality gap             | < 5% from theoretical optimum         |
| Feasibility rate           | > 95% of valid requests produce route |
| Fallback rate (SA)         | < 10% of requests                     |
| Greedy fallback rate       | < 2% of requests                      |
