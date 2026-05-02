# WanderLess Synthetic Pilot Data

Generated: generate_synthetic.py — seed=42

## Destinations

- **TH (Thailand (Chiang Mai)), SG (Singapore)**

## Files

| File | Rows | Description |
|------|------|-------------|
| `tourist_profiles.csv` | 400 | Tourist feature vectors |
| `guide_profiles.csv` | 60 | Guide feature vectors (includes STB license fields for SG) |
| `synthetic_ratings.csv` | 600 | Tourist-Guide-Rating tuples |

## Schema: guide_profiles.csv (new Singapore fields)

| Column | Type | Description |
|--------|------|-------------|
| `license_verified` | bool | Platform-verified credentials |
| `license_number` | string | STB license number (SG licensed guides) |
| `license_type` | string | "licensed" \| "verified_expert" \| "community_host" |
| `license_country` | string | "SG" \| "TH" |
| `license_expiry` | string | ISO date for STB licenses |

## Singapore License Tiers

| Tier | STB Verified | Description |
|------|-------------|-------------|
| `licensed` | Yes (STB-XXXXXX) | Official STB-licensed tour guide |
| `verified_expert` | Yes (VXP-XXXXX) | Background-checked local expert / experience host |
| `community_host` | No | Community host — experience-led activities |

## Rating Model (from Chiang Mai Playbook §Cold Start Data Strategy)

```
norm_dot = (raw_dot - dot_min) / (dot_max - dot_min)   # [0, 1]
true_rating = clamp(norm_dot × 6.5 + 1.2 + bonus, 1.0, 5.0)
bonus = lang_match × 0.30 + (compat − 0.8) × 0.15
rating = clamp(true_rating × 0.88 + gauss(0, 1.0) × 0.12, 1.0, 5.0)
```

88% genuine compatibility signal + 12% irreducible noise.

## Poor Experience Rate

Threshold: rating < 2.5
Observed poor rate in this sample: 28/600 (4.7%)

Expected poor rate: 8-15% (Phase 1 Frame target for cold-start pilot data).
Actual in this sample: 28/600 (4.7%)

## Usage

```python
import pandas as pd

ratings = pd.read_csv("data/synthetic_ratings.csv")
tourists = pd.read_csv("data/tourist_profiles.csv")
guides   = pd.read_csv("data/guide_profiles.csv")

# Baseline: mean rating
print(ratings["rating"].describe())

# Poor experience rate
print(ratings["is_poor_experience"].mean())

# PSI-ready: bin ratings by predicted vs actual
ratings["bin"] = pd.cut(ratings["predicted_rating"], bins=5)
print(ratings.groupby("bin")["rating"].mean())  # calibration check
```

## Limitations

- Rating noise is i.i.d. Gaussian — real ratings have temporal correlation,
  reviewer bias, and guide effort variation not captured here.
- Language match is binary — real multilingual guides have partial fluency.
- Guide expertise is mapped to a 3-D interest space — real expertise is higher-dimensional.
- `is_poor_experience` is rating-based only — Phase 1 Frame includes 48h cancellation
  as a poor signal, not present in this synthetic dataset.
- Dot product range is computed from the generated tourist/guide population —
  with different random seeds or larger populations, the range shifts slightly.
