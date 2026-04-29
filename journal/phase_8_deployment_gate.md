# Phase 8 — Deployment Gate: WanderLess Matching Risk Model

**Timestamp**: 2026-04-26 20:28
**Phase**: Deployment Gate
**Status**: NO-GO — Cannot assess; Phase 4 produced no data

---

## Section 1: Phase 6 Floors (Verbatim)

### USML Floors

#### (a) Separation Floor (Definition)

**Metric**: Silhouette score (mean across all samples)

**Measurement protocol**:

- Apply the fitted model to the full feature matrix (no held-out set for unsupervised)
- Compute silhouette score per sample: `s_i = (b_i - a_i) / max(a_i, b_i)` where a_i = mean intra-cluster distance, b_i = mean nearest-cluster distance
- Aggregate: mean of per-sample silhouette scores across all samples

**Numeric value**: **NOT SET — user to supply numeric floor; Phase 6 did not assign a value**

---

#### (b) Stability Floor (Definition)

**Protocol**:

- **Re-seeding approach**: Re-run the clustering algorithm with N different random seeds, holding all other parameters fixed
- **Number of re-runs**: N = 10 (placeholder — confirm with data scale)
- **Comparison metric**: Adjusted Rand Index (ARI) computed pairwise across the N runs, then averaged

**Stability computation**:

```
stability_score = mean([ARI(run_i, run_j) for all pairs i < j])
```

**Numeric value**: **NOT SET — Phase 5 decision rule stated "stability (avg ARI) ≥ 0.70" as the recommended threshold for production, but this was a decision framework, not a pre-registered floor**

---

#### (c) Actionability Floor (DBAT — Definition)

**Test name**: Distinct-Business-Action Test (DBAT)

**Definition**: Each cluster must be demonstrably associated with at least one distinct, non-overlapping business action that differs from every other cluster's action set.

**Evaluation checklist**:

| #   | Check                                                     | Pass Condition                                                                    |
| --- | --------------------------------------------------------- | --------------------------------------------------------------------------------- |
| 1   | Cluster has a unique matching strategy                    | Guide-filter weighting differs from ≥1 other cluster by >20% on a named dimension |
| 2   | Cluster has a distinct marketing treatment                | Segment label used in a distinct campaign or targeting rule                       |
| 3   | Cluster does not share all actions with any other cluster | Action set is not a strict subset of another cluster's                            |

**Result**: If any cluster fails any check → Actionability Floor = FAIL

**Numeric value**: Binary (PASS/FAIL) — no numeric threshold

---

### SML Floors (Threshold Rule)

#### (a) Curve Selection

**Selected**: PR curve (Precision-Recall) — not ROC

**Reason**: Poor experience events are rare (~8% of bookings); ROC would appear high even at chance performance on minority class.

---

#### (b) Cost Asymmetry (Verbatim)

> "wrong-segment campaign cost ($45 per customer)"
> "per-customer touch cost ($3)"

---

#### (c) Calibration Floor

**Metric**: Brier score

**Definition**: `Brier = (1/N) * Σ (predicted_prob_i - actual_label_i)²`

**Floor rule**: If Brier score indicates poor calibration quality, the model must be calibrated (Platt scaling or isotonic regression) before threshold selection proceeds.

**Numeric value**: **NOT SET — no Brier score produced by any model**

---

## Section 2: Red-Team Blocking Findings

### From Phase 7 Findings Table

**No MITIGATE findings were produced.** All MITIGATE/RE-DO recommendations in Phase 7 are marked "Cannot assess" because no Phase 4 data was available to execute sweeps.

**Reason**: Phase 4 leaderboard contains only "REQUIRES DATA" — all seven sweeps in Phase 7 were blocked.

### Finding Summary from Phase 7

