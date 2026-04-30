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

AUTHENTICITY_KEYWORDS = [
    "grew up", "born", "local family", "third generation",
    "neighborhood", "my city", "live in", "raised in", "my hometown",
    "authentic local", "local born",
]

LOCALITY_BONUS = 0.25

# Chiang Mai neighborhoods — used when tourist destination is "Chiang Mai"
CHIANG_MAI_NEIGHBORHOODS = {
    "old city", "nimman", "night bazaar", "do inthanon", "doi inthanon",
    "do suthep", "doi suthep", "do pui", "doi pui", "mae sa valley",
    "sankamphaeng", "hang dong", "saraphi", "sansai",
}
VERIFIED_BONUS = 0.20
MAX_REVIEW_BONUS = 0.50
MAX_BIO_BONUS = 0.30


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


def _bio_authenticity(bio: str | None) -> float:
    """Score how much bio signals authentic local knowledge."""
    if not bio:
        return 0.0
    bio_lower = bio.lower()
    matches = sum(1 for kw in AUTHENTICITY_KEYWORDS if kw in bio_lower)
    return min(matches * 0.10, MAX_BIO_BONUS)


def _location_match(guide: Guide, destination: str | None) -> float:
    """
    Bonus when guide covers the tourist's destination.
    For Chiang Mai, matches by neighborhood name in location_coverage.
    For other destinations, requires exact match.
    """
    if not destination or not guide.location_coverage:
        return 0.0
    dest_lower = destination.lower()
    covered = [loc.strip().lower() for loc in guide.location_coverage.split("|")]
    if dest_lower in covered:
        return LOCALITY_BONUS
    # Chiang Mai: check if guide covers any Chiang Mai neighborhood
    if dest_lower == "chiang mai":
        for neighborhood in CHIANG_MAI_NEIGHBORHOODS:
            if neighborhood in covered:
                return LOCALITY_BONUS
    return 0.0


def compatibility_score(
    tourist: Tourist,
    guide: Guide,
    dot_range: tuple[float, float],
    destination: str | None = None,
) -> float:
    """
    Interest-match core (norm_dot * 2.5) multiplied by authenticity premium,
    plus fixed offset and language/pace bonus:
      score = (norm_dot * 2.5 * auth_multiplier) + 1.2 + bonus
      bonus = lang_match * 0.30 + (compat - 0.8) * 0.15
      auth_multiplier = 1 + review_bonus + verified_bonus + bio_bonus + locality_bonus

    Authenticity signals differentiate truly local guides from tourist-oriented guides:
      review_bonus    = log(1 + rating_count) / 10  [max 0.50]
      verified_bonus  = 0.20 if license_verified else 0
      bio_bonus       = keyword matches for "grew up", "born", "local family", etc. [max 0.30]
      locality_bonus  = 0.25 if guide covers tourist's destination
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

    # Authenticity signals as multiplicative premium on the interest-match core only
    review_bonus = min(math.log1p(guide.rating_count or 1) / 10, MAX_REVIEW_BONUS)
    verified_bonus = VERIFIED_BONUS if guide.license_verified else 0.0
    bio_bonus = _bio_authenticity(guide.bio)
    locality_bonus = _location_match(guide, destination)

    auth_multiplier = 1.0 + review_bonus + verified_bonus + bio_bonus + locality_bonus

    # Core interest match × BASE (2.5) × auth multiplier, then fixed offsets and lang/pace bonus
    core = nd * 2.5 * auth_multiplier
    return clamp(core + 1.2 + bonus, 1.0, 5.0)


def top_matches(
    tourist: Tourist,
    guides: list[Guide],
    dot_range: tuple[float, float],
    top_n: int = 5,
    destination: str | None = None,
) -> list[dict]:
    """Return top-N scored guides for a tourist."""
    scored = []
    for guide in guides:
        score = compatibility_score(tourist, guide, dot_range, destination)
        scored.append({
            "guide_id": guide.id,
            "score": round(score, 2),
            "lang_match": tourist.language in [lp.split("→")[0] for lp in guide.language_pairs.split("|")],
        })
    scored.sort(key=lambda x: x["score"], reverse=True)
    return scored[:top_n]
