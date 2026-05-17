# WanderLess Validation Report

**Test Date**: 2026-05-14
**Environment**: macOS (Darwin 24.6.0)
**Python Version**: 3.11+
**Flutter Version**: Flutter 3.x
**Package Manager**: `uv` (Python), `flutter pub` (Dart)

---

## 1. Environment

| Component    | Version  | Notes                        |
| ------------ | -------- | ---------------------------- |
| Python       | 3.11+    | Via `uv` virtual environment |
| Flutter      | 3.x      | Via `flutter` CLI            |
| Node.js      | N/A      | Not required for core demo   |
| SQLite       | Built-in | Development database         |
| Backend Port | 8000     | `uvicorn main:app --reload`  |
| Frontend     | Flutter  | `flutter run`                |

---

## 2. Backend Validation

### Setup Commands

```bash
# Install dependencies
cd backend
uv sync

# Run test suite
uv run python -m pytest

# Start API server
uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Expected Results

| Check                 | Command                                 | Expected                  | Status   |
| --------------------- | --------------------------------------- | ------------------------- | -------- |
| Dependencies install  | `uv sync`                               | No errors                 | Required |
| API imports           | `python -c "import main"`               | Clean import              | Required |
| Health endpoint       | `curl http://localhost:8000/api/health` | `200 OK`                  | Required |
| Seed data             | DB populated                            | Tourists, guides, ratings | Required |
| Guide recommendations | `GET /api/recommendations/{id}/guides`  | Ranked guide list         | Required |
| Safety score          | `POST /api/safety/score`                | Score + flags             | Required |
| Group formation       | `POST /api/groups/form`                 | Cluster groups            | Required |
| Pricing               | `POST /api/pricing/quote`               | Price estimate            | Required |

### Seed Accounts

| Role     | Email                     | Password        |
| -------- | ------------------------- | --------------- |
| Tourist  | `tourist_test_1@test.com` | `test123`       |
| Guide    | `guide_test_1@test.com`   | `test123`       |
| Business | `business@wanderless.com` | `wanderless123` |

---

## 3. Frontend Validation

### Setup Commands

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

### Expected Results

| Check           | Command           | Expected                | Status   |
| --------------- | ----------------- | ----------------------- | -------- |
| Dependencies    | `flutter pub get` | No errors               | Required |
| Static analysis | `flutter analyze` | No errors               | Required |
| Unit tests      | `flutter test`    | All pass                | Optional |
| App launch      | `flutter run`     | App starts              | Required |
| Onboarding      | UI flow           | Interest sliders render | Required |
| Discover screen | UI flow           | Guide cards display     | Required |
| Itinerary       | UI flow           | Stop list renders       | Required |

---

## 4. Demo Test Cases

| Test Case            | Steps                                           | Expected Result                  | Status                  |
| -------------------- | ----------------------------------------------- | -------------------------------- | ----------------------- |
| Tourist login        | Register → Login with `tourist_test_1@test.com` | JWT returned, profile accessible | **Test before demo**    |
| Tourist onboarding   | Set 5 interest sliders                          | Preference vector stored         | **Test before demo**    |
| Guide recommendation | Call recommendations endpoint                   | Top 5 guides with scores         | **Primary demo screen** |
| Match explanation    | View guide detail card                          | Score breakdown displayed        | **Test before demo**    |
| Trip plan creation   | Select guide → Create plan                      | Plan created with status         | **Test before demo**    |
| Safety score         | Call `POST /api/safety/score`                   | Score + risk flags               | **Test before demo**    |
| Group formation      | POST to `/api/groups/form`                      | 3–8 person clusters              | **Test before demo**    |
| Pricing quote        | Call `POST /api/pricing/quote`                  | Price range returned             | **Test before demo**    |
| Guide accept request | Guide accepts via guide flow                    | Plan status → ACCEPTED           | **Secondary demo**      |

---

## 5. Known Limitations

### Explicitly Not Claimed as Production-Ready

| Limitation                                 | Details                                                                                                               |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| **Real production accuracy not validated** | All ML accuracy metrics are architecture-stage estimates. No real post-tour ratings exist.                            |
| **Synthetic data used**                    | Collaborative filtering trained on 600 synthetic ratings (88% genuine / 12% noise). Workflow validated, not accuracy. |
| **No real payment processing**             | Payment/escrow state machine is prototype. No Stripe, no actual fund movement.                                        |
| **No real licence verification**           | License tier is surfaced from guide profiles. No real-time MICT API integration.                                      |
| **Satisfaction prediction not wired**      | XGBoost model exists in `backend/ml/review_intelligence.py` but is NOT called by the recommendation API endpoint.     |
| **CP-SAT not implemented**                 | Itinerary optimizer uses greedy construction + 2-opt local search. CP-SAT is documented as future production upgrade. |
| **No load testing**                        | System has not been load-tested or security-audited.                                                                  |
| **No real guide credential verification**  | License numbers in guide profiles are synthetic.                                                                      |
| **Demo relies on synthetic seed data**     | All tourist/guide/rating data is generated for prototype demonstration.                                               |

### Demo Stability Notes

- **Flutter E2E tests**: Playwright toolchain issues in current environment; Flutter app tested manually
- **Backend API**: Stable; all core endpoints return valid responses
- **Database**: SQLite with seed data; reseed required after database reset

---

## 6. Test Commands Quick Reference

```bash
# Backend smoke test
cd backend && uv sync && python -c "import main; print('import ok')"

# Health check
curl http://localhost:8000/api/health

# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"tourist_test_1@test.com","password":"test123"}'

# Guide recommendations (replace {token})
curl http://localhost:8000/api/recommendations/T650C5838/guides \
  -H "Authorization: Bearer {token}"

# Safety score
curl -X POST http://localhost:8000/api/safety/score \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "plan_data": {
      "destination": "Luang Prabang",
      "tour_date_start": "2026-06-15T09:00:00",
      "tour_date_end": "2026-06-15T17:00:00",
      "transport_mode": "local_transport",
      "proposed_stops": [
        {"name": "Wat Xieng Thong", "venue_type": "temple", "duration_hours": 1.5},
        {"name": "Mount Phousi", "venue_type": "viewpoint", "duration_hours": 1.0},
        {"name": "Luang Prabang Night Market", "venue_type": "market", "duration_hours": 1.0},
        {"name": "Kuang Si Waterfall", "venue_type": "nature", "duration_hours": 2.0}
      ],
      "age_group": "26-35",
      "pace_preference": "moderate",
      "adventure_interest": 0.6
    }
  }'

# Group formation
curl -X POST http://localhost:8000/api/groups/form \
  -H "Content-Type: application/json" \
  -d '{"tourist_ids":["T650C5838","T650C5839","T650C5840"],"min_group_size":3,"max_group_size":8}'

# Pricing
curl -X POST http://localhost:8000/api/pricing/quote \
  -H "Content-Type: application/json" \
  -d '{
    "interest": "culture",
    "duration_hours": 4,
    "group_size": 3,
    "tour_date": "2026-06-15",
    "tour_hour": 9,
    "guide_id": "G001",
    "destination": "Luang Prabang",
    "currency": "USD"
  }'
```
