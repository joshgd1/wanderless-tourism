"""
Review Intelligence — WanderLess Tourism

NLP-powered analysis of tourist reviews to extract actionable insights:
- Traveler-type tagging (solo, couple, family, group)
- Sentiment scoring per guide with confidence
- Topic extraction (food, culture, adventure, pace, safety)
- Improvement signals from negative reviews
- Guide strength profiling for better matching

No external NLP API required — rule-based + sklearn text features.
"""

from __future__ import annotations

import logging
import re
from typing import Optional

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans

logger = logging.getLogger("wanderless.ml.review_intelligence")

# ─── Traveler-type patterns ─────────────────────────────────────────────────────

TRAVELER_TYPE_PATTERNS = {
    "solo": [
        r"\bsolo\b", r"\balone\b", r"\b solo traveler\b", r"\bby myself\b",
        r"\bjust me\b", r"\b Single\b", r"\b solo \b",
    ],
    "couple": [
        r"\bcouple\b", r"\bpartner\b", r"\bwife\b", r"\bhusband\b",
        r"\bmy partner\b", r"\bmy better half\b", r"\b romance\b",
        r"\b两人\b", r"\b情侣\b",
    ],
    "family": [
        r"\bfamily\b", r"\bkids?\b", r"\bchildren\b", r"\bteenagers?\b",
        r"\bparents?\b", r"\bgrandparent\b", r"\bmother\b", r"\bfather\b",
        r"\bwith kids\b", r"\bfamily with\b", r"\b三口之家\b",
    ],
    "group": [
        r"\bgroup\b", r"\bfriends\b", r"\bfriend\b", r"\bfriend.?s\b",
        r"\bcrew\b", r"\bpack\b", r"\bteam\b", r"\bour group\b",
        r"\b一群\b", r"\b朋友\b",
    ],
}

# ─── Topic keyword dictionaries ───────────────────────────────────────────────

TOPIC_KEYWORDS = {
    "food": [
        "food", "eating", "restaurant", "meal", "breakfast", "lunch", "dinner",
        "cuisine", "dish", "dishes", "local food", "street food", "thali",
        "noodle", "rice", "curry", "spicy", "delicious", "tasty", "flavor",
        "chef", "cooking", "market", "stall", "eating tour", "foodie",
    ],
    "culture": [
        "temple", "temples", "history", "historical", "museum", "heritage",
        "ancient", "tradition", "traditional", "culture", "cultural", "ritual",
        "ceremony", "festivals", "art", "artist", "painting", "sculpture",
        "architecture", "spiritual", "meditation", "buddhist", "buddhism",
        "老挝", "佛教", "寺庙",
    ],
    "adventure": [
        "trek", "trekking", "hiking", "adventure", "racing", "cycling",
        "bike", "mountain", "jungle", "waterfall", "kayak", "rafting",
        "climbing", "atv", "buggy", "zip", "zipline", "bungee", "diving",
        "snorkeling", "swimming", "beach", "island", "koh", "phi phi",
    ],
    "pace": [
        "pace", "fast", "slow", "relaxed", "leisurely", "rushed",
        "hectic", "comfortable", "easy", "tiring", "exhausting",
        "energy", "tired", "rest", "break", "schedule", "itinerary",
    ],
    "safety": [
        "safe", "safety", "dangerous", "danger", "secure", "security",
        "cautious", "careful", "risk", "accident", "health", "medical",
        "emergency", "police", "scam", "warned", "avoid", "precaution",
    ],
    "value": [
        "value", "money", "worth", "price", "expensive", "cheap",
        "affordable", "overpriced", "bargain", "deal", "tip", "tipping",
        "cost", "budget", "charge", "fee", "pay",
    ],
    "logistics": [
        "pickup", "pick-up", "transport", "transportation", "driver",
        "car", "van", "bus", "transfer", "hotel", "accommodation",
        "flight", "airport", "arranged", "convenient", "organized",
        "communication", "respond", "reply", "booking",
    ],
}

# ─── Sentiment lexicons (simple VADER-style) ─────────────────────────────────

