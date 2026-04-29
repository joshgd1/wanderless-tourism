# Phase 7 — Red-Team: WanderLess Matching Risk Model

**Timestamp**: 2026-04-26 20:21
**Phase**: Red-Team
**Status**: CANNOT EXECUTE — No Phase 4 leaderboard data

---

## Order-of-Information Check

**Statement**: Phase 7 is executing before Phase 4 has produced any numeric results. The Phase 4 leaderboard contains only "REQUIRES DATA" placeholders. No model output, no candidate metrics, no leaderboard rankings have been generated.

**Implication**: All seven sweeps below are documented as frameworks only. No findings can be produced until Phase 4 executes with pilot data.

---

## Inputs Referenced

| Input                             | File                                  | Status                                  |
| --------------------------------- | ------------------------------------- | --------------------------------------- |
| Phase 6 floors and threshold rule | `journal/phase_6_metric_threshold.md` | Framework only — numeric floors not set |
| Phase 4 leaderboard               | `journal/phase_4_candidates.md`       | All cells = "REQUIRES DATA"             |
| Phase 3 approved features         | `journal/phase_3_features.md`         | 65 features approved                    |
| Phase 1 Frame                     | `01-analysis/00-executive-summary.md` | Target and cost terms defined           |

---

## Cost Terms (Verbatim from Brief)

> "wrong-segment campaign cost ($45 per customer)"
> "per-customer touch cost ($3)"

---

## Sweep 1: Separation Check

### Framework (Cannot Execute)

**Metric**: Silhouette score (mean across all samples)
**Protocol**: Apply fitted model to full feature matrix; compute mean silhouette per Phase 6 §1(a)

**Phase 6 floor**: Silhouette score must exceed a pre-registered numeric floor (not yet set; user to fill)

**Evidence source**: `journal/phase_4_candidates.md` — "Silhouette Score" column

**Execution result**: **CANNOT EXECUTE — Phase 4 leaderboard has no silhouette values**

**Dollar severity if below floor**: Not computable without data

---

## Sweep 2: Stability Check

### Framework (Cannot Execute)

**Metric**: Stability score (mean ARI across 10 re-seeded runs)
**Protocol**: Re-run candidate clustering with 10 different random seeds; compute pairwise ARI; average

**Phase 6 floor**: Stability score (avg ARI) must exceed a pre-registered numeric floor (not yet set)

**Evidence source**: `journal/phase_4_candidates.md` — "Stability Score" column

**Business impact if unstable**: Segment labels would reshuffle on every retrain, making marketing campaigns and matching strategies unreliable — different tourists receive different segment labels on different days with no actual change in their behavior.

**Execution result**: **CANNOT EXECUTE — Phase 4 leaderboard has no ARI values**

---

## Sweep 3: Actionability Test (DBAT)

### Framework (Cannot Execute)

**Test**: Distinct-Business-Action Test (DBAT) per Phase 6 §1(c)
**Checklist**:

| #   | Check                                                     | Pass Condition                                                                    |
| --- | --------------------------------------------------------- | --------------------------------------------------------------------------------- |
| 1   | Cluster has unique matching strategy                      | Guide-filter weighting differs from ≥1 other cluster by >20% on a named dimension |
| 2   | Cluster has distinct marketing treatment                  | Segment label used in distinct campaign or targeting rule                         |
| 3   | Cluster does not share all actions with any other cluster | Action set is not a strict subset of another cluster's                            |

**Evidence source**: Would require model output (cluster assignments) to evaluate checklist

**Business impact if FAIL**: If any cluster fails DBAT, that cluster cannot be given a distinct product or marketing treatment — it is operationally identical to another segment and must be merged or discarded.

**Execution result**: **CANNOT EXECUTE — No cluster assignments produced**

---

## Sweep 4: Leakage Re-check

### Based on Phase 3 Review

**Status**: Pre-existing leakage audit already completed in Phase 3

**Finding from Phase 3** (`journal/phase_3_features.md`):

| Feature                     | Type                | Status |
| --------------------------- | ------------------- | ------ |
| `tourist.guide_ratings`     | LABEL LEAKAGE       | OUT    |
| `guide.average_rating`      | LABEL LEAKAGE       | OUT    |
| `guide.repeat_tourist_rate` | FUTURE-DATA LEAKAGE | OUT    |
| `repeat_guide_bonus`        | LABEL LEAKAGE       | OUT    |
| `repeat_guide_rating`       | LABEL LEAKAGE       | OUT    |
| `collaborative_score`       | LABEL LEAKAGE       | OUT    |

**Verification**: All OUT features were excluded from the approved IN feature set. Evidence: `journal/phase_3_features.md` — "Recommendation" column for each excluded feature.

**Conclusion**: No label or future-data leakage found in approved feature set. No new leakage findings from Phase 3.

**Execution result**: **COMPLETE — leakage re-check already performed in Phase 3**

---

## Sweep 5: Proxy / Bias Check

### Framework (Cannot Execute)

**Source**: Phase 3 proxy-drop findings (`journal/phase_3_features.md`)

**Known proxy concerns from Phase 3**:

| Feature                        | Regulatory Flag                                            | Phase 3 Recommendation      |
| ------------------------------ | ---------------------------------------------------------- | --------------------------- |
| `tourist.age_group`            | PDPA §13 (Singapore) / GDPR Art. 9 (EU)                    | OUT                         |
| `tourist.mobility`             | GDPR Art. 9 / PDPA §13 — disability indicator              | FLAG (hard constraint only) |
| `tourist.dietary_restrictions` | GDPR Art. 9 — may imply religion (halal, kosher) or health | FLAG (hard constraint only) |
| `tourist.accessibility_needs`  | GDPR Art. 9 / PDPA §13 — disability                        | FLAG (hard constraint only) |

