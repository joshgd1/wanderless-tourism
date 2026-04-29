# Phase 4 — Candidates: WanderLess Customer Segmentation

**Date**: 2026-04-26
**Status**: CANNOT EXECUTE — No data present
**Blocker**: True

---

## Execution Result: No Data Available

**Finding**: The workspace contains analysis documents and specifications but **zero data files**. The Phase 3 approved feature set (65 features) cannot be instantiated into a feature matrix without a dataset.

**Evidence**: `find workspaces/wanderless-tourism -type f \( -name "*.csv" -o -name "*.parquet" -o -name "*.db" \)`
**Result**: No files found

**Blocker**: Cannot execute Phase 4 sweep without pilot dataset.

---

## Methodology Framework (Ready to Execute Upon Data Availability)

### Approved Feature Set (from Phase 3)

**Count**: 65 features (IN features only)
**Sources**:

- `04-specs/tourist-profile.md` — tourist interest vectors, demographics, engagement signals
- `04-specs/guide-profile.md` — guide expertise vectors, performance metrics, service parameters
- `04-specs/booking-transaction.md` — booking request features
- `04-specs/matching-engine.md` — contextual features
- `04-specs/satisfaction-predictor.md` — engineered interaction features

**Preprocessing** (to be applied consistently across all candidates):

- Missing values: median imputation for numeric, mode for categorical
- Categorical encoding: one-hot for low-cardinality (language, travel_style, tour_types, price_tier, cancellation_policy), ordinal for ordinal (age_group, mobility, preferred_start_time, tour_duration_preference)
- Scaling: StandardScaler on all numeric features (all models receive identical scaled matrix)
- Embeddings: tourist.interest_vector (64-dim) and guide.expertise_embedding (64-dim) concatenated as 128-dim vector; dimensionality reduced via PCA to 32 components for clustering (retains >95% variance)
- Final feature matrix: 65 features → scaled + encoded + PCA-reduced

---

## Sweep Protocol

### Model Families (3 genuinely different)

| #   | Family         | Algorithm                         | Justification                                                                                   |
| --- | -------------- | --------------------------------- | ----------------------------------------------------------------------------------------------- |
| 1   | Centroid-based | `sklearn.cluster.KMeans`          | Fixed K=3 per spec constraint; Lloyd's algorithm; assumes spherical clusters                    |
| 2   | Density-based  | `sklearn.cluster.DBSCAN`          | No K required; identifies outliers (singleton clusters); different assumption set from centroid |
| 3   | Probabilistic  | `sklearn.mixture.GaussianMixture` | Soft assignments; estimates cluster covariance; assumes Gaussian distributions                  |

### Baseline

| #   | Family | Algorithm                 | Justification                                                    |
| --- | ------ | ------------------------- | ---------------------------------------------------------------- |
| 4   | Naive  | Random uniform assignment | Uniform random over K=3; no structure learned; establishes floor |

### Algorithm Sources

| Algorithm       | Source                            | Function/Class                                                                      |
| --------------- | --------------------------------- | ----------------------------------------------------------------------------------- |
| KMeans          | `sklearn.cluster.KMeans`          | `KMeans.fit(X, k=3, n_init=10, max_iter=300, random_state=seed)`                    |
| DBSCAN          | `sklearn.cluster.DBSCAN`          | `DBSCAN.fit(X, eps=eps_opt, min_samples=5)` — eps to be tuned                       |
| GaussianMixture | `sklearn.mixture.GaussianMixture` | `GaussianMixture.fit(X, n_components=3, covariance_type='full', random_state=seed)` |
| Random Uniform  | `numpy.random.default_rng`        | `rng.integers(0, 3, size=n_samples)`                                                |

### Identical Stability Protocol

| Parameter        | Value                                                                                   |
| ---------------- | --------------------------------------------------------------------------------------- |
| Random seed(s)   | `seed=42` (primary); `seed=range(5)` for stability resamples                            |
| Resample count   | 10 bootstrap resamples of full dataset (n_samples with replacement)                     |
| Train/test split | None — unsupervised on full feature matrix                                              |
| Resample method  | Bootstrap with replacement; stability = average Adjusted Rand Index across 10 resamples |