| Finding                | Sweep   | Recommendation | Blocking?                 |
| ---------------------- | ------- | -------------- | ------------------------- |
| Separation below floor | Sweep 1 | Cannot assess  | NO-GO requires assessment |
| Stability below floor  | Sweep 2 | Cannot assess  | NO-GO requires assessment |
| DBAT failure           | Sweep 3 | Cannot assess  | NO-GO requires assessment |
| Leakage present        | Sweep 4 | ACCEPT         | No — PASS                 |
| Proxy bias detected    | Sweep 5 | Cannot assess  | NO-GO requires assessment |
| Cold start failure     | Sweep 6 | Cannot assess  | NO-GO requires assessment |
| Operational overload   | Sweep 7 | Cannot assess  | NO-GO requires assessment |

**Blocking findings requiring assessment before deployment**: Sweeps 1, 2, 3, 5, 6, 7 — all cannot be assessed without Phase 4 data.

---

## Section 3: PASS / FAIL Table Against Floors

| Floor                        | Observed Value           | Status            | Evidence Source                                         |
| ---------------------------- | ------------------------ | ----------------- | ------------------------------------------------------- |
| Silhouette separation floor  | **REQUIRES DATA**        | **CANNOT ASSESS** | `phase_4_candidates.md` — no silhouette values produced |
| Stability floor (ARI ≥ 0.70) | **REQUIRES DATA**        | **CANNOT ASSESS** | `phase_4_candidates.md` — no ARI values produced        |
| Actionability (DBAT)         | **REQUIRES DATA**        | **CANNOT ASSESS** | No cluster assignments produced                         |
| Brier calibration floor      | **REQUIRES DATA**        | **CANNOT ASSESS** | No model run; no Brier score produced                   |
| Leakage (Sweep 4)            | No leakage detected      | **PASS**          | `phase_3_features.md` — 6 features confirmed OUT        |
| Proxy bias                   | **REQUIRES DATA**        | **CANNOT ASSESS** | Proxy-drop not executed                                 |
| Cold start behavior          | Framework defined        | **CANNOT ASSESS** | No production simulation                                |
| Operational ceiling          | Ceiling = 15 reviews/day | **CANNOT ASSESS** | No flagged volume data                                  |

**Gate result**: **NO-GO — Insufficient data to assess floors**

---

## Section 4: Day-One Monitoring Plan

> **Note**: All thresholds below are variance-grounded framework definitions. Actual threshold values require pilot data to compute historical variance. Thresholds are marked [REQUIRES DATA] until Phase 4 executes.

### Signal 1: Cluster Separation Drift

**(a) Signal**: Mean silhouette score across all samples, computed monthly on the full feature matrix

**(b) Cadence**: Monthly

**(c) Alert Threshold** (variance-grounded):

- Threshold: [REQUIRES DATA] — to be set at 2 standard deviations below the pilot-data baseline silhouette score
- Rationale: If separation degrades by more than 2σ from the pilot-data mean, clusters are becoming less distinct than at deployment time
- Source: `phase_6_metric_threshold.md` §1(a)

**(d) Owner**: ML Ops Engineer

---

### Signal 2: Cluster Stability Degradation

**(a) Signal**: Stability score (mean ARI across 10 re-seeded runs), computed weekly

**(b) Cadence**: Weekly

**(c) Alert Threshold** (variance-grounded):

- Threshold: [REQUIRES DATA] — to be set at the pre-registered floor value (Phase 6 did not assign numeric value; user must supply)
- Alert trigger: If stability score falls below floor for 2 consecutive weekly measurements
- Source: `phase_6_metric_threshold.md` §1(b)

**(d) Owner**: ML Ops Engineer

---

### Signal 3: Segment Size Distribution Shift

**(a) Signal**: Entropy of cluster size proportions; measured weekly

**(b) Cadence**: Weekly

**(c) Alert Threshold** (variance-grounded):

- Threshold: [REQUIRES DATA] — to be set at 2σ above the pilot-data entropy baseline
- If a cluster drops below 10% of population or exceeds 80%, trigger review regardless of entropy
- Source: `phase_5_implications.md` §Interpretive Guidance Checklist, Check #4

**(d) Owner**: Trust & Safety Manager

---

### Signal 4: Calibration Quality (Brier Score)

**(a) Signal**: Brier score on rolling 30-day prediction window

**(b) Cadence**: Weekly

**(c) Alert Threshold** (variance-grounded):