**Phase 3 decision**: age_group excluded entirely; dietary/mobility/accessibility flagged as hard-constraint only (not predictive inputs)

**Proxy-drop test**: **CANNOT EXECUTE** — requires pilot data to fit models with/without demographic features and measure reassignment rate. From `journal/phase_3_features.md`: "REQUIRES DATA"

**If proxy drift detected at execution**:

- Dollar impact: If demographic groups receive systematically different segment assignments, and wrong-segment intervention is applied, affected groups bear disproportionate campaign cost burden
- Severity formula: `affected_customers × $45.00` (wrong-segment campaign cost)
- Regulatory exposure: Potential PDPA §13 / GDPR Art. 9 violation if age-derived segments used for targeting

**Execution result**: **PENDING DATA — proxy-drop test framework ready, execution blocked**

---

## Sweep 6: Cold Start Stress

### Framework (Cannot Execute)

**Test scenario**: New traveler (0 completed tours) matched with new guide (< 3 tours completed)

**Cold start behavior** (from Phase 3):

- New tourist: `completeness_score < 0.5`; matching eligibility gated
- New guide: `total_tours_completed < 3`; cold_start_flag = True; assigned to lowest weight in collaborative filtering

**Evidence source**: `journal/phase_3_features.md` — Feature #39 `guide.total_tours_completed` and Feature #75 `cold_start_flag`

**Business implications of cold start**:

- New tourists receive less accurate matching → higher risk of poor experience
- New guides receive fewer bookings → slower data accumulation → extended cold start period
- Risk: Compound death spiral (per Phase 2 discovery: `journal/0002-DISCOVERY-compound-death-spiral.md`)

**Execution result**: **CANNOT EXECUTE — requires production data simulation**

---

## Sweep 7: Operational Load Check

### Framework (Cannot Execute)

**Reference ceiling**: Phase 1 Frame — Trust & Safety Manager can manually review 15 flagged bookings per day

**Evidence source**: `01-analysis/00-executive-summary.md` — "Operational Ceiling" section

**Computation if Phase 4 data existed**:

```
Daily flagged volume = bookings_per_month × flagging_rate / 30
Flagging_rate assumption: 10% (Phase 1 Frame)
```

**Overload condition**: If daily flagged volume > 15 → Trust & Safety Manager is overloaded → unaddressed alerts accumulate → liability exposure

**If exceeded**:

- Dollar severity: `unreviewed_alerts × $45.00` (wrong-segment cost per alert that should have been reviewed)
- At 20 un-reviewed alerts per day: `20 × $45.00 = $900/day = $27,000/month`
- Business impact: Unreviewed alerts create platform liability for any incident that occurs with an un-reviewed tourist

**Execution result**: **CANNOT EXECUTE — Phase 4 produces no booking volume data**

---

## Findings Table (No Data — Placeholder)

| #   | Finding                | Sweep   | Metric / Observation            | Evidence                 | Dollar Severity   | Status vs Floor | Recommendation |
| --- | ---------------------- | ------- | ------------------------------- | ------------------------ | ----------------- | --------------- | -------------- |
| 1   | Separation below floor | Sweep 1 | **REQUIRES DATA**               | `phase_4_candidates.md`  | **REQUIRES DATA** | Cannot assess   | Cannot assess  |
| 2   | Stability below floor  | Sweep 2 | **REQUIRES DATA**               | `phase_4_candidates.md`  | **REQUIRES DATA** | Cannot assess   | Cannot assess  |
| 3   | DBAT failure           | Sweep 3 | **REQUIRES DATA**               | Cluster assignments      | **REQUIRES DATA** | Cannot assess   | Cannot assess  |
| 4   | Leakage present        | Sweep 4 | No leakage in approved features | `phase_3_features.md`    | $0 — no finding   | PASS            | ACCEPT         |
| 5   | Proxy bias detected    | Sweep 5 | **REQUIRES DATA**               | Proxy-drop not run       | **REQUIRES DATA** | Cannot assess   | Cannot assess  |
| 6   | Cold start failure     | Sweep 6 | **REQUIRES DATA**               | No production simulation | **REQUIRES DATA** | Cannot assess   | Cannot assess  |
| 7   | Operational overload   | Sweep 7 | **REQUIRES DATA**               | No volume data           | **REQUIRES DATA** | Cannot assess   | Cannot assess  |

---

## Severity Ranking

**Ranking cannot be established without data.** Dollar severities are undefined for Sweeps 1, 2, 3, 5, 6, 7.

**Known finding (non-dollar)**: Sweep 4 confirms no label or future-data leakage in approved feature set.

---

## Phase Dependency Chain

```
Phase 4 (leaderboard data)
    ↓
Phase 7 (red-team sweeps) ← CURRENTLY BLOCKED HERE
    ↓
Phase 8 (if needed — remediation)
```

---

## Missing Inputs Required to Execute Phase 7

| Input                                  | Blocks                  |
| -------------------------------------- | ----------------------- |
| Pilot dataset (~500+ bookings)         | Sweeps 1, 2, 3, 5, 6, 7 |
| Phase 4 leaderboard output             | All sweeps              |
| Numeric floor values (from user)       | Floor comparisons       |
| Phase 1 operational ceiling validation | Sweep 7                 |

---

**Status**: CANNOT EXECUTE — Awaiting pilot data and Phase 4 execution
