# Demo API Commands

Test the backend API directly if the Flutter app is unavailable.

## Start Backend

```bash
cd backend
pip install -r requirements.txt
python main.py
```

Backend runs at `http://localhost:8000`. API docs at `http://localhost:8000/docs`.

## Health Check

```bash
curl http://localhost:8000/api/health
```

Expected: `{"status":"ok"}`

## Tourist Registration

```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "emma_test@test.com",
    "password": "test123",
    "full_name": "Emma"
  }'
```

## Login

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "emma_test@test.com",
    "password": "test123"
  }'
```

Returns a JWT token. Use it in the `Authorization: Bearer <token>` header for authenticated requests.

## Get Tourist Matches (Guide Recommendations)

```bash
# Register/update tourist with preferences first
curl -X PUT http://localhost:8000/api/tourists/<tourist_id>/preferences \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "language": "English",
    "budget": "medium",
    "pace": "slow",
    "interests": ["culture", "food", "heritage"],
    "safety_preference": "high"
  }'

# Get guide recommendations
curl http://localhost:8000/api/recommendations/<tourist_id>/guides?top_n=5 \
  -H "Authorization: Bearer <token>"
```

Expected response shape:

```json
[
  {
    "guide_id": "...",
    "name": "...",
    "score": 0.85,
    "score_content": 0.82,
    "score_collab": 0.78,
    "score_dest": 0.95
  }
]
```

## Get Matches

```bash
curl http://localhost:8000/api/matches/<tourist_id>?top_n=5 \
  -H "Authorization: Bearer <token>"
```

## Get All Guides

```bash
curl http://localhost:8000/api/guides
```

## Pricing Quote

```bash
curl -X POST http://localhost:8000/api/pricing/quote \
  -H "Content-Type: application/json" \
  -d '{
    "guide_id": "<guide_id>",
    "activity_type": "cultural_tour",
    "group_size": 2,
    "duration_hours": 4
  }'
```

## Create Trip Plan

```bash
curl -X POST http://localhost:8000/api/trip-plans \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "tourist_id": "<tourist_id>",
    "guide_id": "<guide_id>",
    "destination": "Luang Prabang",
    "duration_days": 4
  }'
```

## Run Tests

```bash
pytest tests/ -v
```

Expected: 14/14 passed.