- Threshold: [REQUIRES DATA] — to be set at Brier score at pilot deployment time plus 2σ
- If Brier exceeds threshold: model must be recalibrated before threshold selection is rerun
- Source: `phase_6_metric_threshold.md` §2(c)

**(d) Owner**: ML Ops Engineer

---

### Signal 5: Operational Load — Flagged Booking Volume

**(a) Signal**: Daily count of bookings flagged as high-risk by the model

**(b) Cadence**: Daily

**(c) Alert Threshold** (variance-grounded):

- Threshold: 15 flagged bookings/day (per Phase 1 operational ceiling: T&S Manager capacity)
- Alert if: Flagged volume exceeds 15 for 3 consecutive days
- Source: `01-analysis/00-executive-summary.md` — "15 flagged bookings can be manually reviewed per T&S Manager per day"

**(d) Owner**: Trust & Safety Manager

---

### Signal 6: Cold Start Fraction

**(a) Signal**: Proportion of active bookings involving a guide with <3 completed tours (cold_start_flag = True)

**(b) Cadence**: Monthly

**(c) Alert Threshold** (variance-grounded):

- Threshold: [REQUIRES DATA] — to be set at pilot-data baseline fraction + 2σ
- Alert if: Cold start fraction increases by >20% above baseline (signals guide recruitment pipeline is slowing)
- Source: `phase_7_red_team.md` Sweep 6; `phase_3_features.md` Feature #39

**(d) Owner**: Trust & Safety Manager

---

## Section 5: Rollback Trigger

**Cannot be defined without model output.** The rollback trigger requires a specific stability metric and threshold, which cannot be set without Phase 4 data.

**Framework for rollback trigger** (once data exists):

```
IF cluster_stability_score < [PRE-REGISTERED FLOOR] FOR 3 consecutive weekly measurements:
    AND cluster_stability_degradation is attributable to model retrain (not data distribution shift):
        TRIGGER ROLLBACK

Rollback scope: Revert matching engine to [fallback system]
Rollback window: Immediate — matching must not degrade further during investigation
```

**Source**: `phase_6_metric_threshold.md` §1(b) stability floor definition; `phase_7_red_team.md` Sweep 2 business impact (segment reshuffling)

---

## Section 6: Rollback Target

**Fallback system for matching**: Rule-based deterministic matching (current production system prior to ML upgrade)

**Fallback behavior**:

- Tourists matched to guides by highest content-based compatibility score (cosine similarity of interest vectors) only
- No collaborative filtering, no contextual scoring
- No group formation
- No satisfaction prediction
- Matching coverage remains >95% (all eligible tourists receive a match)

**Why this is the rollback target**:

- It is the currently deployed system (matching existed before the ML model)
- It is rule-based and deterministic (no stability issues)
- It does not require retraining
- It can be activated immediately

**Source**: `04-specs/matching-engine.md` — content-based matching is the foundational layer; collaborative and contextual scores are additive improvements

---

## Section 7: Governance Rule

**This document does not declare GO or NO-GO.**

The deployment gate cannot be passed because:

1. Phase 4 produced no data — all metric floors are unassessed
2. Six of seven Phase 7 red-team sweeps are blocked
3. The only assessed finding (leakage, Sweep 4) is PASS but insufficient alone to clear deployment

**Decision authority rests with the user.**

**The following must occur before a deployment gate decision is valid**:

| #   | Prerequisite                                        | Blocks                                  |
| --- | --------------------------------------------------- | --------------------------------------- |
| 1   | Phase 4 executes with pilot dataset                 | All metric floors                       |
| 2   | User supplies numeric separation floor              | Separation PASS/FAIL                    |
| 3   | User supplies numeric stability floor               | Stability PASS/FAIL                     |
| 4   | Phase 7 sweeps re-executed against Phase 4 output   | All blocking findings                   |
| 5   | MITIGATE findings receive explicit user disposition | Cannot ship through unresolved MITIGATE |

---

**Status**: NO-GO — Deployment gate is blocked pending Phase 4 data execution and user-supplied floor values