POSITIVE_WORDS = {
    "amazing": 1.5, "fantastic": 1.5, "excellent": 1.5, "outstanding": 1.5,
    "perfect": 1.5, "wonderful": 1.3, "brilliant": 1.3, "superb": 1.3,
    "great": 1.0, "good": 0.8, "nice": 0.6, "lovely": 0.7,
    "helpful": 0.8, "friendly": 0.8, "knowledgeable": 0.9, "professional": 0.8,
    "recommend": 1.0, "loved": 1.2, "enjoyed": 1.0, "beautiful": 0.9,
    "incredible": 1.4, "memorable": 1.1, "unforgettable": 1.3,
    "best": 1.5, "loved": 1.2, "exceptional": 1.5,
}

NEGATIVE_WORDS = {
    "terrible": -1.5, "awful": -1.5, "horrible": -1.5, "disaster": -1.5,
    "worst": -1.5, "bad": -1.0, "poor": -1.0, "disappointing": -1.2,
    "disappointed": -1.2, "rude": -1.2, "unprofessional": -1.2,
    "overpriced": -0.8, "expensive": -0.6, "unsafe": -1.3, "dangerous": -1.3,
    "boring": -1.0, "tired": -0.5, "rushed": -0.8, "slow": -0.4,
    "scam": -1.5, "avoid": -1.0, "regret": -1.2, "waste": -1.0,
    "dirty": -1.0, "broken": -0.8, "cold": -0.5, "wet": -0.5,
}


def _compute_sentiment_score(text: str) -> tuple[float, float]:
    """
    Compute a sentiment score (-1 to 1) and confidence (0 to 1) for review text.
    Uses word-list matching with intensification.
    """
    if not text:
        return 0.0, 0.0

    words = re.findall(r"\b\w+\b", text.lower())
    if not words:
        return 0.0, 0.0

    score = 0.0
    word_count = 0

    intensifiers = {"very": 1.5, "really": 1.4, "extremely": 1.6, "absolutely": 1.5,
                    "incredibly": 1.4, "so": 1.3, "quite": 1.2}

    prev_word = None
    for word in words:
        if word in POSITIVE_WORDS:
            mult = intensifiers.get(prev_word, 1.0)
            score += POSITIVE_WORDS[word] * mult
            word_count += 1
        elif word in NEGATIVE_WORDS:
            mult = intensifiers.get(prev_word, 1.0)
            score += NEGATIVE_WORDS[word] * mult
            word_count += 1
        prev_word = word

    if word_count == 0:
        return 0.0, 0.0

    raw = score / word_count
    # Clamp to [-1, 1]
    sentiment = max(-1.0, min(1.0, raw / 3.0))  # scale down since dict values are large
    # Confidence based on how many sentiment words fired
    confidence = min(1.0, word_count / 3.0)
    return round(sentiment, 4), round(confidence, 4)


def _extract_traveler_type(text: str) -> list[str]:
    """Detect traveler types mentioned in review text."""
    text_lower = text.lower()
    found = []
    for traveler_type, patterns in TRAVELER_TYPE_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, text_lower, re.IGNORECASE):
                if traveler_type not in found:
                    found.append(traveler_type)
                break
    return found


def _extract_topics(text: str) -> dict[str, float]:
    """Score each topic by keyword overlap with review text."""
    text_lower = text.lower()
    scores = {}
    for topic, keywords in TOPIC_KEYWORDS.items():
        count = sum(1 for kw in keywords if kw in text_lower)
        # Normalize by text length to avoid bias toward long reviews
        score = count / max(1, len(text_lower) / 200)
        scores[topic] = round(min(1.0, score), 4)
    return scores


def _extract_ngrams(text: str, n: int = 2) -> list[str]:
    """Extract significant n-grams from review text."""
    words = re.findall(r"\b[a-z]{3,}\b", text.lower())
    words = [w for w in words if w not in {
        "the", "and", "for", "was", "were", "with", "this", "that",
        "have", "has", "had", "not", "but", "were", "from", "they",
        "been", "were", "have", "also", "very", "really", "just",
    }]
    ngrams = []
    for i in range(len(words) - n + 1):
        ngrams.append(" ".join(words[i:i+n]))
    return ngrams


