#!/usr/bin/env python3
"""
WanderLess — Synthetic Pilot Data Generator

Generates synthetic tourist-guide-rating tuples for cold-start model development.
Supports Thailand (Chiang Mai) and Singapore destinations.

Rating formula:
    norm_dot = (raw_dot - dot_min) / (dot_max - dot_min)   # [0, 1]
    true_rating = clamp(norm_dot * 6.5 + 1.2 + bonus, 1.0, 5.0)
    bonus = lang_match * 0.30 + (compat - 0.8) * 0.15
    rating = clamp(true_rating * 0.88 + noise * 0.12, 1.0, 5.0)

Target: mean ≈ 3.4-3.7, poor_rate ≈ 8-15% (rating < 2.5).

Output: data/synthetic_ratings.csv  — tourist-guide-rating tuples
        data/tourist_profiles.csv  — tourist feature vectors
        data/guide_profiles.csv    — guide feature vectors
        data/README.md             — data dictionary and generation notes

Usage:
    python generate_synthetic.py [--n N] [--seed SEED] [--output-dir DIR]
"""

import argparse
import math
import random
import csv
import json
from pathlib import Path
from datetime import datetime, timedelta

# ---------------------------------------------------------------------------
# Destination configs
# ---------------------------------------------------------------------------

DESTINATIONS = {
    "TH": {
        "name": "Thailand (Chiang Mai)",
        "languages": ["en", "zh", "fr", "de", "ja", "ko", "ru", "th"],
        "locations": [
            "Old City", "Doi Suthep", "Night Bazaar", "Nimman",
            "Doi Inthanon", "Mae Sa Valley", "Doi Pui", "Sankamphaeng",
        ],
        "native_tongue": "th",
        "license_types": ["licensed", "verified_expert", "community_host"],
    },
    "SG": {
        "name": "Singapore",
        "languages": ["en", "zh", "ms", "ta"],  # English, Mandarin, Malay, Tamil
        "locations": [
            "Marina Bay", "Orchard Road", "Clarke Quay", "Sentosa",
            "Chinatown", "Little India", "Gardens by the Bay", "Haw Par Villa",
            "Universal Studios", "Botanic Gardens", "Fort Canning", "Kampong Glam",
        ],
        "native_tongue": "sg",
        "license_types": ["licensed", "verified_expert", "community_host"],
    },
}

N_TOURISTS_PER_DEST = 200  # per destination
N_GUIDES_PER_DEST = 30      # per destination
N_RATINGS = 600
SEED = 42

AGE_GROUPS = ["18-25", "26-35", "36-50", "51-65", "65+"]
TRAVEL_STYLES = ["solo", "couple", "family", "group"]
BUDGET_TIERS = ["budget", "mid", "premium"]

# Global expertise pool (all destinations)
EXPERTISE_TAGS_POOL = [
    "food", "history", "culture", "trekking", "temples", "nature",
    "photography", "art", "nightlife", "shopping", "wellness",
    "cooking", "markets", "rural", "river", "architecture",
    "food_heritage", "museums", "gardens", "beach", "waterfront",
]

# Rating distribution parameters (from Chiang Mai Playbook §Cold Start Data Strategy)
RATING_MEAN = 4.2
RATING_STD = 1.0  # enough spread: ~15-20% poor for average/random pairs

# Poor-experience threshold (from Phase 1 Frame: 1-2 stars = poor)
POOR_THRESHOLD = 2.5  # ratings below this = poor experience

# ---------------------------------------------------------------------------
# Vector helpers
# ---------------------------------------------------------------------------


def unit_vector(v: list[float]) -> list[float]:
    """L2-normalize a vector."""
    norm = math.sqrt(sum(x * x for x in v))
    if norm == 0:
        return v
    return [x / norm for x in v]


def dot_product(a: list[float], b: list[float]) -> float:
    """Unnormalized dot product — wider spread than unit-vector cosine."""
    return sum(ai * bi for ai, bi in zip(a, b))


def clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))


def match_score(t_vec: list[float], g_vec: list[float]) -> float:
    """
    Unnormalized dot product as similarity score.
    Vectors in [0.2, 1.0]^3 → dot product range ≈ [0.12, 3.0]
    """
    return dot_product(t_vec, g_vec)


