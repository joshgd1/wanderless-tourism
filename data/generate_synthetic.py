#!/usr/bin/env python3
"""
WanderLess — Synthetic Pilot Data Generator

Generates 500 synthetic tourist-guide-rating tuples for cold-start model development.
Aligns with Chiang Mai Playbook cold-start strategy (Phase 1, Months 1-4):
    match_score = 0.70 × content_similarity + 0.30 × language_match

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

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

N_TOURISTS = 350
N_GUIDES = 50
N_RATINGS = 500  # tourist-guide pairs with ratings
SEED = 42

# Languages reflecting Chiang Mai tourist mix (per Chiang Mai Playbook)
LANGUAGES = ["en", "zh", "fr", "de", "ja", "ko", "ru", "th"]
AGE_GROUPS = ["18-25", "26-35", "36-50", "51-65", "65+"]
TRAVEL_STYLES = ["solo", "couple", "family", "group"]
BUDGET_TIERS = ["budget", "mid", "premium"]
LOCATIONS = [
    "Old City",
    "Doi Suthep",
    "Night Bazaar",
    "Nimman",
    "Doi Inthanon",
    "Mae Sa Valley",
    "Doi Pui",
    "Sankamphaeng",
]

EXPERTISE_TAGS_POOL = [
    "food",
    "history",
    "culture",
    "trekking",
    "temples",
    "nature",
    "photography",
    "art",
    "nightlife",
    "shopping",
    "wellness",
    "cooking",
    "markets",
    "rural",
    "river",
]
SPECIALTIES_POOL = EXPERTISE_TAGS_POOL  # alias

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
) -> dict:
    """
    Tourist feature vector per 01-tourist-profile.md schema.
    Fields: food_interest, culture_interest, adventure_interest,
            pace_preference, budget_level, language, age_group,
            travel_style, energy_curve[24]
    """
    food = rng.uniform(0.2, 1.0)
    culture = rng.uniform(0.2, 1.0)
    adventure = rng.uniform(0.1, 1.0)
    pace = rng.uniform(0.1, 1.0)
    budget = rng.uniform(0.1, 1.0)

    # Build interest vector (same dimensions as guide expertise space)
    interest_vec = [food, culture, adventure]

    return {
        "tourist_id": f"T{rng.randint(10000, 99999)}",
        "food_interest": round(food, 3),
        "culture_interest": round(culture, 3),
        "adventure_interest": round(adventure, 3),
        "pace_preference": round(pace, 3),
        "budget_level": round(budget, 3),
        "language": rng.choice(LANGUAGES),
        "age_group": rng.choice(AGE_GROUPS),
        "travel_style": rng.choice(TRAVEL_STYLES),
        "energy_curve": [
            round(rng.uniform(0.3, 1.0) if 8 <= h <= 20 else rng.uniform(0.1, 0.5), 3)
            for h in range(24)
        ],
        "_interest_vec": interest_vec,  # internal; not written to CSV
    }


def make_guide_profile(
    rng: random.Random,
) -> dict:
    """
    Guide profile per 02-guide-profile.md schema.
    Guide vector for matching: weighted expertise + pace alignment.
    """
    n_expertise = rng.randint(2, 4)
    expertise = rng.sample(EXPERTISE_TAGS_POOL, n_expertise)

    # Map expertise to numeric vector aligned with tourist interest dimensions
    expertise_map = {
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
    }

    # Build guide expertise vector in same 3-d space as tourist interests
    expertise_vec = [0.0, 0.0, 0.0]
    for tag in expertise:
        if tag in expertise_map:
            for i, v in enumerate(expertise_map[tag]):
                expertise_vec[i] = max(expertise_vec[i], v)
    expertise_vec = unit_vector(expertise_vec)

    personality = [round(rng.uniform(0.1, 1.0), 3) for _ in range(5)]
    pace_style = rng.uniform(0.1, 1.0)
    group_preferred = rng.randint(1, 8)

    # Budget tier alignment with tourist budget_level
    tier_map = {"budget": 0.2, "mid": 0.55, "premium": 0.9}
    budget_tier = rng.choice(BUDGET_TIERS)

    # Guide location coverage
    n_locations = rng.randint(1, 4)
    locations = rng.sample(LOCATIONS, n_locations)

    return {
        "guide_id": f"G{rng.randint(100, 999)}",
        "expertise_tags": expertise,
        "personality_vector": personality,
        "language_pairs": [
            ("en", "th"),
            (rng.choice(["en", "zh", "ja", "ko"]), "th"),
        ],
        "pace_style": round(pace_style, 3),
        "group_size_preferred": group_preferred,
        "budget_tier": budget_tier,
        "location_coverage": locations,
        "availability": {
            str(d): rng.sample(["morning", "afternoon", "evening"], k=rng.randint(1, 3))
            for d in range(1, 8)
        },
        "rating_history": round(rng.gauss(RATING_MEAN, 0.5), 2),
        "rating_count": rng.randint(0, 200),
        "specialties": expertise,
        "_expertise_vec": expertise_vec,  # internal
        "_pace_style": pace_style,
        "_budget_alignment": tier_map[budget_tier],
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
    parser.add_argument("--output-dir", type=str, default=".", help="Output directory")
    args = parser.parse_args()

    rng = random.Random(args.seed)
    output = Path(args.output_dir)
    output.mkdir(parents=True, exist_ok=True)

    print(f"[WanderLess] Generating synthetic pilot data (seed={args.seed})")
    print(f"  Tourists : {N_TOURISTS}")
    print(f"  Guides   : {N_GUIDES}")
    print(f"  Ratings  : {args.n}")

    # --- Generate tourists ---
    tourists = [make_tourist_vector(rng) for _ in range(N_TOURISTS)]
    print(f"  ✓ {len(tourists)} tourist profiles generated")

    # --- Generate guides ---
    guides = [make_guide_profile(rng) for _ in range(N_GUIDES)]
    print(f"  ✓ {len(guides)} guide profiles generated")

    # --- Generate ratings ---
    # Compute dot_range from all tourist-guide pairs in the population
    all_dots = [
        dot_product(t["_interest_vec"], g["_expertise_vec"])
        for t in tourists for g in guides
    ]
    dot_range = (min(all_dots), max(all_dots))

    # Sample tourist-guide pairs (allow repeats for realistic rating distribution)
    ratings = []
    for _ in range(args.n):
        tourist = rng.choice(tourists)
        guide = rng.choice(guides)
        ratings.append(generate_rating(tourist, guide, rng, dot_range))

    poor_count = sum(1 for r in ratings if r["is_poor_experience"])
    print(f"  ✓ {len(ratings)} ratings generated")
    print(f"    Poor experience rate: {poor_count}/{len(ratings)} ({100*poor_count/len(ratings):.1f}%)")
    print(f"    Rating mean: {sum(r['rating'] for r in ratings)/len(ratings):.2f}")
    print(f"    Rating std:  {math.sqrt(sum((r['rating']-4.2)**2 for r in ratings)/len(ratings)):.2f}")

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
        "rating_count", "specialties",
    ]
    with open(output / "guide_profiles.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=guide_fields, extrasaction="ignore")
        w.writeheader()
        for g in guides:
            row = {k: g[k] for k in guide_fields}
            row["expertise_tags"] = "|".join(g["expertise_tags"])
            row["personality_vector"] = "|".join(f"{v:.3f}" for v in g["personality_vector"])
            row["language_pairs"] = "|".join(f"{s}→{t}" for s, t in g["language_pairs"])
            row["location_coverage"] = "|".join(g["location_coverage"])
            row["availability"] = json.dumps(g["availability"])
            row["specialties"] = "|".join(g["specialties"])
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
    readme = f"""# WanderLess Synthetic Pilot Data

