"""
WanderLess Product Smoke Tests
Tests the live backend API endpoints with seeded demo data.
Uses FastAPI TestClient (no HTTP server required).
"""

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"

for path in (str(ROOT), str(BACKEND)):
    if path not in sys.path:
        sys.path.insert(0, path)

try:
    from main import app
except Exception as exc:
    pytest.fail(
        f"Could not import backend FastAPI app. "
        f"Install dependencies first: pip install -r requirements.txt. "
        f"Original error: {exc}"
    )


@pytest.fixture
def client():
    return TestClient(app)


def _payload_text(payload) -> str:
    return str(payload).lower()


def _assert_no_legacy_terms(payload):
    """Fail if any legacy market term appears as a whole word in API output."""
    import re
    text = _payload_text(payload)
    # Use word boundaries for terms that could be substrings of legitimate words.
    # "thb" and "baht" could appear as currency codes; match them explicitly.
    forbidden = [
        r"\bchiang mai\b",
        r"\bthailand\b",
        r"\bbangkok\b",
        r"\bphuket\b",
        r"\bdoi suthep\b",
        r"\bwat phra singh\b",
        r"\bold city market\b",
        r"\bthb\b",
        r"\bbaht\b",
        r"\btat\b",
        r"\btourism authority of thailand\b",
        r"\bstb\b",
        r"\bsingapore tourism board\b",
    ]
    for pattern in forbidden:
        match = re.search(pattern, text, re.IGNORECASE)
        assert not match, (
            f"Legacy market term found in API output: '{match.group()}' "
            f"(matched pattern {pattern}). Output excerpt: {text[:500]}"
        )


def _get_auth_headers(client: TestClient) -> dict:
    response = client.post(
        "/api/auth/login",
        json={"email": "demo.tourist@wanderless.ai", "password": "demo123"},
    )
    assert response.status_code in (200, 201), (
        f"Login failed with status {response.status_code}: {response.text}"
    )
    payload = response.json()
    token = payload.get("access_token") or payload.get("token")
    assert token, f"No token in login response: {payload}"
    return {"Authorization": f"Bearer {token}", "tourist_id": payload.get("tourist_id", "demo")}


# ─────────────────────────────────────────────────────────────────────────────
# Test cases
# ─────────────────────────────────────────────────────────────────────────────

def test_health_endpoint(client: TestClient):
    response = client.get("/api/health")
    assert response.status_code == 200, response.text
    assert response.json(), "Health endpoint returned empty body"


def test_login_returns_token(client: TestClient):
    response = client.post(
        "/api/auth/login",
        json={"email": "demo.tourist@wanderless.ai", "password": "demo123"},
    )
    assert response.status_code in (200, 201), response.text
    payload = response.json()
    token = payload.get("access_token") or payload.get("token")
    assert token, f"No token in login response: {payload}"


def test_guide_recommendations_returns_ranked_list(client: TestClient):
    auth = _get_auth_headers(client)
    headers = {"Authorization": auth["Authorization"]}
    tid = auth.get("tourist_id", "T650C5838")
    response = client.get(f"/api/recommendations/{tid}/guides", headers=headers)
    assert response.status_code == 200, response.text
    payload = response.json()
    assert payload, "Expected non-empty guide recommendation list"
    assert len(payload) > 0, "Expected at least one guide recommendation"
    _assert_no_legacy_terms(payload)


def test_destination_recommendations_are_laos_consistent(client: TestClient):
    auth = _get_auth_headers(client)
    headers = {"Authorization": auth["Authorization"]}
    tid = auth.get("tourist_id", "T650C5838")
    response = client.get(
        f"/api/recommendations/{tid}/destinations", headers=headers
    )
    assert response.status_code == 200, response.text
    text = _payload_text(response.json())
    assert "laos" in text or "luang prabang" in text, (
        f"Expected Laos/Luang Prabang in destination recommendations; got: {text[:300]}"
    )
    _assert_no_legacy_terms(response.json())


def test_safety_score_endpoint(client: TestClient):
    headers = _get_auth_headers(client)
    response = client.post(
        "/api/safety/score",
        headers=headers,
        json={
            "plan_data": {
                "destination": "Luang Prabang",
                "tour_date_start": "2026-06-15T09:00:00",
                "tour_date_end": "2026-06-15T17:00:00",
                "transport_mode": "local_transport",
                "proposed_stops": [
                    {"name": "Wat Xieng Thong", "venue_type": "temple", "duration_hours": 1.5},
                    {"name": "Mount Phousi", "venue_type": "viewpoint", "duration_hours": 1.0},
                    {"name": "Luang Prabang Night Market", "venue_type": "market", "duration_hours": 1.0},
                    {"name": "Kuang Si Waterfall", "venue_type": "nature", "duration_hours": 2.0},
                ],
                "age_group": "26-35",
                "pace_preference": "moderate",
                "adventure_interest": 0.6,
            }
        },
    )
    assert response.status_code == 200, response.text
    payload = response.json()
    text = _payload_text(payload)
    assert any(kw in text for kw in ("score", "risk", "safety", "level")), (
        f"Safety response missing decision-support fields; got: {text[:300]}"
    )
    _assert_no_legacy_terms(payload)


def test_pricing_quote_endpoint(client: TestClient):
    response = client.post(
        "/api/pricing/quote",
        json={
            "interest": "culture",
            "duration_hours": 4,
            "group_size": 3,
            "tour_date": "2026-06-15",
            "tour_hour": 9,
            "guide_id": "G001",
            "destination": "Luang Prabang",
            "currency": "USD",
        },
    )
    assert response.status_code == 200, response.text
    payload = response.json()
    text = _payload_text(payload)
    assert any(kw in text for kw in ("price", "quote", "total", "usd")), (
        f"Pricing response missing commercial fields; got: {text[:300]}"
    )
    _assert_no_legacy_terms(payload)


def test_group_formation_endpoint(client: TestClient):
    headers = _get_auth_headers(client)
    response = client.post(
        "/api/groups/form",
        headers=headers,
        json={
            "destination": "Luang Prabang",
            "tourist_ids": ["T650C5838", "T650C5839", "T650C5840"],
            "min_group_size": 3,
            "max_group_size": 8,
        },
    )
    assert response.status_code in (200, 201), (
        f"Group formation failed with {response.status_code}: {response.text}"
    )
    _assert_no_legacy_terms(response.json())