# ---------------------------------------------------------------------------
# Profile generators
# ---------------------------------------------------------------------------


def make_tourist_vector(
    rng: random.Random,
    country: str = "TH",
) -> dict:
    """
    Tourist feature vector. Fields: food/culture/adventure interest, pace,
    budget, language, age_group, travel_style, energy_curve[24].
    """
    dest = DESTINATIONS[country]
    food = rng.uniform(0.2, 1.0)
    culture = rng.uniform(0.2, 1.0)
    adventure = rng.uniform(0.1, 1.0)
    pace = rng.uniform(0.1, 1.0)
    budget = rng.uniform(0.1, 1.0)

    interest_vec = [food, culture, adventure]

    return {
        "tourist_id": f"T{country}{rng.randint(10000, 99999)}",
        "food_interest": round(food, 3),
        "culture_interest": round(culture, 3),
        "adventure_interest": round(adventure, 3),
        "pace_preference": round(pace, 3),
        "budget_level": round(budget, 3),
        "language": rng.choice(dest["languages"]),
        "age_group": rng.choice(AGE_GROUPS),
        "travel_style": rng.choice(TRAVEL_STYLES),
        "energy_curve": [
            round(rng.uniform(0.3, 1.0) if 8 <= h <= 20 else rng.uniform(0.1, 0.5), 3)
            for h in range(24)
        ],
        "_interest_vec": interest_vec,
        "_country": country,
    }


# Expertise vector map — shared across all destinations
EXPERTISE_MAP = {
    "food": (1.0, 0.0, 0.0),
    "culture": (0.0, 1.0, 0.0),
    "adventure": (0.0, 0.0, 1.0),
    "history": (0.1, 0.9, 0.0),
    "temples": (0.0, 0.8, 0.2),
    "nature": (0.0, 0.1, 0.9),
    "trekking": (0.0, 0.1, 0.9),
    "photography": (0.1, 0.5, 0.4),
    "art": (0.1, 0.7, 0.2),
    "nightlife": (0.3, 0.1, 0.1),
    "shopping": (0.4, 0.1, 0.1),
    "wellness": (0.2, 0.3, 0.2),
    "cooking": (0.8, 0.1, 0.1),
    "markets": (0.5, 0.2, 0.1),
    "rural": (0.0, 0.2, 0.7),
    "river": (0.0, 0.1, 0.8),
    "music": (0.1, 0.5, 0.1),
    "architecture": (0.1, 0.6, 0.1),
    "food_heritage": (0.8, 0.5, 0.1),
    "museums": (0.1, 0.9, 0.2),
    "gardens": (0.1, 0.4, 0.6),
    "beach": (0.3, 0.1, 0.8),
    "waterfront": (0.3, 0.3, 0.5),
}


def make_guide_profile(
    rng: random.Random,
    country: str = "TH",
) -> dict:
    """
    Guide profile with destination-specific locations and Singapore STB licensing.
    """
    dest = DESTINATIONS[country]
    n_expertise = rng.randint(2, 4)
    expertise = rng.sample(EXPERTISE_TAGS_POOL, n_expertise)

    expertise_vec = [0.0, 0.0, 0.0]
    for tag in expertise:
        if tag in EXPERTISE_MAP:
            for i, v in enumerate(EXPERTISE_MAP[tag]):
                expertise_vec[i] = max(expertise_vec[i], v)
    expertise_vec = unit_vector(expertise_vec)

    personality = [round(rng.uniform(0.1, 1.0), 3) for _ in range(5)]
    pace_style = rng.uniform(0.1, 1.0)
    group_preferred = rng.randint(1, 8)
    tier_map = {"budget": 0.2, "mid": 0.55, "premium": 0.9}
    budget_tier = rng.choice(BUDGET_TIERS)

    # Location coverage — country:location format
    n_locations = rng.randint(1, 4)
    locations = rng.sample(dest["locations"], k=min(n_locations, len(dest["locations"])))
    location_coverage = "|".join(f"{country}:{loc}" for loc in locations)

    # Language pairs
    native = dest["native_tongue"]
    lang_pool = dest["languages"]
    language_pairs = [
        ("en", native),
        (rng.choice(lang_pool), native),
    ]

    # Singapore STB licensing
    license_type = rng.choice(dest["license_types"])
    if country == "SG":
        if license_type == "licensed":
            license_number = f"STB-{rng.randint(100000, 999999)}"
            license_verified = True
            license_expiry = (datetime.now() + timedelta(days=rng.randint(180, 730))).strftime("%Y-%m-%d")
        elif license_type == "verified_expert":
            license_number = f"VXP-{rng.randint(10000, 99999)}"
            license_verified = True
            license_expiry = None
        else:
            license_number = None
            license_verified = False
            license_expiry = None
    else:
        license_number = None
        license_verified = rng.random() < 0.3
        license_expiry = None

    return {
        "guide_id": f"G{country}{rng.randint(100, 999)}",
        "expertise_tags": expertise,
        "personality_vector": personality,
        "language_pairs": language_pairs,
        "pace_style": round(pace_style, 3),
        "group_size_preferred": group_preferred,
        "budget_tier": budget_tier,
        "location_coverage": location_coverage,
        "availability": {
            str(d): rng.sample(["morning", "afternoon", "evening"], k=rng.randint(1, 3))
            for d in range(1, 8)
        },
        "rating_history": round(rng.gauss(RATING_MEAN, 0.5), 2),
        "rating_count": rng.randint(0, 200),
        "specialties": expertise,
        "_expertise_vec": expertise_vec,
        "_pace_style": pace_style,
        "_budget_alignment": tier_map[budget_tier],
        "_country": country,
        "_license_type": license_type,
        "_license_number": license_number,
        "_license_verified": license_verified,
        "_license_expiry": license_expiry,
    }


