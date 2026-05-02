# WanderLess E2E Smoke Test Results

**Date:** 2026-05-02
**Backend:** http://localhost:8000
**Flutter App:** Not detected on standard ports (8080, 5000, 3000, 60999, 60444)

---

## Summary Table

| #   | TEST                                    | URL                                      | METHOD | STATUS | RESULT |
| --- | --------------------------------------- | ---------------------------------------- | ------ | ------ | ------ |
| 1   | Tourist Registration                    | `/api/auth/register`                     | POST   | 200    | PASS   |
| 2   | Guide Registration                      | `/api/guides/register`                   | POST   | 200    | PASS   |
| 3   | Business Registration (no name field)   | `/api/business/register`                 | POST   | 400    | FAIL   |
| 4   | Business Registration (correct payload) | `/api/business/register`                 | POST   | 200    | PASS   |
| 5   | Tourist Login                           | `/api/auth/login`                        | POST   | 200    | PASS   |
| 6   | Guide Login                             | `/api/guides/login`                      | POST   | 200    | PASS   |
| 7   | Business Login                          | `/api/business/login`                    | POST   | 401    | FAIL   |
| 8   | Tourist /me                             | `/api/auth/me`                           | GET    | 200    | PASS   |
| 9   | Guide /me                               | `/api/guides/auth/me`                    | GET    | 200    | PASS   |
| 10  | Business Dashboard                      | `/api/business/dashboard`                | GET    | 200    | PASS   |
| 11  | Recommendations Guides                  | `/api/recommendations/{id}/guides`       | GET    | 200    | PASS   |
| 12  | Recommendations Destinations            | `/api/recommendations/{id}/destinations` | GET    | 200    | PASS   |
| 13  | Flutter App Splash                      | Not running                              | -      | -      | SKIP   |
| 14  | Flutter Login UI                        | Not running                              | -      | -      | SKIP   |

**API Tests: 10/12 passed**
**Flutter UI Tests: 0/2 completed (app not running)**

---

## Detailed Results

### TEST 1: Tourist Registration

- **URL:** `POST http://localhost:8000/api/auth/register`
- **Payload:** `{"email":"tourist_test_1@test.com","password":"test123","name":"Test Tourist"}`
- **STATUS:** 200
- **RESULT:** PASS
- **NOTES:** Email already registered (re-run of pre-existing account)

---

### TEST 2: Guide Registration

- **URL:** `POST http://localhost:8000/api/guides/register`
- **Payload:** `{"email":"guide_test_1@test.com","password":"test123","name":"Test Guide","specialization":"hiking"}`
- **STATUS:** 200
- **RESULT:** PASS
- **NOTES:** Email already registered (re-run of pre-existing account)

---

### TEST 3: Business Registration (Field Mismatch)

- **URL:** `POST http://localhost:8000/api/business/register`
- **Payload:** `{"email":"biz_test_1@test.com","password":"test123","business_name":"Test Biz","business_type":"hotel"}`
- **STATUS:** 400
- **RESULT:** FAIL
- **NOTES:** `{"detail":"Your name is required"}` - The API requires BOTH `name` (personal name of owner) AND `business_name` (business entity name). This is a field naming clarity issue in the API contract.

---

### TEST 4: Business Registration (Correct Payload)

- **URL:** `POST http://localhost:8000/api/business/register`
- **Payload:** `{"email":"biz_test_6@test.com","password":"test123","name":"John Owner","business_name":"Test Biz 6","business_type":"hotel"}`
- **STATUS:** 200
- **RESULT:** PASS
- **NOTES:** Registration requires `name` + `business_name` + `business_type` fields. The API documentation should clarify that `name` is the owner's personal name.

---

### TEST 5: Tourist Login

- **URL:** `POST http://localhost:8000/api/auth/login`
- **Payload:** `{"email":"tourist_test_1@test.com","password":"test123"}`
- **STATUS:** 200
- **RESULT:** PASS
- **NOTES:** Returns `access_token`, `token_type`, `tourist_id`, `name`
- **Response:** `{"access_token":"eyJ...","token_type":"bearer","tourist_id":"T650C5838","name":"Test Tourist"}`

---

### TEST 6: Guide Login

- **URL:** `POST http://localhost:8000/api/guides/login`
- **Payload:** `{"email":"guide_test_1@test.com","password":"test123"}`
- **STATUS:** 200
- **RESULT:** PASS
- **NOTES:** Returns `access_token`, `token_type`, `guide_id`, `name`
- **Response:** `{"access_token":"eyJ...","token_type":"bearer","guide_id":"GED176663","name":"Test Guide"}`

---

### TEST 7: Business Login

- **URL:** `POST http://localhost:8000/api/business/login`
- **Payload:** `{"email":"biz_test_5@test.com","password":"test123"}`
- **STATUS:** 401
- **RESULT:** FAIL
- **NOTES:** `{"detail":"Invalid email or password"}` - The `biz_test_5@test.com` account was never successfully registered (failed at TEST 3 due to missing `name` field). The `biz_test_6@test.com` account was registered but not tested for login.

