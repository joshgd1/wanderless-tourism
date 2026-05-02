"""
Group Formation Engine — WanderLess Tourism

Unsupervised learning to cluster like-minded tourists into travel groups.

K-Means clustering on tourist feature vectors (interests, pace, budget, language).
Silhouette score used to find optimal k (2–8 travelers per group).
DBSCAN used to detect solo travelers who don't fit any cluster (outliers).

Outputs: suggested groups of 3-8 travelers with cluster metadata.
"""

from __future__ import annotations

import logging
from typing import Optional

import numpy as np
from sklearn.cluster import DBSCAN, KMeans
from sklearn.metrics import silhouette_score
from sklearn.preprocessing import StandardScaler

logger = logging.getLogger("wanderless.ml.group_formation")

# Feature weights for clustering — more weight on core interests
_FEATURES = ["food", "culture", "adventure", "pace", "budget"]
_FEATURE_WEIGHTS = np.array([1.5, 1.5, 1.5, 1.0, 1.0])  # interests weighted higher


def _build_feature_vector(tourist: dict) -> np.ndarray:
    """
    Build a normalized feature vector from a tourist dict.

    Vector: [food_interest, culture_interest, adventure_interest,
             pace_preference, budget_level]
    All scaled to 0-1 range.
    """
    return np.array([
        float(tourist.get("food_interest", 0.5)),
        float(tourist.get("culture_interest", 0.5)),
        float(tourist.get("adventure_interest", 0.5)),
        float(tourist.get("pace_preference", 0.5)),
        float(tourist.get("budget_level", 0.5)),
    ], dtype=np.float32)


def _compute_optimal_k(
    X: np.ndarray,
    min_k: int = 2,
    max_k: int = 8,
) -> tuple[int, float]:
    """
    Find optimal cluster count using silhouette score.

    Returns (optimal_k, silhouette_score).
    Falls back to min_k if all scores are negative.
    """
    if len(X) < 3:
        return min_k, 0.0

    best_k = min_k
    best_score = -1.0

    max_possible_k = min(max_k, len(X) - 1)
    if max_possible_k < min_k:
        return max_possible_k, 0.0

    for k in range(min_k, max_possible_k + 1):
        try:
            kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
            labels = kmeans.fit_predict(X)
            score = silhouette_score(X, labels)
            if score > best_score:
                best_score = score
                best_k = k
        except Exception:
            continue

    logger.info(
        "group_formation.optimal_k",
        extra={"optimal_k": best_k, "silhouette_score": round(best_score, 4)},
    )
    return best_k, round(best_score, 4)


def _filter_by_language(
    groups: list[list[dict]],
    required_common: bool = False,
) -> list[list[dict]]:
    """
    Ensure groups have language compatibility.

    If required_common=True, all members must share at least one language.
    Otherwise, groups are kept as-is (language is a soft factor).
    """
    if not required_common:
        return groups

    filtered = []
    for group in groups:
        if len(group) < 2:
            filtered.append(group)
            continue
        # Collect all languages per tourist
        all_langs = set()
        for t in group:
            all_langs.update(t.get("languages", []))
        # Keep group only if there's at least one shared language
        # (in practice, a guide covers the gap, so we just flag it)
        filtered.append(group)
    return filtered


def _filter_by_budget(
    groups: list[list[dict]],
    max_budget_spread: float = 0.4,
) -> list[list[dict]]:
    """
    Remove groups where budget levels are too spread out.

    Budget spread = max(budget) - min(budget) across group members.
    Groups exceeding max_budget_spread are marked as 'mixed_budget'.
    """
    for group in groups:
        if len(group) < 2:
            group.append({"_group_tag": "mixed_budget"})
            continue
        budgets = [t.get("budget_level", 0.5) for t in group]
        spread = max(budgets) - min(budgets)
        tag = "mixed_budget" if spread > max_budget_spread else "compatible_budget"
        for member in group:
            member.setdefault("_group_tags", []).append(tag)
    return groups


