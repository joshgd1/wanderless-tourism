# Phase 5 — Implications: WanderLess Customer Segmentation

**Date**: 2026-04-26
**Status**: AWAITING DATA — Phase 4 leaderboard is template only
**Data dependency**: Phase 4 sweep must be executed with pilot data before this document produces actionable output

---

## Section 1: Candidate Comparison Table

> **Note**: All metric values below are "REQUIRES DATA" from Phase 4 execution. This table documents the interpretive framework and column definitions, not actual results.

### Candidate Comparison Framework

| Model / Algorithm             | Separation                                                                                            | Stability                                                                                      | Training Complexity                                                  | Interpretability                                                                                                                                               |
| ----------------------------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **KMeans (K=3)**              | Separation: measured by Silhouette score; higher = tighter cluster separation                         | Stability: average ARI across 10 bootstrap resamples; higher = more stable cluster assignments | O(n·K·I) where n=samples, K=3, I=iterations; linear in n; fastest    | High — centroid is a real data point; distance-to-centroid is directly explainable; cluster membership is binary and unambiguous                               |
| **DBSCAN**                    | Separation: density connectivity; clusters have irregular shapes; no centroid-based separation metric | Stability: ARI across resamples may be low if eps is near a density boundary                   | O(n²) in worst case; sensitive to eps                                | Medium — cluster labels include outliers (-1); noise points complicate segment definition; eps sensitivity makes production monitoring complex                 |
| **GaussianMixture**           | Separation: estimated Gaussian covariance; soft assignment probabilities; log-likelihood available    | Stability: ARI across resamples; may be unstable if components overlap significantly           | O(n·K·M) where M=features; EM iterations until convergence; moderate | Medium — soft assignments are business-friendly (confidence scores); cluster means are real vectors; but Gaussian assumption may not hold for interest vectors |
| **Random Uniform (Baseline)** | Separation: zero by construction; Silhouette ≈ 0                                                      | Stability: N/A; random assignments have zero reproducibility                                   | O(n); constant                                                       | None — no structure learned; purely random assignment over K=3                                                                                                 |

### Column Definitions (Business Translation)

| Metric                  | What It Measures                                            | Business Meaning                                                                                                       |
| ----------------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Separation**          | How distinct the clusters are from each other               | Whether segments are meaningfully different or overlap enough to be the same segment                                   |
| **Stability**           | Whether the same model run twice produces the same segments | Whether the model is safe to act on — unstable segments mean different tourists get different labels on different days |
| **Training Complexity** | Computational cost and operational overhead                 | Whether the model can be retrained daily on new data without infrastructure strain                                     |
| **Interpretability**    | How easily a business team can explain what each segment is | Whether marketing and product can use segment labels without a data scientist in the loop                              |

---

## Section 2: Business Profiles (Top 2 Candidates — Framework)

> **Note**: These profiles describe what each candidate's output _would look like_ in business language, once data exists. Profiles are illustrative — actual cluster characteristics await Phase 4 execution.

### Candidate A: KMeans (K=3)

**How to read a KMeans business profile**:
KMeans produces three distinct centroid profiles. Each centroid represents the "average tourist" in that segment. For each segment, business teams would receive:

- A plain-language label (e.g., "The Experience Seeker")
- A list of top distinguishing traits
- A suggested matching strategy for guides

**Illustrative segment descriptions** (pending data):

| Segment   | Profile                                                                                                                                                                                                                                                             |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Segment 1 | Travelers who prioritize cultural immersion and authentic local connection. They plan ahead, prefer small groups, and are willing to pay premium prices for a guide who shares their depth of interest. They tend to book 1-2 experiences per trip and rate highly. |
| Segment 2 | Spontaneous, budget-conscious travelers who value flexibility and social atmosphere. They prefer group tours, shorter experiences, and often book last-minute. Lower repeat rate unless the guide creates a strong personal connection.                             |
| Segment 3 | High-engagement travelers with specific niche interests (food, adventure, photography). They book multiple experiences per trip, research extensively before arriving, and are most likely to become repeat platform users.                                         |

**Business action**: Marketing would target each segment differently; matching would weight guide traits differently for each; success metrics (repeat rate, NPS) would be tracked per segment.

---

### Candidate B: GaussianMixture

**How to read a GMM business profile**:
GMM produces three soft segments with probability scores per tourist. Each tourist belongs to all three segments with different weights. Business teams would receive:

- A primary segment assignment (highest probability)
- A secondary segment affinity (second-highest probability)
- An "uncertainty score" (if probabilities are close to equal, the tourist is a genuine cross-segment traveler)

**Illustrative segment descriptions** (pending data):