def _flag_improvement_signals(text: str) -> list[str]:
    """Extract improvement signals from negative review aspects."""
    text_lower = text.lower()
    signals = []

    # Check for specific complaints
    if re.search(r"\b(pace|too fast|too slow|rushed|hectic|slow pace|relaxed pace)\b", text_lower):
        signals.append("pace_mismatch")
    if re.search(r"\b(unsafe|dangerous|scam|not safe|felt unsafe)\b", text_lower):
        signals.append("safety_concern")
    if re.search(r"\b(food|meal|restaurant|hungry|not fed)\b", text_lower):
        signals.append("food_issue")
    if re.search(r"\b(price|expensive|overpriced|worth|money|cheap)\b", text_lower):
        signals.append("value_concern")
    if re.search(r"\b(transport|pickup|van|car|driver|organized|communication)\b", text_lower):
        signals.append("logistics_issue")
    if re.search(r"\b(guide|team|staff|rude|unprofessional|attitude)\b", text_lower):
        signals.append("guide_mannerism")
    if re.search(r"\b(language|english|speak|communicate|translation)\b", text_lower):
        signals.append("language_barrier")
    if re.search(r"\b(itinerary|schedule|plan|organized|time|hours|rushed)\b", text_lower):
        signals.append("schedule_issue")

    return signals