Generated: {Path(__file__).name} — seed={args.seed}

## Files

| File | Rows | Description |
|------|------|-------------|
| `tourist_profiles.csv` | {N_TOURISTS} | Tourist feature vectors |
| `guide_profiles.csv` | {N_GUIDES} | Guide feature vectors |
| `synthetic_ratings.csv` | {args.n} | Tourist-Guide-Rating tuples |

## Schema: synthetic_ratings.csv

| Column | Type | Description |
|--------|------|-------------|
| `tourist_id` | string | FK → tourist_profiles.csv |
| `guide_id` | string | FK → guide_profiles.csv |
| `rating` | float [1, 5] | Synthetic rating (post-noise) |
| `is_poor_experience` | bool | True if rating < {POOR_THRESHOLD} (per Phase 1 Frame: 1-2 stars) |
| `norm_dot_product` | float [0, 1] | Normalized dot product similarity (noise-free) |
| `language_match` | float {{0, 1}} | Binary: guide speaks tourist language |
| `budget_alignment` | float [0, 1] | Budget compatibility score [0.6, 1.0] |
| `pace_alignment` | float [0, 1] | Pace compatibility score [0.6, 1.0] |
| `predicted_rating` | float [1, 5] | Noise-free rating (norm_dot × 6.5 + 1.2 + bonus) |
| `rating_source` | string | Always "synthetic" |

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