| Segment                          | Profile                                                                                                                                                                                                                   |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Segment 1 (High confidence)      | Strongly food-motivated travelers, often couples or small groups. They have clear preferences and high satisfaction when matched with a guide whose expertise aligns. Low variability in outcomes.                        |
| Segment 2 (Mixed affinity)       | Travelers who don't fit a single profile — may show high food AND adventure scores simultaneously. These cross-segment travelers are at highest risk of poor matching if the system forces a single-label assignment.     |
| Segment 3 (Niche expert seekers) | Travelers with very specific goals (photography, wellness, history). They have strong opinions and less tolerance for mismatch. High satisfaction when matched precisely; very low satisfaction when matched generically. |

**Business action**: Cross-segment travelers (Segment 2) would receive hybrid matching — multiple guide recommendations for different aspects of their trip. Uncertainty score would trigger a "profile enrichment" prompt to improve matching confidence.

---

## Section 3: Recommendation

> **Cannot be determined until Phase 4 sweep executes with real data.**

**Framework for the recommendation decision**:

The recommended candidate will be the one that best balances three criteria (in priority order):

1. **Stability** (highest weight): Unsupervised segments that shift on every retrain are operationally unusable. A model with Silhouette 0.45 but ARI > 0.80 across resamples is preferable to Silhouette 0.60 but ARI < 0.50.

2. **Interpretability** (second weight): Business teams must be able to use segment labels in product and marketing decisions without data science support. Centroid-based models (KMeans) have a structural advantage here.

3. **Practical separation** (third weight): Segments must be meaningfully different — not just statistically different in a feature space, but different enough to warrant different matching strategies and different enough that tourists recognize themselves in the description.

**Decision rule** (to be applied when data exists):

```
IF KMeans stability (avg ARI) >= 0.70:
    RECOMMEND KMeans
ELIF GMM stability (avg ARI) >= 0.70 AND GMM Silhouette > KMeans Silhouette:
    RECOMMEND GMM
ELSE:
    FLAG "Insufficient stability for production deployment" — requires model iteration
```

---

## Section 4: Rejected Alternatives

For every candidate not recommended (including baseline):

| Candidate                       | Rejection Reason                                                                                                                                                                                                                                                                                      |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **KMeans** (if rejected)        | Rejected only if stability (avg ARI) < 0.70 across bootstrap resamples — segments are not reproducible enough to act on; different tourists would be labeled differently each week, making marketing campaigns and matching strategies unreliable                                                     |
| **DBSCAN** (if not recommended) | Rejected if average Silhouette score falls below 0.30 — indicates that density-based clusters are not meaningfully separated; additionally, the presence of outlier-labeled points (-1) complicates segment-based product strategy since a portion of tourists cannot be assigned to any segment      |
| **GMM** (if rejected)           | Rejected only if stability (avg ARI) < 0.70 — soft assignments are business-friendly in principle but become operationally complex if cluster assignments shift significantly across retrains; the Gaussian assumption may also produce degenerate covariance matrices if interest vectors are sparse |
| **Random Uniform Baseline**     | Rejected unconditionally — random assignment establishes the performance floor; any production model must beat random on both separation and stability to justify deployment                                                                                                                          |

---

## Interpretive Guidance for When Data Exists

### Reading the Leaderboard (Checklist)

When Phase 4 produces actual numbers, apply this checklist before accepting any candidate:

| Check | Question                                                 | Pass Condition                                                                |
| ----- | -------------------------------------------------------- | ----------------------------------------------------------------------------- |
| 1     | Is KMeans stability (avg ARI) ≥ 0.70?                    | If NO — KMeans is too unstable for production                                 |
| 2     | Is GMM stability (avg ARI) ≥ 0.70?                       | If NO — GMM soft assignments will shift too much                              |
| 3     | Is best Silhouette > 0.10 above Random baseline?         | If NO — segments barely beat random assignment                                |
| 4     | Are all cluster sizes between 10% and 80% of population? | If NO — a cluster is too small to be actionable or too large to be distinct   |
| 5     | Does DBSCAN label > 20% of data as outliers (-1)?        | If YES — too many tourists can't be segmented; may indicate eps is too strict |

### Business Translation Checklist

After passing the leaderboard checklist, validate that segment labels are business-meaningful:

| Segment Test    | Question                                                                   |
| --------------- | -------------------------------------------------------------------------- |
| Distinctiveness | Can you describe each segment in one sentence without using feature names? |
| Actionability   | Does each segment warrant a different matching strategy?                   |
| Recognizability | Would a tourist recognize themselves in the segment description?           |
| Stability       | Does the segment label remain meaningful if you retrain tomorrow?          |

---

**Status**: FRAMEWORK COMPLETE — Awaiting Phase 4 data execution to produce actionable implications