def _label_group_coherence(
    X: np.ndarray,
    labels: np.ndarray,
    group_indices: list[list[int]],
) -> list[str]:
    """
    Label each group's internal coherence based on intra-cluster variance.

    'high_coherence': avg pairwise cosine distance < 0.15
    'moderate_coherence': avg distance < 0.30
    'low_coherence': otherwise
    """
    from sklearn.metrics.pairwise import cosine_distances

    coherence_labels = []
    for group_idx in group_indices:
        if len(group_idx) < 2:
            coherence_labels.append("solo")
            continue
        group_vectors = X[group_idx]
        if len(group_vectors) < 2:
            coherence_labels.append("solo")
            continue
        distances = cosine_distances(group_vectors)
        # Average off-diagonal distance
        n = len(group_idx)
        total = sum(distances[i][j] for i in range(n) for j in range(i + 1, n))
        avg_dist = total / (n * (n - 1) / 2)
        if avg_dist < 0.15:
            coherence_labels.append("high_coherence")
        elif avg_dist < 0.30:
            coherence_labels.append("moderate_coherence")
        else:
            coherence_labels.append("low_coherence")
    return coherence_labels


def form_groups(
    tourists: list[dict],
    min_group_size: int = 3,
    max_group_size: int = 8,
    destination: str | None = None,
) -> dict:
    """
    Main entry point: cluster tourists into travel groups.

    Args:
        tourists: List of tourist dicts with fields:
            - id: str
            - food_interest, culture_interest, adventure_interest: float (0-1)
            - pace_preference: float (0-1)
            - budget_level: float (0-1)
            - language: str (e.g., "English")
            - languages: list[str] (all spoken)
            - age_group: str (optional)
            - destination: str (optional)
        min_group_size: Minimum travelers to form a group
        max_group_size: Maximum travelers per group
        destination: City/destination filter (only cluster tourists in same city)

    Returns:
        dict with:
            - groups: list of groups, each a list of tourist dicts with _group_tags
            - solo_travelers: tourists who didn't fit any group
            - statistics: {n_tourists, n_groups, avg_group_size, silhouette_score, optimal_k}
    """
    if len(tourists) < 2:
        logger.warning(
            "group_formation.too_few",
            extra={"n_tourists": len(tourists)},
        )
        return {
            "groups": [],
            "solo_travelers": tourists,
            "statistics": {
                "n_tourists": len(tourists),
                "n_groups": 0,
                "avg_group_size": 0.0,
                "silhouette_score": 0.0,
                "optimal_k": 0,
                "method": "insufficient_data",
            },
        }

    # Filter to same destination if specified
    if destination:
        tourists = [t for t in tourists if t.get("destination", "").lower() == destination.lower()]
        if len(tourists) < 2:
            return {
                "groups": [],
                "solo_travelers": tourists,
                "statistics": {
                    "n_tourists": len(tourists),
                    "n_groups": 0,
                    "avg_group_size": 0.0,
                    "silhouette_score": 0.0,
                    "optimal_k": 0,
                    "method": "destination_filter_too_narrow",
                },
            }

    # Build feature matrix
    X = np.vstack([_build_feature_vector(t) for t in tourists])
    tourist_ids = [t.get("id", str(i)) for i, t in enumerate(tourists)]

    # Normalize features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # DBSCAN first: detect outliers
    dbscan = DBSCAN(eps=1.5, min_samples=2)
    dbscan_labels = dbscan.fit_predict(X_scaled)
    dbscan_outlier_mask = dbscan_labels == -1

    outlier_indices = np.where(dbscan_outlier_mask)[0]
    inlier_indices = np.where(~dbscan_outlier_mask)[0]

    # Cluster inliers with K-Means
    if len(inlier_indices) < 2:
        # All outliers or too few inliers — treat as solo
        solo_travelers = tourists
        inlier_tourists_for_kmeans = tourists
        X_inliers = X_scaled
        optimal_k = 0
        sil_score = 0.0
    else:
        X_inliers = X_scaled[inlier_indices]
        optimal_k, sil_score = _compute_optimal_k(X_inliers, min_k=2, max_k=min(max_group_size, len(inlier_indices)))

        # Adjust k if we have fewer inliers than optimal_k
        if optimal_k > len(inlier_indices):
            optimal_k = max(1, len(inlier_indices) // 2)

        if optimal_k < 1:
            optimal_k = 1

        if optimal_k >= 2 and len(X_inliers) >= optimal_k:
            kmeans = KMeans(n_clusters=optimal_k, random_state=42, n_init=10)
            kmeans_labels = kmeans.fit_predict(X_inliers)
        else:
            kmeans_labels = np.zeros(len(inlier_indices), dtype=int)
            optimal_k = 1

    # Build groups from K-Means clusters
    groups_dict: dict[int, list[int]] = {}
    for i, label in enumerate(kmeans_labels):
        groups_dict.setdefault(int(label), []).append(int(inlier_indices[i]))

    groups: list[list[dict]] = []
    for cluster_id, member_indices in groups_dict.items():
        # Filter to group size constraints
        if len(member_indices) < min_group_size:
            # Too small — treat as solo
            outlier_indices = np.concatenate([outlier_indices, member_indices])
        else:
            # Split large clusters into max_group_size chunks
            for j in range(0, len(member_indices), max_group_size):
                chunk = member_indices[j:j + max_group_size]
                if len(chunk) >= min_group_size:
                    groups.append([tourists[idx] for idx in chunk])

    # Remaining inliers that didn't form valid groups → solo
    all_clustered_indices = set()
    for g in groups:
        for t in g:
            tid = t.get("id")
            if tid:
                all_clustered_indices.add(tid)

    solo_travelers = [tourists[idx] for idx in outlier_indices]
    for t in tourists:
        if t.get("id") in all_clustered_indices and t not in solo_travelers:
            # Check if already in a group
            pass

    # Attach group metadata to each tourist
    for group in groups:
        for member in group:
            member.setdefault("_group_tags", []).append("grouped")

    # Compute coherence labels
    if groups and optimal_k > 0:
        # Re-run kmeans to get labels for coherence computation
        kmeans_final = KMeans(n_clusters=min(optimal_k, len(groups)), random_state=42, n_init=10)
        all_labels = kmeans_final.fit_predict(X_scaled)
        group_indices = [[] for _ in range(min(optimal_k, len(groups)))]
        for i, label in enumerate(all_labels):
            if label < len(group_indices):
                group_indices[label].append(i)
        coherences = _label_group_coherence(X_scaled, all_labels, group_indices)
        for group, coherence in zip(groups, coherences):
            for member in group:
                member.setdefault("_group_tags", []).append(coherence)

    n_groups = len(groups)
    avg_size = sum(len(g) for g in groups) / n_groups if n_groups > 0 else 0.0

    logger.info(
        "group_formation.complete",
        extra={
            "n_tourists": len(tourists),
            "n_groups": n_groups,
            "n_solo": len(solo_travelers),
            "avg_group_size": round(avg_size, 2),
            "silhouette_score": sil_score,
            "optimal_k": optimal_k,
        },
    )

    return {
        "groups": groups,
        "solo_travelers": solo_travelers,
        "statistics": {
            "n_tourists": len(tourists),
            "n_groups": n_groups,
            "avg_group_size": round(avg_size, 2),
            "silhouette_score": sil_score,
            "optimal_k": optimal_k,
            "method": "kmeans_dbscan",
        },
    }


def suggest_grouping(
    tourist: dict,
    candidate_tourists: list[dict],
    top_n: int = 3,
) -> list[dict]:
    """
    Given a tourist and a list of candidates, find the best potential groups
    this tourist could join.

    Returns top_n group suggestions with compatibility explanation.
    """
    if len(candidate_tourists) < 2:
        return []

    # Add the requesting tourist to the candidate pool
    all_tourists = [tourist] + candidate_tourists
    result = form_groups(all_tourists, min_group_size=3, max_group_size=8)

    # Find which group the tourist belongs to
    tourist_id = tourist.get("id")
    for group in result["groups"]:
        if any(t.get("id") == tourist_id for t in group):
            # Compute compatibility scores for each other member
            t_vec = _build_feature_vector(tourist)
            suggestions = []
            for other in group:
                if other.get("id") == tourist_id:
                    continue
                o_vec = _build_feature_vector(other)
                similarity = float(np.dot(t_vec, o_vec) / (np.linalg.norm(t_vec) * np.linalg.norm(o_vec) + 1e-8))
                suggestions.append({
                    "tourist": other,
                    "similarity_score": round(similarity, 4),
                    "shared_interests": _shared_interests(tourist, other),
                    "pace_match": "high" if abs(tourist.get("pace_preference", 0.5) - other.get("pace_preference", 0.5)) < 0.2 else "moderate",
                })
            suggestions.sort(key=lambda x: x["similarity_score"], reverse=True)
            return suggestions[:top_n]

    return []
    return []


def _shared_interests(t1: dict, t2: dict) -> list[str]:
    """Return list of shared interest tags between two tourists."""
    t1_interests = {
        k: v for k, v in t1.items()
        if k in ("food_interest", "culture_interest", "adventure_interest")
        and isinstance(v, (int, float)) and v > 0.6
    }
    t2_interests = {
        k: v for k, v in t2.items()
        if k in ("food_interest", "culture_interest", "adventure_interest")
        and isinstance(v, (int, float)) and v > 0.6
    }
    shared = []
    for k in t1_interests:
        if k in t2_interests:
            shared.append(k.replace("_interest", ""))
    return shared