### Metrics (applied identically to all applicable candidates)

| Metric                       | Implementation                                | Applies To                            |
| ---------------------------- | --------------------------------------------- | ------------------------------------- |
| Inertia (within-cluster SSE) | `KMeans.inertia_`                             | KMeans only                           |
| Silhouette score             | `sklearn.metrics.silhouette_score(X, labels)` | All except random                     |
| Adjusted Rand Index (ARI)    | `sklearn.metrics.adjusted_rand_score`         | Stability (pairwise across resamples) |
| Cluster size distribution    | `numpy.bincount(labels)`                      | All                                   |
| Entropy of cluster sizes     | `scipy.stats.entropy(cluster_proportions)`    | All                                   |

---

## Leaderboard (Template — Awaiting Data)

| Model Family   | Algorithm       | Source (file + function)          | Key Assumptions                                          | Preprocessing            | Seed(s) | Resamples    | Inertia / SSE     | Silhouette Score  | Stability (avg ARI)   | Cluster Size Distribution (min/med/max) | Notes                                          |
| -------------- | --------------- | --------------------------------- | -------------------------------------------------------- | ------------------------ | ------- | ------------ | ----------------- | ----------------- | --------------------- | --------------------------------------- | ---------------------------------------------- |
| Centroid-based | KMeans (K=3)    | `sklearn.cluster.KMeans`          | Spherical clusters, equal variance, K fixed=3            | StandardScaler + PCA(32) | 42      | 10 bootstrap | **REQUIRES DATA** | **REQUIRES DATA** | **REQUIRES DATA**     | **REQUIRES DATA**                       | Lloyd's algorithm, 10 inits                    |
| Density-based  | DBSCAN          | `sklearn.cluster.DBSCAN`          | Density connectivity, no K required, identifies outliers | StandardScaler + PCA(32) | 42      | 10 bootstrap | N/A               | **REQUIRES DATA** | **REQUIRES DATA**     | **REQUIRES DATA**                       | eps sensitivity; singleton clusters = outliers |
| Probabilistic  | GaussianMixture | `sklearn.mixture.GaussianMixture` | Gaussian distributions per cluster, soft assignments     | StandardScaler + PCA(32) | 42      | 10 bootstrap | N/A               | **REQUIRES DATA** | **REQUIRES DATA**     | **REQUIRES DATA**                       | Full covariance; EM estimation                 |
| Naive Baseline | Random Uniform  | `numpy.random.default_rng`        | No structure; uniform prior over K=3                     | None (no fit)            | 42      | N/A          | N/A               | **REQUIRES DATA** | N/A (random baseline) | **REQUIRES DATA**                       | Floor for silhouette; no learning              |

---

## Missing Inputs Blocking Execution

| Input                     | Purpose                                                           | Status                  |
| ------------------------- | ----------------------------------------------------------------- | ----------------------- |
| Tourist profile dataset   | Instantiate tourist features (65-dim vector per tourist)          | MISSING                 |
| Guide profile dataset     | Used for guide-side segmentation if combined traveler-guide model | MISSING                 |
| Booking history           | For temporal stability analysis                                   | MISSING                 |
| Phase 3 approved features | Feature matrix construction                                       | APPROVED — pending data |

---

## Execution Plan (Upon Data Availability)

```
Step 1: Load pilot dataset (~500+ traveler profiles)
Step 2: Apply consistent preprocessing pipeline
Step 3: Run 4 candidates (KMeans, DBSCAN, GMM, Random)
Step 4: Compute metrics for each candidate
Step 5: Tabulate leaderboard
Step 6: Flag stability concerns
Step 7: Identify outlier/inconclusive clusters
```

---

## DBSCAN Epsilon Justification (Pending Data)

DBSCAN requires eps estimation. Upon data availability, use:

- **K-distance graph**: Plot sorted k-nearest-neighbor distances; elbow detection
- **Starting point**: eps = 0.5 (StandardScaler-scaled space)
- **Validation**: Silhouette at each eps; select eps maximizing silhouette within reasonable range [0.3, 1.5]

---

**Status**: BLOCKED — Awaiting pilot data generation or synthetic data from Phase 3 specs