# ---------------------------------------------------------------------------
# Rating generation
# ---------------------------------------------------------------------------


def generate_rating(
    tourist: dict,
    guide: dict,
    rng: random.Random,
    dot_range: tuple[float, float],
) -> dict:
    """
    Generate a rating consistent with vector similarity + Chiang Mai matching rule.

    Rating formula:
        norm_dot = (raw_dot - dot_min) / (dot_max - dot_min)  # mapped to [0, 1]
        true_rating = clamp(norm_dot * 6.5 + 1.2 + bonus, 1.0, 5.0)
        bonus = lang_match * 0.30 + (compat - 0.8) * 0.15
        rating = clamp(true_rating * 0.88 + noise * 0.12, 1.0, 5.0)

    Target: mean ≈ 3.4-3.7, poor_rate ≈ 8-15% (rating < 2.5).
    dot_range = (dot_min, dot_max) from all tourist-guide pairs in the population.
    """
    t_vec = tourist["_interest_vec"]
    g_vec = guide["_expertise_vec"]

    raw_dot = dot_product(t_vec, g_vec)
    dot_min, dot_max = dot_range
    norm_dot = (raw_dot - dot_min) / (dot_max - dot_min)

    lang_match = 1.0 if tourist["language"] in [lp[0] for lp in guide["language_pairs"]] else 0.0

    budget_diff = abs(tourist["budget_level"] - guide["_budget_alignment"])
    budget_compat = clamp(1.0 - budget_diff * 0.40, 0.6, 1.0)

    pace_diff = abs(tourist["pace_preference"] - guide["_pace_style"])
    pace_compat = clamp(1.0 - pace_diff * 0.35, 0.6, 1.0)

    compat = budget_compat * pace_compat
    bonus = lang_match * 0.30 + (compat - 0.8) * 0.15

    true_rating = clamp(norm_dot * 6.5 + 1.2 + bonus, 1.0, 5.0)

    # Add noise: 12% noise weight, Gaussian
    noise = rng.gauss(0, RATING_STD)
    noisy_rating = true_rating * 0.88 + noise * 0.12

    rating = clamp(round(noisy_rating, 2), 1.0, 5.0)

    # Poor experience flag (per Phase 1 Frame: 1-2 stars = poor)
    is_poor = rating < POOR_THRESHOLD

    return {
        "tourist_id": tourist["tourist_id"],
        "guide_id": guide["guide_id"],
        "rating": rating,
        "is_poor_experience": is_poor,
        "norm_dot_product": round(norm_dot, 4),
        "language_match": lang_match,
        "budget_alignment": round(budget_compat, 3),
        "pace_alignment": round(pace_compat, 3),
        "predicted_rating": round(true_rating, 2),
        "rating_source": "synthetic",
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(description="WanderLess synthetic pilot data generator")
    parser.add_argument("--n", type=int, default=N_RATINGS, help="Number of rating tuples to generate")
    parser.add_argument("--seed", type=int, default=SEED, help="Random seed")
    parser.add_argument("--output-dir", type=str, default="data", help="Output directory")
    args = parser.parse_args()

    rng = random.Random(args.seed)
    output = Path(args.output_dir)
    output.mkdir(parents=True, exist_ok=True)

    print(f"[WanderLess] Generating synthetic pilot data (seed={args.seed})")
    total_tourists = N_TOURISTS_PER_DEST * len(DESTINATIONS)
    total_guides = N_GUIDES_PER_DEST * len(DESTINATIONS)
    print(f"  Destinations: {', '.join(d['name'] for d in DESTINATIONS.values())}")
    print(f"  Tourists : {total_tourists} ({N_TOURISTS_PER_DEST}/dest)")
    print(f"  Guides   : {total_guides} ({N_GUIDES_PER_DEST}/dest)")
    print(f"  Ratings  : {args.n}")

    # --- Generate tourists per destination ---
    tourists = []
    for country in DESTINATIONS:
        for _ in range(N_TOURISTS_PER_DEST):
            tourists.append(make_tourist_vector(rng, country=country))
    print(f"  ✓ {len(tourists)} tourist profiles generated")

    # --- Generate guides per destination ---
    guides = []
    for country in DESTINATIONS:
        for _ in range(N_GUIDES_PER_DEST):
            guides.append(make_guide_profile(rng, country=country))
    print(f"  ✓ {len(guides)} guide profiles generated")

    # --- Generate ratings ---
    # Compute dot_range from all tourist-guide pairs in the population
    all_dots = [
        dot_product(t["_interest_vec"], g["_expertise_vec"])
        for t in tourists for g in guides
    ]
    dot_range = (min(all_dots), max(all_dots))

    # Sample tourist-guide pairs (cross-destination to simulate realistic matching)
    ratings = []
    for _ in range(args.n):
        tourist = rng.choice(tourists)
        guide = rng.choice(guides)
        ratings.append(generate_rating(tourist, guide, rng, dot_range))

    poor_count = sum(1 for r in ratings if r["is_poor_experience"])
    print(f"  ✓ {len(ratings)} ratings generated")
    print(f"    Poor experience rate: {poor_count}/{len(ratings)} ({100*poor_count/len(ratings):.1f}%)")
    print(f"    Rating mean: {sum(r['rating'] for r in ratings)/len(ratings):.2f}")

    # --- Write tourist profiles CSV ---
    tourist_fields = [
        "tourist_id", "food_interest", "culture_interest", "adventure_interest",
        "pace_preference", "budget_level", "language", "age_group",
        "travel_style", "energy_curve",
    ]
    with open(output / "tourist_profiles.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=tourist_fields, extrasaction="ignore")
        w.writeheader()
        for t in tourists:
            row = {k: t[k] for k in tourist_fields}
            row["energy_curve"] = "|".join(f"{v:.3f}" for v in row["energy_curve"])
            w.writerow(row)
    print(f"  ✓ tourist_profiles.csv")

    # --- Write guide profiles CSV ---
    guide_fields = [
        "guide_id", "expertise_tags", "personality_vector", "language_pairs",
        "pace_style", "group_size_preferred", "budget_tier",
        "location_coverage", "availability", "rating_history",
        "rating_count", "specialties", "license_verified",
        "license_number", "license_type", "license_country", "license_expiry",
    ]
    with open(output / "guide_profiles.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=guide_fields, extrasaction="ignore")
        w.writeheader()
        for g in guides:
            row = {k: g.get(k) for k in guide_fields}
            row["expertise_tags"] = "|".join(g["expertise_tags"])
            row["personality_vector"] = "|".join(f"{v:.3f}" for v in g["personality_vector"])
            row["language_pairs"] = "|".join(f"{s}→{t}" for s, t in g["language_pairs"])
            # location_coverage already formatted as "SG:Marina Bay|SG:Orchard"
            row["availability"] = json.dumps(g["availability"])
            row["specialties"] = "|".join(g["specialties"])
            row["license_verified"] = g["_license_verified"]
            row["license_number"] = g["_license_number"] or ""
            row["license_type"] = g["_license_type"] or ""
            row["license_country"] = g["_country"]
            row["license_expiry"] = g["_license_expiry"] or ""
            w.writerow(row)
    print(f"  ✓ guide_profiles.csv")

    # --- Write ratings CSV ---
    rating_fields = [
        "tourist_id", "guide_id", "rating", "is_poor_experience",
        "norm_dot_product", "language_match", "budget_alignment",
        "pace_alignment", "predicted_rating", "rating_source",
    ]
    with open(output / "synthetic_ratings.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rating_fields)
        w.writeheader()
        w.writerows(ratings)
    print(f"  ✓ synthetic_ratings.csv")

    # --- Write README ---
    dest_list = ", ".join(f"{k} ({v['name']})" for k, v in DESTINATIONS.items())
    readme = f"""# WanderLess Synthetic Pilot Data

Generated: {Path(__file__).name} — seed={args.seed}

## Destinations

- **{dest_list}**

## Files

| File | Rows | Description |
|------|------|-------------|
| `tourist_profiles.csv` | {total_tourists} | Tourist feature vectors |
| `guide_profiles.csv` | {total_guides} | Guide feature vectors (includes STB license fields for SG) |
| `synthetic_ratings.csv` | {args.n} | Tourist-Guide-Rating tuples |

## Schema: guide_profiles.csv (new Singapore fields)

| Column | Type | Description |
|--------|------|-------------|
| `license_verified` | bool | Platform-verified credentials |
| `license_number` | string | STB license number (SG licensed guides) |
| `license_type` | string | "licensed" | "verified_expert" | "community_host" |
| `license_country` | string | "SG" | "TH" |
| `license_expiry` | string | ISO date for STB licenses |

## Singapore License Tiers

| Tier | STB Verified | Description |
|------|-------------|-------------|
| `licensed` | Yes (STB-XXXXXX) | Official STB-licensed tour guide |
| `verified_expert` | Yes (VXP-XXXXX) | Background-checked local expert / experience host |
| `community_host` | No | Community host — experience-led activities |

## Rating Model (from Chiang Mai Playbook §Cold Start Data Strategy)

```
norm_dot = (raw_dot - dot_min) / (dot_max - dot_min)   # [0, 1]
true_rating = clamp(norm_dot × 6.5 + 1.2 + bonus, 1.0, 5.0)
bonus = lang_match × 0.30 + (compat − 0.8) × 0.15
rating = clamp(true_rating × 0.88 + gauss(0, {RATING_STD}) × 0.12, 1.0, 5.0)
```

88% genuine compatibility signal + 12% irreducible noise.

## Poor Experience Rate

Threshold: rating < {POOR_THRESHOLD}
Observed poor rate in this sample: {poor_count}/{args.n} ({100*poor_count/args.n:.1f}%)

Expected poor rate: 8-15% (Phase 1 Frame target for cold-start pilot data).
Actual in this sample: {poor_count}/{args.n} ({100*poor_count/args.n:.1f}%)

## Usage

```python
import pandas as pd

ratings = pd.read_csv("data/synthetic_ratings.csv")
tourists = pd.read_csv("data/tourist_profiles.csv")
guides   = pd.read_csv("data/guide_profiles.csv")

# Baseline: mean rating
print(ratings["rating"].describe())

# Poor experience rate
print(ratings["is_poor_experience"].mean())

# PSI-ready: bin ratings by predicted vs actual
ratings["bin"] = pd.cut(ratings["predicted_rating"], bins=5)
print(ratings.groupby("bin")["rating"].mean())  # calibration check
```

## Limitations

- Rating noise is i.i.d. Gaussian — real ratings have temporal correlation,
  reviewer bias, and guide effort variation not captured here.
- Language match is binary — real multilingual guides have partial fluency.
- Guide expertise is mapped to a 3-D interest space — real expertise is higher-dimensional.
- `is_poor_experience` is rating-based only — Phase 1 Frame includes 48h cancellation
  as a poor signal, not present in this synthetic dataset.
- Dot product range is computed from the generated tourist/guide population —
  with different random seeds or larger populations, the range shifts slightly.
"""
    with open(output / "README.md", "w") as f:
        f.write(readme)
    print(f"  ✓ README.md")
    print("\nDone. Data written to:", output.resolve())


if __name__ == "__main__":
    main()
