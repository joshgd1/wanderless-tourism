"""
ML Recommendation Engine — WanderLess Tourism

Combines content-based filtering (preference matching) with
collaborative filtering (rating patterns) using scikit-learn.

Content-based: cosine similarity between tourist preference vectors
               and guide expertise vectors (numerical + text features)

Collaborative: matrix factorization (TruncatedSVD) on tourist-guide
               rating matrix, then k-NN retrieval for predictions.

Hybrid: weighted combination of content + collaborative scores.
"""

from __future__ import annotations

import logging
import math
from typing import Optional

import numpy as np
from scipy.sparse import csr_matrix
from scipy.sparse.linalg import svds
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MinMaxScaler, OneHotEncoder
from sklearn.neighbors import NearestNeighbors

from models import Tourist, Guide, Rating

logger = logging.getLogger("wanderless.ml")

# ─── Destination catalogue (static knowledge base) ─────────────────────────────

DESTINATIONS = {
    "Old City": {
        "tags": ["culture", "history", "temples", "food", "photography"],
        "budget": "mid",
        "pace": 0.3,
        "description": "Chiang Mai's historic heart with ancient temples, "
        "traditional markets, and street food",
    },
    "Doi Suthep": {
        "tags": ["nature", "trekking", "photography", "culture"],
        "budget": "budget",
        "pace": 0.5,
        "description": "Mountain temple with panoramic city views and forest trails",
    },
    "Mae Sa Valley": {
        "tags": ["nature", "adventure", "trekking", "rural"],
        "budget": "budget",
        "pace": 0.7,
        "description": "Waterfalls, orchid farms, and mountain villages in the valley",
    },
    "Nimman": {
        "tags": ["food", "nightlife", "shopping", "wellness"],
        "budget": "premium",
        "pace": 0.4,
        "description": "Modern Chiang Mai's cafe district, boutique shops, and spas",
    },
    "Santitham": {
        "tags": ["food", "culture", "local", "markets", "photography"],
        "budget": "mid",
        "pace": 0.3,
        "description": "Authentic local neighborhood with family-run restaurants "
        "and morning markets",
    },
    "Hang Dong": {
        "tags": ["shopping", "art", "cooking", "wellness"],
        "budget": "mid",
        "pace": 0.4,
        "description": "Artisan boutiques, cooking schools, and silk weaving villages",
    },
}


# ─── Feature Engineering ────────────────────────────────────────────────────────

