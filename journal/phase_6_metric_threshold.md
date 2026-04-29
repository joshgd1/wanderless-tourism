# Phase 6 — Metric + Threshold Pre-Registration: WanderLess Matching Risk Model

**Timestamp**: 2026-04-26 18:42
**Phase**: Metric + Threshold Pre-Registration (Floors)
**Order-of-information statement**: **"Floors are being set prior to re-opening the leaderboard."**

---

## Section 0: Order-of-Information Check

**Statement**: Floors are being set prior to re-opening the leaderboard.

**Reasoning**: The Phase 4 leaderboard contains no numeric results — all metric cells are marked "REQUIRES DATA." No candidate comparisons, rankings, or metric values have been observed. This Phase 6 document defines the floor frameworks and threshold-selection rules before any leaderboard values are available, preventing post-hoc rationalization of thresholds.

---

## Section 1: Unsupervised Floors — Definitions Only

### (a) Separation Floor

**Metric**: Silhouette score (mean across all samples)

**Measurement protocol**:

- Apply the fitted model to the full feature matrix (no held-out set for unsupervised)
- Compute silhouette score per sample: `s_i = (b_i - a_i) / max(a_i, b_i)` where a_i = mean intra-cluster distance, b_i = mean nearest-cluster distance
- Aggregate: mean of per-sample silhouette scores across all samples
- This produces a single scalar in range [-1, 1]

**What the floor prevents**: Silhouette < floor indicates clusters are not meaningfully separated — assignment to any cluster is nearly arbitrary. Floor must exceed what random partition achieves on the same data.

---

### (b) Stability Floor

**Protocol**:

- **Re-seeding approach**: Re-run the clustering algorithm with N different random seeds, holding all other parameters fixed
- **Number of re-runs**: N = 10 (placeholder — confirm with data scale)
- **Comparison metric**: Adjusted Rand Index (ARI) computed pairwise across all N runs, then averaged
  - ARI = 1.0: identical cluster assignments
  - ARI = 0.0: random agreement
  - ARI < 0: worse than random

**How stability is computed**:

```
stability_score = mean([ARI(run_i, run_j) for all pairs i < j])
```

**What the floor prevents**: Stability < floor indicates that the clustering is not reproducible — a tourist's segment label would change depending on which seed the model happened to use. A stable model produces the same segments across seeds. Unstable segments cannot be used in product or marketing decisions.

---

### (c) Actionability Floor (Named Test)

**Test name**: Distinct-Business-Action Test (DBAT)

**Definition**: Each cluster must be demonstrably associated with at least one distinct, non-overlapping business action that differs from every other cluster's action set.

**Evaluation method** (checklist — pass/fail per cluster):

| #   | Check                                                     | Pass Condition                                                                                                |
| --- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| 1   | Cluster has a unique matching strategy                    | Guide-filter weighting for this cluster differs from at least one other cluster by > 20% on a named dimension |
| 2   | Cluster has a distinct marketing treatment                | Segment label is used in a distinct campaign or targeting rule not shared with other clusters                 |
| 3   | Cluster does not share all actions with any other cluster | The cluster's action set is not a strict subset of another cluster's action set                               |

**Result**: If any cluster fails any check → Actionability Floor = FAIL
**Result**: If all clusters pass all checks → Actionability Floor = PASS

---

## Section 2: Supervised Threshold Rule — Frame Only

### (a) Curve Selection

**Selected**: **PR curve (Precision-Recall)** — not ROC

**Reason (tied to class imbalance)**: Poor experience events are expected to be rare (~8% of bookings based on Phase 1 Frame assumptions). In imbalanced settings, ROC AUC can appear high even when the model performs at chance level on the minority class. PR curve reflects actual detection capability for the rare positive class.

---

### (b) Cost Asymmetry (Verbatim from Project Brief)

Quote exactly:

> "wrong-segment campaign cost ($45 per customer)"

> "per-customer touch cost ($3)"

These two costs are asymmetric in direction and magnitude. The wrong-segment cost ($45) is a loss incurred when a tourist is matched to a poor-experience guide. The per-customer touch cost ($3) is a marginal cost incurred for each tourist touched by the intervention.

---

### (c) Calibration Floor

**Metric**: Brier score

**Definition**: Mean squared error between predicted probabilities and binary labels, averaged across all samples:

```
Brier = (1/N) * Σ (predicted_prob_i - actual_label_i)²
```

**Floor rule**: If Brier score indicates poor calibration quality, the model **must be calibrated before threshold selection proceeds**.

**Calibration requirement**: Any model producing probability outputs must pass a calibration quality check (e.g., reliability diagram bins, Expected Calibration Error) before the threshold is selected. If calibration is insufficient, apply Platt scaling or isotonic regression as a post-processing step before threshold selection.

---

## Section 3: Dollar-Lift Framework — Formula Skeleton Only

### Definitions

| Symbol              | Definition                                                       |
| ------------------- | ---------------------------------------------------------------- |
| TP (True Positive)  | Predicted high-risk AND actual poor experience occurred          |
| FP (False Positive) | Predicted high-risk AND actual poor experience did NOT occur     |
| FN (False Negative) | Predicted NOT high-risk BUT actual poor experience occurred      |
| TN (True Negative)  | Predicted NOT high-risk AND actual poor experience did NOT occur |

### Cost Terms (from project brief)

| Term                            | Verbatim Label                                   | Direction                                                                                                        |
| ------------------------------- | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| Cost per wrong-segment campaign | "wrong-segment campaign cost ($45 per customer)" | FP cost — incurred each time a tourist is incorrectly flagged and subjected to an intervention they did not need |
| Cost per customer touch         | "per-customer touch cost ($3)"                   | Marginal cost — incurred each time the system touches a tourist, regardless of outcome                           |

### Dollar-Lift Formula

```
Expected Value (EV) per period =
    (TP × [value per correct action — TBD])
  − (FP × $45.00)
  − ([total tourists touched] × $3.00)
```

**Placeholder definitions**:

- `[value per correct action — TBD]`: The economic value of correctly identifying and preventing a poor-experience booking; must be defined by business stakeholders before EV is computed
- `[total tourists touched]`: Sum of all tourists flagged for intervention in the period; derived from threshold × population size

**Break-even condition** (for reference, not a floor):

```
TP × [value per correct action] = FP × $45.00 + [total touched] × $3.00
```

---

## Section 4: Threshold-Selection Rule (Pre-Registered)

**Rule**: The operating threshold on the PR curve is selected by solving for the point where:

```
Marginal EV of detecting one additional true positive
  =
Marginal cost of the intervention touch required to detect it
```

**At this point**: The cost of touching one more tourist ($3.00) equals the expected value recovered from correctly preventing one more poor experience.

**Note**: This threshold is selected on the PR curve, not ROC, because PR reflects performance on the rare positive class (poor experiences) which is the actual detection target.

---

**Status**: COMPLETE — Floor definitions and threshold rule pre-registered; awaiting user to write numeric floor values