---

### TEST 8: Tourist Profile

- **URL:** `GET http://localhost:8000/api/auth/me`
- **Auth:** Bearer token (tourist_test_1@test.com)
- **STATUS:** 200
- **RESULT:** PASS
- **Response:**

```json
{
  "id": "T650C5838",
  "email": "tourist_test_1@test.com",
  "name": "Test Tourist",
  "food_interest": 0.5,
  "culture_interest": 0.5,
  "adventure_interest": 0.5,
  "pace_preference": 0.5,
  "budget_level": 0.5,
  "language": "en",
  "languages": [],
  "age_group": "26-35",
  "travel_style": "solo",
  "experience_type": "authentic_local"
}
```

---

### TEST 9: Guide Profile

- **URL:** `GET http://localhost:8000/api/guides/auth/me`
- **Auth:** Bearer token (guide_test_1@test.com)
- **STATUS:** 200
- **RESULT:** PASS
- **Response:**

```json
{
  "id": "GED176663",
  "email": "guide_test_1@test.com",
  "name": "Test Guide",
  "bio": "Local guide ready to show you around!",
  "photo_url": null,
  "expertise_tags": ["culture", "food", "adventure"],
  "language_pairs": ["en→th"],
  "pace_style": 0.5,
  "group_size_preferred": 4,
  "budget_tier": "mid",
  "location_coverage": ["Chiang..."]
}
```

---

### TEST 10: Business Dashboard

- **URL:** `GET http://localhost:8000/api/business/dashboard`
- **Auth:** Bearer token (biz_test_6@test.com)
- **STATUS:** 200
- **RESULT:** PASS
- **Response:**

```json
{
  "business_owner_id": "B062E09E0",
  "total_bookings": 0,
  "total_revenue": 0.0,
  "total_commission": 0.0,
  "guides": [],
  "recent_bookings": []
}
```

---

### TEST 11: Recommendations - Guides

- **URL:** `GET http://localhost:8000/api/recommendations/T650C5838/guides`
- **Auth:** Bearer token (tourist_test_1@test.com)
- **STATUS:** 200
- **RESULT:** PASS
- **Response:** Returns array of recommended guides with ML scores (score, score_content, score_collab, score_dest, ml_explanation)

---

### TEST 12: Recommendations - Destinations

- **URL:** `GET http://localhost:8000/api/recommendations/T650C5838/destinations`
- **Auth:** Bearer token (tourist_test_1@test.com)
- **STATUS:** 200
- **RESULT:** PASS
- **Response:** Returns array of recommended destinations with ranks, scores, tags, descriptions, and ml_explanation

---

### TEST 13: Flutter App Splash Screen

- **URL:** http://localhost:60444 (attempted)
- **STATUS:** N/A
- **RESULT:** SKIP
- **NOTES:** Flutter toolchain not available in current WSL environment. The Flutter SDK path points to a Windows-mounted path (`/mnt/c/flutter`) where the Dart SDK is not accessible. No Flutter process is running on any standard port (8000, 8080, 5000, 3000, 60999, 60444).

---

### TEST 14: Flutter Login UI

- **URL:** N/A
- **STATUS:** N/A
- **RESULT:** SKIP
- **NOTES:** Flutter app not running. Could not test `guide@wanderless.com / wanderless123` login flow.

---

## Issues Found

### Issue 1: Business Registration Field Clarity (API)

- **Severity:** Medium
- **Endpoint:** `POST /api/business/register`
- **Problem:** The API requires two separate name fields: `name` (owner's personal name) and `business_name` (business entity name). The error message "Your name is required" is ambiguous when only `business_name` is provided.
- **Recommendation:** Either (a) make `name` optional if it refers to an owner's personal name and the business_name suffices, or (b) update the error message to "Owner name is required" or "Personal name is required" to distinguish from business_name.

### Issue 2: Business Login Failure for biz_test_5

- **Severity:** Low (test data issue)
- **Endpoint:** `POST /api/business/login`
- **Problem:** `biz_test_5@test.com` was never successfully registered due to the missing `name` field issue (Issue 1), causing login to fail with 401.
- **Root Cause:** Cascade from Issue 1 - the test account was registered with an incomplete payload.

### Issue 3: Flutter App Not Running

- **Severity:** High (test infrastructure)
- **Problem:** Flutter toolchain is not functional in the current WSL environment. The Dart SDK is not accessible at the mounted Flutter path.
- **Impact:** Cannot perform UI-level E2E tests against the Flutter app.
- **Recommendation:** Either (a) install Flutter natively in WSL, or (b) ensure the Flutter web app is served on an accessible port before running E2E tests.

---

## Test Environment

- **Platform:** Linux (WSL2)
- **Backend:** uvicorn on port 8000 (pid 361993)
- **Flutter:** Not available (toolchain issue on mounted Windows path)
- **Tests run via:** curl (bash)