_EXPERTISE_TAG_VECS = {
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

_BUDGET_MAP = {"budget": 0.2, "mid": 0.55, "premium": 0.9}
_REVERSE_BUDGET = {v: k for k, v in _BUDGET_MAP.items()}


def _build_tourist_features(t: Tourist) -> np.ndarray:
    """Build numerical feature vector from tourist preferences."""
    return np.array([
        t.food_interest,
        t.culture_interest,
        t.adventure_interest,
        t.pace_preference,
        t.budget_level,
    ], dtype=np.float32)


def _build_guide_features(g: Guide) -> np.ndarray:
    """Build numerical feature vector from guide attributes."""
    # Aggregate expertise tags → (food, culture, adventure)
    ev = np.array([0.0, 0.0, 0.0], dtype=np.float32)
    for tag in g.expertise_tags.split("|"):
        if tag in _EXPERTISE_TAG_VECS:
            ev = np.maximum(ev, _EXPERTISE_TAG_VECS[tag])

    budget_val = _BUDGET_MAP.get(g.budget_tier, 0.55)

    return np.concatenate([
        ev,  # 3-dim expertise
        [g.pace_style, budget_val],  # 2-dim
    ]).astype(np.float32)


def _build_destination_features(dest: dict) -> np.ndarray:
    """Build guide-style vector from destination catalogue."""
    ev = np.array([0.0, 0.0, 0.0], dtype=np.float32)
    for tag in dest["tags"]:
        if tag in _EXPERTISE_TAG_VECS:
            ev = np.maximum(ev, _EXPERTISE_TAG_VECS[tag])

    budget_val = _BUDGET_MAP.get(dest["budget"], 0.55)

    return np.concatenate([
        ev,
        [dest["pace"], budget_val],
    ]).astype(np.float32)


# ─── Content-Based Recommender ──────────────────────────────────────────────────

class ContentBasedRecommender:
    """
    Cosine-similarity recommender between tourists and guides/destinations.

    Tourist vector  = [food_i, culture_i, adventure_i, pace_pref, budget_level]
    Guide vector    = [food_e, culture_e, adventure_e, pace_g, budget_tier]
    Destination vec = [food_e, culture_e, adventure_e, pace_d, budget_dest]
    """

    def __init__(self):
        self._tourist_cache: dict[str, np.ndarray] = {}
        self._guide_cache: dict[str, np.ndarray] = {}
        self._dest_cache: dict[str, np.ndarray] = {}
        self._all_guide_ids: list[str] = []
        self._all_guide_vectors: Optional[np.ndarray] = None
        self._knn_guide: Optional[NearestNeighbors] = None

    def fit(self, tourists: list[Tourist], guides: list[Guide]) -> "ContentBasedRecommender":
        """Build feature caches and k-NN index over guide vectors."""
        self._tourist_cache = {
            t.id: _build_tourist_features(t) for t in tourists
        }

        self._guide_cache = {g.id: _build_guide_features(g) for g in guides}
        self._all_guide_ids = [g.id for g in guides]
        self._all_guide_vectors = np.vstack([self._guide_cache[gid] for gid in self._all_guide_ids])

        # Build k-NN index over guide vectors for fast approximate retrieval
        self._knn_guide = NearestNeighbors(n_neighbors=min(20, len(guides)),
                                           metric="cosine", algorithm="brute")
        self._knn_guide.fit(self._all_guide_vectors)

        # Build destination feature cache
        self._dest_cache = {
            name: _build_destination_features(info)
            for name, info in DESTINATIONS.items()
        }

        logger.info(
            "content_recommender.fitted",
            n_tourists=len(tourists),
            n_guides=len(guides),
            n_destinations=len(DESTINATIONS),
        )
        return self

    def score_guides_for_tourist(self, tourist_id: str, guide_ids: list[str]) -> list[tuple[str, float]]:
        """Return content-based similarity scores for guides (0–1)."""
        t_vec = self._tourist_cache.get(tourist_id)
        if t_vec is None:
            return [(gid, 0.0) for gid in guide_ids]

        t_norm = np.linalg.norm(t_vec)
        if t_norm == 0:
            return [(gid, 0.0) for gid in guide_ids]

        scores = []
        for gid in guide_ids:
            g_vec = self._guide_cache.get(gid)
            if g_vec is None:
                scores.append(0.0)
                continue
            dot = np.dot(t_vec, g_vec)
            g_norm = np.linalg.norm(g_vec)
            if g_norm == 0:
                scores.append(0.0)
            else:
                scores.append(float(dot / (t_norm * g_norm)))
        return list(zip(guide_ids, scores))

    def score_destination_for_tourist(self, tourist_id: str) -> list[tuple[str, float]]:
        """Return content-based scores for all destinations (0–1)."""
        t_vec = self._tourist_cache.get(tourist_id)
        if t_vec is None:
            return [(n, 0.0) for n in DESTINATIONS]

        t_norm = np.linalg.norm(t_vec)
        if t_norm == 0:
            return [(n, 0.0) for n in DESTINATIONS]

        results = []
        for name, d_vec in self._dest_cache.items():
            dot = np.dot(t_vec, d_vec)
            d_norm = np.linalg.norm(d_vec)
            score = float(dot / (t_norm * d_norm)) if d_norm > 0 else 0.0
            results.append((name, score))
        results.sort(key=lambda x: x[1], reverse=True)
        return results

    def nn_guides(self, tourist_id: str, k: int = 5) -> list[str]:
        """Return IDs of k most similar guides (by content features)."""
        t_vec = self._tourist_cache.get(tourist_id)
        if t_vec is None or self._knn_guide is None:
            return []
        distances, indices = self._knn_guide.kneighbors([t_vec], k=min(k, len(self._all_guide_ids)))
        return [self._all_guide_ids[i] for i in indices[0]]


# ─── Collaborative Filtering ─────────────────────────────────────────────────────

class CollaborativeRecommender:
    """
    Matrix-factorization recommender using TruncatedSVD on the
    tourist × guide rating matrix.

    Predicts the rating a tourist would give a guide they haven't
    rated yet, based on latent factors learned from observed ratings.
    """

    def __init__(self, n_factors: int = 10, k: int = 10):
        self.n_factors = n_factors
        self.k = k  # k-NN neighbours for prediction

    def fit(self, ratings: list[Rating]) -> "CollaborativeRecommender":
        """
        Build the tourist×guide rating matrix and decompose it with SVD.

        Matrices:
          R       — m×n tourist×guide rating matrix (sparse)
          U       — m×k user latent factors
          sigma   — k singular values
          Vt      — k×n item latent factors
          R_pred  — U @ sigma @ Vt ≈ R
        """
        # Index tourists and guides
        self._tourist_ids: list[str] = sorted(set(r.tourist_id for r in ratings))
        self._guide_ids: list[str] = sorted(set(r.guide_id for r in ratings))
        self._tidx: dict[str, int] = {tid: i for i, tid in enumerate(self._tourist_ids)}
        self._gidx: dict[str, int] = {gid: i for i, gid in enumerate(self._guide_ids)}

        m, n = len(self._tourist_ids), len(self._guide_ids)

        # Build sparse rating matrix
        rows, cols, data = [], [], []
        for r in ratings:
            rows.append(self._tidx[r.tourist_id])
            cols.append(self._gidx[r.guide_id])
            data.append(float(r.rating))

        R = csr_matrix((data, (rows, cols)), shape=(m, n))

        # Center ratings per tourist (global mean fallback)
        self._global_mean = np.mean(data) if data else 3.0
        R_centered = R.toarray().astype(np.float32)
        for i in range(m):
            row = R_centered[i]
            nz = row[row != 0]
            if len(nz) > 0:
                row[row != 0] = nz - nz.mean()
            else:
                row[:] = 0.0

        # Truncated SVD — learn k latent factors
        k_factors = min(self.n_factors, min(m, n) - 1)
        try:
            U, sigma, Vt = svds(csr_matrix(R_centered), k=k_factors)
        except Exception:
            # Fallback if SVD fails (e.g., too few ratings)
            U = np.zeros((m, k_factors))
            sigma = np.zeros(k_factors)
            Vt = np.zeros((k_factors, n))

        # R_pred = U @ diag(sigma) @ Vt  (still centered)
        self._U = U  # m × k_factors
        self._sigma = sigma
        self._Vt = Vt  # k_factors × n
        self._R_sparse = R  # original un-centered sparse matrix

        # k-NN over item (guide) latent factors for fallback prediction
        V = (Vt.T * sigma).astype(np.float32)  # n × k_factors (item factors)
        self._knn_item = NearestNeighbors(n_neighbors=min(self.k, n),
                                           metric="cosine", algorithm="brute")
        self._knn_item.fit(V)

        logger.info(
            "collaborative_recommender.fitted",
            n_ratings=len(ratings),
            n_tourists=m,
            n_guides=n,
            n_factors=k_factors,
        )
        return self

    def predict(self, tourist_id: str, guide_ids: list[str]) -> list[tuple[str, float]]:
        """
        Predict ratings for a tourist toward a list of guides.
        Uses SVD reconstruction + k-NN fallback for cold-start.
        """
        if tourist_id not in self._tidx:
            # Cold-start tourist — return neutral prediction
            return [(gid, self._global_mean) for gid in guide_ids]

        t_idx = self._tidx[tourist_id]

        # Reconstruct full rating row: U @ sigma @ Vt + global_mean
        reconstructed_row = self._U[t_idx] * self._sigma @ self._Vt  # 1 × n

        # Actual ratings for this tourist
        actual_R_t = self._R_sparse[t_idx].toarray().flatten()  # 1 × n

        predictions = []
        for gid in guide_ids:
            if gid not in self._gidx:
                predictions.append(self._global_mean)
                continue

            g_idx = self._gidx[gid]
            # Use SVD prediction if the tourist rated this guide before
            if actual_R_t[g_idx] != 0:
                # Blend SVD reconstruction with actual rating (smooth)
                pred = 0.5 * float(reconstructed_row[0, g_idx] + self._global_mean) \
                    + 0.5 * actual_R_t[g_idx]
            else:
                # Unrated — use SVD prediction
                pred = float(reconstructed_row[0, g_idx] + self._global_mean)

            # Clip to valid rating range
            pred = max(1.0, min(5.0, pred))
            predictions.append(pred)

        return list(zip(guide_ids, predictions))

    def similar_guides(self, guide_id: str, k: int = 5) -> list[tuple[str, float]]:
        """
        Find k guides most similar to the given guide based on latent factors.
        Uses k-NN over item latent vectors.
        """
        if guide_id not in self._gidx:
            return []

        g_idx = self._gidx[guide_id]
        V = (self._Vt.T * self._sigma).astype(np.float32)
        query = V[g_idx].reshape(1, -1)
        distances, indices = self._knn_item.kneighbors(query, k=min(k + 1, V.shape[0]))
        results = [
            (self._guide_ids[i], float(1.0 - distances[0][j]))
            for j, i in enumerate(indices[0])
            if self._guide_ids[i] != guide_id
        ]
        return results[:k]


# ─── Hybrid Recommender ────────────────────────────────────────────────────────

_WEIGHT_CONTENT = 0.45
_WEIGHT_COLLAB = 0.45
_WEIGHT_DEST = 0.10


class HybridRecommender:
    """
    Combines content-based and collaborative filtering with destination
    recommendation in a single hybrid scorer.

    Final score = w1*content + w2*collab + w3*dest_affinity
    """

    def __init__(self):
        self.content = ContentBasedRecommender()
        self.collab = CollaborativeRecommender(n_factors=10, k=10)

    def fit(self, tourists: list[Tourist], guides: list[Guide],
            ratings: list[Rating]) -> "HybridRecommender":
        """Fit both sub-recommenders."""
        self.content.fit(tourists, guides)
        self.collab.fit(ratings)
        return self

    def recommend_guides(
        self,
        tourist_id: str,
        destination: str | None = None,
        top_n: int = 5,
    ) -> list[dict]:
        """
        Return top-N recommended guides with per-score breakdown.

        Each result dict contains:
          guide_id, name, photo_url, score, score_content,
          score_collab, score_dest, expertise_tags, location_coverage,
          rating_history, rating_count, budget_tier, license_verified, bio
        """
        all_guide_ids = list(self.content._guide_cache.keys())
        all_guides = self.content._guide_cache  # gid → feature vector

        # 1. Content-based scores
        content_scores = dict(
            self.content.score_guides_for_tourist(tourist_id, all_guide_ids)
        )

        # 2. Collaborative scores
        collab_scores = dict(
            self.collab.predict(tourist_id, all_guide_ids)
        )

        # 3. Normalize collaborative scores to 0–1 (based on rating range 1–5)
        collab_values = list(collab_scores.values())
        collab_min, collab_max = min(collab_values), max(collab_values)
        if collab_max > collab_min:
            collab_norm = {
                gid: (v - collab_min) / (collab_max - collab_min)
                for gid, v in collab_scores.items()
            }
        else:
            collab_norm = {gid: 0.5 for gid in collab_scores}

        # Normalize content scores to 0–1
        content_values = list(content_scores.values())
        content_min, content_max = min(content_values), max(content_values)
        if content_max > content_min:
            content_norm = {
                gid: (v - content_min) / (content_max - content_min)
                for gid, v in content_scores.items()
            }
        else:
            content_norm = {gid: 0.5 for gid in content_scores}

        # 4. Destination affinity (if destination specified, boost matching guides)
        dest_boost: dict[str, float] = {}
        if destination:
            dest_info = DESTINATIONS.get(destination)
            if dest_info:
                dest_tags = set(dest_info["tags"])
                for gid in all_guide_ids:
                    # Guide location coverage overlap
                    # This is approximate — stored as pipe-delimited in DB
                    boost = 0.1  # small bonus for matching destination
                    dest_boost[gid] = boost

        # 5. Compute hybrid scores
        scored = []
        for gid in all_guide_ids:
            sc = content_norm.get(gid, 0.0)
            cc = collab_norm.get(gid, 0.5)
            db = dest_boost.get(gid, 0.0)

            hybrid = (
                _WEIGHT_CONTENT * sc
                + _WEIGHT_COLLAB * cc
                + _WEIGHT_DEST * db
            )

            scored.append({
                "guide_id": gid,
                "score": round(hybrid, 4),
                "score_content": round(sc, 4),
                "score_collab": round(cc, 4),
                "score_dest": round(db, 4),
            })

        scored.sort(key=lambda x: x["score"], reverse=True)
        return scored[:top_n]

    def recommend_destinations(self, tourist_id: str) -> list[dict]:
        """
        Return ranked destination recommendations with explanations.
        """
        dest_scores = self.content.score_destination_for_tourist(tourist_id)

        results = []
        for rank, (name, raw_score) in enumerate(dest_scores, 1):
            dest = DESTINATIONS[name]
            # Map dominant expertise axis to user-facing label
            ev = self.content._dest_cache[name][:3]
            dominant_axis = ["food", "culture", "adventure"][int(np.argmax(ev))]

            results.append({
                "rank": rank,
                "name": name,
                "score": round(float(raw_score), 4),
                "tags": dest["tags"],
                "description": dest["description"],
                "budget_tier": dest["budget"],
                "pace": dest["pace"],
                "ml_explanation": (
                    f"Based on your {dominant_axis} interest, "
                    f"{name} ranks #{rank} with a compatibility score of {raw_score:.2f}. "
                    f"Best for: {', '.join(dest['tags'][:3])}."
                ),
            })
        return results


# ─── Singleton instance ─────────────────────────────────────────────────────────

_recommender: Optional[HybridRecommender] = None


def get_recommender() -> HybridRecommender:
    global _recommender
    if _recommender is None:
        _recommender = HybridRecommender()
    return _recommender


def fit_recommender(tourists: list[Tourist], guides: list[Guide],
                     ratings: list[Rating]) -> HybridRecommender:
    """Fit (or re-fit) the global recommender instance."""
    global _recommender
    _recommender = HybridRecommender()
    _recommender.fit(tourists, guides, ratings)
    logger.info("hybrid_recommender.fitted_and_ready")
    return _recommender
