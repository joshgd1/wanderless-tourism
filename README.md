# WanderLess

**ML-powered travel marketplace matching tourists with local guides through compatibility intelligence.**

Instead of browsing tours by destination, WanderLess matches you with guides based on who you are — your interests, travel style, pace, and personality. The platform then orchestrates the full experience: itinerary optimization, group formation, and satisfaction prediction.

![WanderLess — Where Compatibility Meets Travel](WanderLess%20Logo.png)

---

## Why WanderLess Exists

Current travel platforms (Klook, GetYourGuide, Viator, Airbnb Experiences) all use the same discovery model: browse by city, sort by popularity, pick from pre-packaged offerings. This has three fundamental failures:

1. **Time waste** — Travelers spend 3–5 hours researching and still end up disappointed
2. **Guide invisibility** — You book "an experience," not a person; personality and expertise stay hidden until the tour starts
3. **Compatibility gap** — Nobody matches by _who_ you are — only _where_ you're going. This is a solved ML problem in every other consumer domain (Netflix, Spotify, Amazon) but not in travel.

Travel is the last major consumer domain where ML-powered recommendation hasn't been applied.

---

## Four ML Capabilities

### 1. Interest-Compatibility Matching

Scores tourist-guide compatibility 0–100% using hybrid recommendation:

- **40%** content-based: interest vector cosine similarity
- **40%** collaborative: TruncatedSVD matrix factorization on tourist-guide-rating tuples
- **20%** contextual: destination affinity boost (time/weather signals described for future production upgrade)

### 2. Group Formation Engine

Clusters like-minded travelers for group tours using K-Means clustering + DBSCAN outlier detection. Groups of 3–8 travelers with measured coherence scores.

### 3. Itinerary Optimization

Sequences tour stops using greedy construction + 2-opt local search, respecting time windows, travel distance, budgets, and meal breaks. (CP-SAT constraint solver described in architecture for production upgrade.)

### 4. Satisfaction Prediction

XGBoost regression model (prototype) predicts expected tour rating before it happens. Model exists in `backend/ml/review_intelligence.py`; not yet wired to the recommendation API endpoint. Accuracy targets (85%+ directional accuracy) are architecture-stage estimates requiring real-data validation.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│   (tourist onboarding, guide discovery, booking, itinerary) │
└──────────────────────────┬──────────────────────────────────┘
                           │  REST API
┌──────────────────────────▼──────────────────────────────────┐
│                   Python Backend                            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ Kailash SDK │  │ DataFlow    │  │  ML Engine      │  │
│  │ Nexus API   │  │ SQLite      │  │  (cosine sim, │  │
│  │             │  │             │  │   TruncatedSVD,│  │
│  │             │  │             │  │   K-Means/DBSCAN)│  │
└─────────────────────────────────────────────────────────────┘
```

**Tech Stack**

| Layer     | Technology                                                                                                                                            |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mobile    | Flutter (Android/iOS)                                                                                                                                 |
| Backend   | Python 3.11+ with Kailash SDK                                                                                                                         |
| API       | Kailash Nexus (handler pattern, multi-channel deploy)                                                                                                 |
| Database  | SQLite (development), PostgreSQL (production) via Kailash DataFlow                                                                                    |
| ML        | Cosine similarity, TruncatedSVD (collaborative filtering), K-Means/DBSCAN (group formation); XGBoost satisfaction model (prototype, not wired to API) |
| Framework | Kailash Core SDK, Kaizen, DataFlow, Nexus                                                                                                             |

---

## Getting Started

### Prerequisites

- Python 3.11+
- Flutter SDK (for mobile app development)
- `uv` package manager

### Backend Setup

```bash
# Clone and enter the project
git clone https://github.com/joshgd1/wanderless-tourism.git
cd wanderless-tourism

# Install dependencies
uv venv
uv sync

# Configure environment
cp .env.example .env
# Edit .env with your API keys and configuration

# Run the backend server
cd backend
uv run python main.py
```

### Mobile App Setup

```bash
cd app
flutter pub get
flutter run
```

### Synthetic Pilot Data

The project ships with generated pilot data for cold-start ML validation:

| File                    | Rows | Description                                                 |
| ----------------------- | ---- | ----------------------------------------------------------- |
| `tourist_profiles.csv`  | 400  | Tourist feature vectors (interests, pace, budget, language) |
| `guide_profiles.csv`    | 60   | Guide profiles (expertise, personality, STB licensing)      |
| `synthetic_ratings.csv` | 600  | Tourist-guide-rating tuples                                 |

Rating model: `88%` genuine compatibility signal + `12%` irreducible noise, calibrated against a 1–5 scale.

---

## Project Structure

```
wanderless-tourism/
├── backend/               # Python API server
│   ├── main.py           # Nexus app entry point
│   ├── models.py         # SQLAlchemy models
│   ├── matching.py        # Compatibility scoring engine
│   ├── ml/               # ML components (cosine sim, TruncatedSVD, K-Means/DBSCAN; XGBoost prototype not wired to API)
│   └── database.py       # DataFlow database setup
├── app/                  # Flutter mobile application
│   ├── lib/
│   │   ├── features/     # Feature modules (auth, matching, booking)
│   │   ├── shared/       # Shared widgets, theme, utilities
│   │   └── main.dart
│   └── pubspec.yaml
├── specs/                # Detailed product specifications
│   ├── matching-engine.md
│   ├── itinerary-optimizer.md
│   ├── group-formation.md
│   ├── satisfaction-predictor.md
│   └── *_profile.md
├── data/                 # Synthetic pilot datasets
├── tests/                # Test suites
└── docs/                 # Decision records and guides
    ├── COC_DECISION_LOG_A_PLUS.md    # Team decision log with rubric mapping
    ├── ML_CLAIMS_IMPLEMENTATION_MATRIX.md  # ML claim verification matrix
    └── PRESENTATION_GUIDE.md          # Demo script and Q&A guide
```

---

## Singapore Licensing (STB)

WanderLess supports Singapore Tourism Board (STB) licensing tiers for guides operating in Singapore:

| Tier              | License    | Description                                       |
| ----------------- | ---------- | ------------------------------------------------- |
| `licensed`        | STB-XXXXXX | Official STB-licensed tour guide                  |
| `verified_expert` | VXP-XXXXX  | Background-checked local expert / experience host |
| `community_host`  | —          | Community host — experience-led activities        |

---

## Business Model

| Revenue Stream            | Rate      | Trigger           |
| ------------------------- | --------- | ----------------- |
| Booking commission        | 15–18%    | Tourist pays      |
| Guide premium tools       | $14.99/mo | After 20 bookings |
| Business partner referral | 5–10%     | Pay-per-visit     |

**Unit Economics**: Tourist LTV $45–90 / CAC $5–15 / payback in 1 trip. Guide LTV $600–1,200/year / CAC $0 / payback in 1–2 months.

---

## Contributing

Contributions are welcome. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

This project is licensed under **Apache 2.0** — see [LICENSE](LICENSE) for details.

---

## Security

For vulnerability disclosures, please contact [security@terrene.foundation](mailto:security@terrene.foundation). See [SECURITY.md](SECURITY.md) for our disclosure policy and scope.

---

_WanderLess is a research and development project exploring ML-powered travel matching. Built with the [Kailash SDK](https://github.com/terrene-foundation/kailash-py) by the Terrene Foundation._
