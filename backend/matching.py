"""
Compatibility scoring — mirrors generate_synthetic.py formula.
"""

import math
from typing import Optional

from sqlalchemy.orm import Session

from models import Tourist, Guide
from database import compute_dot_range


def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


def unit_vector(v: list[float]) -> list[float]:
    norm = math.sqrt(sum(x * x for x in v))
    return [x / norm for x in v] if norm else v


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
}

TIER_MAP = {"budget": 0.2, "mid": 0.55, "premium": 0.9}


def interest_vec(tourist: Tourist) -> list[float]:
    return [tourist.food_interest, tourist.culture_interest, tourist.adventure_interest]


def expertise_vec(guide: Guide) -> list[float]:
    ev = [0.0, 0.0, 0.0]
    for tag in guide.expertise_tags.split("|"):
        if tag in EXPERTISE_MAP:
            for i, v in enumerate(EXPERTISE_MAP[tag]):
                ev[i] = max(ev[i], v)
    return unit_vector(ev) if any(ev) else ev


def raw_dot(tourist: Tourist, guide: Guide) -> float:
    return sum(a * b for a, b in zip(interest_vec(tourist), expertise_vec(guide)))


def compatibility_score(tourist: Tourist, guide: Guide, dot_range: tuple[float, float]) -> float:
    """
    Matches generate_synthetic.py formula:
      norm_dot = (raw_dot - dot_min) / (dot_max - dot_min)
      true_rating = norm_dot * 6.5 + 1.2 + bonus
      bonus = lang_match * 0.30 + (compat - 0.8) * 0.15
    Returns raw compatibility score (pre-noise, scaled 1-5).
    """
    dot_min, dot_max = dot_range
    nd = (raw_dot(tourist, guide) - dot_min) / (dot_max - dot_min)

    lang_match = 1.0 if tourist.language in [lp.split("→")[0] for lp in guide.language_pairs.split("|")] else 0.0

    budget_diff = abs(tourist.budget_level - TIER_MAP.get(guide.budget_tier, 0.55))
    budget_compat = clamp(1.0 - budget_diff * 0.40, 0.6, 1.0)

    pace_diff = abs(tourist.pace_preference - guide.pace_style)
    pace_compat = clamp(1.0 - pace_diff * 0.35, 0.6, 1.0)

    compat = budget_compat * pace_compat
    bonus = lang_match * 0.30 + (compat - 0.8) * 0.15

    return clamp(nd * 6.5 + 1.2 + bonus, 1.0, 5.0)


def top_matches(tourist: Tourist, guides: list[Guide], dot_range: tuple[float, float], top_n: int = 5) -> list[dict]:
    """Return top-N scored guides for a tourist."""
    scored = []
    for guide in guides:
        score = compatibility_score(tourist, guide, dot_range)
        scored.append({
            "guide_id": guide.id,
            "score": round(score, 2),
            "lang_match": tourist.language in [lp.split("→")[0] for lp in guide.language_pairs.split("|")],
        })
    scored.sort(key=lambda x: x["score"], reverse=True)
    return scored[:top_n]