class ReviewIntelligence:
    """
    Analyze a corpus of reviews to build guide profiles and extract insights.

    Public methods:
      analyze_guide(guide_id, reviews) → GuideProfile
      batch_analyze(reviews_with_guide) → list[GuideProfile]
      extract_guide_strengths(guide_profile) → dict
    """

    def __init__(self):
        self._guide_profiles: dict[str, dict] = {}
        self._all_reviews: list[str] = []
        self._tfidf: Optional[TfidfVectorizer] = None
        self._kmeans: Optional[KMeans] = None

    def analyze_guide(self, guide_id: str, reviews: list[dict]) -> dict:
        """
        Build a comprehensive profile for a single guide from their reviews.

        Args:
            guide_id: The guide's ID
            reviews: List of dicts with at least 'text' key. Optional: 'rating', 'tourist_id'

        Returns a GuideProfile dict:
          guide_id, n_reviews, avg_rating, avg_sentiment,
          traveler_types (counter), topic_scores (averaged),
          strengths (list), improvement_signals (list of lists per review),
          sentiment_trend (positive/negative/stable), top_ngrams,
          confidence (0-1 based on review count)
        """
        if not reviews:
            return {
                "guide_id": guide_id,
                "n_reviews": 0,
                "avg_rating": 0.0,
                "avg_sentiment": 0.0,
                "sentiment_confidence": 0.0,
                "traveler_types": {},
                "topic_scores": {},
                "strengths": [],
                "improvement_signals": [],
                "sentiment_trend": "no_data",
                "top_ngrams": [],
                "confidence": 0.0,
            }

        # Compute per-review metrics
        sentiments = []
        confidences = []
        ratings = []
        all_traveler_types: dict[str, int] = {}
        all_topic_scores: dict[str, list[float]] = {t: [] for t in TOPIC_KEYWORDS}
        all_improvement_signals: list[list[str]] = []
        all_ngrams: list[tuple[str, int]] = []  # (ngram, count)
        ngram_counts: dict[str, int] = {}

        for review in reviews:
            text = review.get("text", "")
            rating = review.get("rating")

            if rating:
                ratings.append(float(rating))

            sentiment, confidence = _compute_sentiment_score(text)
            sentiments.append(sentiment)
            confidences.append(confidence)

            for tt in _extract_traveler_type(text):
                all_traveler_types[tt] = all_traveler_types.get(tt, 0) + 1

            topic_scores = _extract_topics(text)
            for topic, score in topic_scores.items():
                all_topic_scores[topic].append(score)

            signals = _flag_improvement_signals(text)
            if signals:
                all_improvement_signals.append(signals)

            for ng in _extract_ngrams(text, 2):
                ngram_counts[ng] = ngram_counts.get(ng, 0) + 1

        # Aggregate
        avg_sentiment = np.mean(sentiments) if sentiments else 0.0
        avg_confidence = np.mean(confidences) if confidences else 0.0
        avg_rating = np.mean(ratings) if ratings else 0.0
        n_reviews = len(reviews)

        # Topic scores averaged across reviews
        topic_scores_agg = {
            t: round(np.mean(scores), 4) if scores else 0.0
            for t, scores in all_topic_scores.items()
        }

        # Top 10 n-grams
        top_ngrams = sorted(ngram_counts.items(), key=lambda x: x[1], reverse=True)[:10]
        top_ngrams = [ng for ng, _ in top_ngrams]

        # Sentiment trend
        if len(sentiments) >= 3:
            early = np.mean(sentiments[:len(sentiments)//2])
            late = np.mean(sentiments[len(sentiments)//2:])
            diff = late - early
            if diff > 0.1:
                sentiment_trend = "improving"
            elif diff < -0.1:
                sentiment_trend = "declining"
            else:
                sentiment_trend = "stable"
        else:
            sentiment_trend = "insufficient_data"

        # Strengths: top topics with avg score > 0.3
        strengths = [t for t, s in topic_scores_agg.items() if s > 0.3]
        # Add high-sentiment topics
        for review in reviews:
            text = review.get("text", "")
            sentiment, _ = _compute_sentiment_score(text)
            if sentiment > 0.3:
                topics_in_review = _extract_topics(text)
                for t, s in topics_in_review.items():
                    if s > 0.5 and t not in strengths:
                        strengths.append(t)

        # Confidence: more reviews = higher confidence, plateaus at 20
        confidence = min(1.0, n_reviews / 20.0)

        profile = {
            "guide_id": guide_id,
            "n_reviews": n_reviews,
            "avg_rating": round(avg_rating, 2),
            "avg_sentiment": round(avg_sentiment, 4),
            "sentiment_confidence": round(avg_confidence, 4),
            "traveler_types": all_traveler_types,
            "topic_scores": topic_scores_agg,
            "strengths": list(set(strengths))[:5],
            "improvement_signals": all_improvement_signals,
            "sentiment_trend": sentiment_trend,
            "top_ngrams": top_ngrams,
            "confidence": round(confidence, 4),
        }

        self._guide_profiles[guide_id] = profile
        return profile

    def get_guide_profile(self, guide_id: str) -> dict | None:
        """Return cached guide profile if available."""
        return self._guide_profiles.get(guide_id)

    def batch_analyze(self, reviews_by_guide: dict[str, list[dict]]) -> list[dict]:
        """Analyze multiple guides at once."""
        results = []
        for guide_id, reviews in reviews_by_guide.items():
            profile = self.analyze_guide(guide_id, reviews)
            results.append(profile)
        return results

    def matching_tags_for_guide(self, guide_id: str) -> dict[str, list[str]]:
        """
        Return tags useful for guide-tourist matching.
        Combines traveler types the guide excels with + their top topics.
        """
        profile = self._guide_profiles.get(guide_id)
        if not profile:
            return {"traveler_types": [], "topics": [], "sentiment": "unknown"}

        top_travelers = sorted(
            profile["traveler_types"].items(),
            key=lambda x: x[1], reverse=True
        )[:3]
        top_travelers = [t for t, _ in top_travelers]

        return {
            "traveler_types": top_travelers,
            "topics": profile["strengths"],
            "sentiment": (
                "positive" if profile["avg_sentiment"] > 0.2
                else "negative" if profile["avg_sentiment"] < -0.2
                else "neutral"
            ),
            "confidence": profile["confidence"],
        }


# ─── Singleton ────────────────────────────────────────────────────────────────

_intelligence: Optional[ReviewIntelligence] = None


def get_review_intelligence() -> ReviewIntelligence:
    global _intelligence
    if _intelligence is None:
        _intelligence = ReviewIntelligence()
    return _intelligence
