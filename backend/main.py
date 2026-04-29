"""
FastAPI application — WanderLess backend.
"""

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database import init_db, get_db, compute_dot_range
from matching import compatibility_score, top_matches
import models  # noqa: F401 — models registered with Base.metadata

logger = logging.getLogger("wanderless")
logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: seed DB from CSV
    db = next(get_db())
    init_db(db)
    db.close()
    logger.info("wanderless.startup database_seeded")
    yield
    logger.info("wanderless.shutdown server_shutdown")


app = FastAPI(title="WanderLess API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health")
async def health():
    return {"status": "ok"}


@app.post("/api/admin/reseed")
async def reseed_database(db: Session = Depends(get_db)):
    """Delete and re-seed the database. Use after CSV encoding fixes."""
    import os
    init_db(db)
    db.commit()
    db_path = os.path.join(os.path.dirname(__file__), "wanderless.db")
    logger.info(f"database.reseed complete")
    return {"status": "reseeded"}


@app.get("/api/tourists/{tourist_id}")
async def get_tourist(tourist_id: str, db: Session = Depends(get_db)):
    t = db.query(models.Tourist).filter_by(id=tourist_id).first()
    if not t:
        raise HTTPException(status_code=404, detail="Tourist not found")
    return {
        "id": t.id,
        "food_interest": t.food_interest,
        "culture_interest": t.culture_interest,
        "adventure_interest": t.adventure_interest,
        "pace_preference": t.pace_preference,
        "budget_level": t.budget_level,
        "language": t.language,
        "age_group": t.age_group,
        "travel_style": t.travel_style,
    }


@app.post("/api/tourists")
async def create_tourist(data: dict, db: Session = Depends(get_db)):
    import uuid
    tourist_id = data.get("id") or f"T{uuid.uuid4().hex[:8].upper()}"
    t = models.Tourist(
        id=tourist_id,
        food_interest=data["food_interest"],
        culture_interest=data["culture_interest"],
        adventure_interest=data["adventure_interest"],
        pace_preference=data["pace_preference"],
        budget_level=data["budget_level"],
        language=data["language"],
        age_group=data.get("age_group", "26-35"),
        travel_style=data.get("travel_style", "solo"),
        energy_curve="|".join(["0.5"] * 24),
    )
    db.add(t)
    db.commit()
    db.refresh(t)
    return {"id": t.id}


@app.get("/api/guides")
async def list_guides(db: Session = Depends(get_db)):
    guides = db.query(models.Guide).all()
    return [
        {
            "id": g.id,
            "name": g.name,
            "bio": g.bio,
            "photo_url": g.photo_url,
            "expertise_tags": g.expertise_tags.split("|"),
            "language_pairs": g.language_pairs.split("|"),
            "pace_style": g.pace_style,
            "group_size_preferred": g.group_size_preferred,
            "budget_tier": g.budget_tier,
            "location_coverage": g.location_coverage.split("|"),
            "rating_history": g.rating_history,
            "rating_count": g.rating_count,
            "specialties": g.specialties.split("|"),
        }
        for g in guides
    ]


@app.get("/api/guides/{guide_id}")
async def get_guide(guide_id: str, db: Session = Depends(get_db)):
    g = db.query(models.Guide).filter_by(id=guide_id).first()
    if not g:
        raise HTTPException(status_code=404, detail="Guide not found")
    return {
        "id": g.id,
        "name": g.name,
        "bio": g.bio,
        "photo_url": g.photo_url,
        "expertise_tags": g.expertise_tags.split("|"),
        "personality_vector": [float(x) for x in g.personality_vector.split("|")],
        "language_pairs": g.language_pairs.split("|"),
        "pace_style": g.pace_style,
        "group_size_preferred": g.group_size_preferred,
        "budget_tier": g.budget_tier,
        "location_coverage": g.location_coverage.split("|"),
        "availability": g.availability,
        "rating_history": g.rating_history,
        "rating_count": g.rating_count,
        "specialties": g.specialties.split("|"),
    }


@app.get("/api/matches/{tourist_id}")
async def get_matches(tourist_id: str, top_n: int = 5, db: Session = Depends(get_db)):
    t0 = time.monotonic()
    logger.info(f"matches.start tourist_id={tourist_id} top_n={top_n}")

    tourist = db.query(models.Tourist).filter_by(id=tourist_id).first()
    if not tourist:
        raise HTTPException(status_code=404, detail="Tourist not found")

    guides = db.query(models.Guide).all()
    dot_range = compute_dot_range(db)
    scored = top_matches(tourist, guides, dot_range, top_n)

    # Enrich with guide details
    guide_map = {g.id: g for g in guides}
    results = []
    for item in scored:
        g = guide_map[item["guide_id"]]
        results.append({
            "guide_id": g.id,
            "name": g.name,
            "photo_url": g.photo_url,
            "bio": g.bio,
            "expertise_tags": g.expertise_tags.split("|"),
            "rating_history": g.rating_history,
            "rating_count": g.rating_count,
            "budget_tier": g.budget_tier,
            "score": item["score"],
            "lang_match": item["lang_match"],
        })

    logger.info(f"matches.ok tourist_id={tourist_id} count={len(results)} latency_ms={(time.monotonic() - t0) * 1000:.1f}")
    return results


@app.post("/api/bookings")
async def create_booking(data: dict, db: Session = Depends(get_db)):
    b = models.Booking(
        tourist_id=data["tourist_id"],
        guide_id=data["guide_id"],
        destination=data.get("destination", "Chiang Mai"),
        tour_date=data["tour_date"],
        duration_hours=data.get("duration_hours", 4.0),
        group_size=data.get("group_size", 1),
        gross_value=data.get("gross_value", 1500.0),
        status="REQUESTED",
        payment_status="held_escrow",
    )
    db.add(b)
    db.commit()
    db.refresh(b)
    logger.info(f"booking.created booking_id={b.id} tourist_id={b.tourist_id} guide_id={b.guide_id}")
    return {"id": b.id, "status": b.status}


@app.get("/api/bookings/{booking_id}")
async def get_booking(booking_id: int, db: Session = Depends(get_db)):
    b = db.query(models.Booking).filter_by(id=booking_id).first()
    if not b:
        raise HTTPException(status_code=404, detail="Booking not found")
    return {
        "id": b.id,
        "tourist_id": b.tourist_id,
        "guide_id": b.guide_id,
        "destination": b.destination,
        "tour_date": b.tour_date,
        "duration_hours": b.duration_hours,
        "group_size": b.group_size,
        "gross_value": b.gross_value,
        "status": b.status,
        "payment_status": b.payment_status,
    }


@app.put("/api/bookings/{booking_id}/status")
async def update_booking_status(booking_id: int, data: dict, db: Session = Depends(get_db)):
    b = db.query(models.Booking).filter_by(id=booking_id).first()
    if not b:
        raise HTTPException(status_code=404, detail="Booking not found")
    b.status = data["status"]
    db.commit()
    logger.info(f"booking.status_updated booking_id={booking_id} status={b.status}")
    return {"id": b.id, "status": b.status}


@app.get("/api/itineraries/{booking_id}")
async def get_itinerary(booking_id: int, db: Session = Depends(get_db)):
    it = db.query(models.Itinerary).filter_by(booking_id=booking_id).first()
    if not it:
        # Return a default itinerary if none exists
        return {
            "id": None,
            "booking_id": booking_id,
            "stops": [
                {"name": "Old City Temple Visit", "order": 1, "duration_hours": 1.5},
                {"name": "Local Market Lunch", "order": 2, "duration_hours": 1.0},
                {"name": "Doi Suthep Temple", "order": 3, "duration_hours": 2.0},
            ],
            "status": "proposed",
        }
    return {
        "id": it.id,
        "booking_id": it.booking_id,
        "stops": it.stops,
        "status": it.status,
    }


@app.put("/api/itineraries/{itinerary_id}")
async def update_itinerary(itinerary_id: int, data: dict, db: Session = Depends(get_db)):
    it = db.query(models.Itinerary).filter_by(id=itinerary_id).first()
    if not it:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    if "stops" in data:
        it.stops = data["stops"]
    if "status" in data:
        it.status = data["status"]
    db.commit()
    logger.info(f"itinerary.updated itinerary_id={itinerary_id}")
    return {"id": it.id, "stops": it.stops, "status": it.status}


@app.post("/api/ratings")
async def create_rating(data: dict, db: Session = Depends(get_db)):
    r = models.Rating(
        tourist_id=data["tourist_id"],
        guide_id=data["guide_id"],
        booking_id=data.get("booking_id"),
        rating=data["rating"],
        is_poor_experience=data.get("is_poor_experience", data["rating"] < 2.5),
        norm_dot_product=data.get("norm_dot_product", 0.5),
        language_match=data.get("language_match", 0.0),
        budget_alignment=data.get("budget_alignment", 0.8),
        pace_alignment=data.get("pace_alignment", 0.8),
        predicted_rating=data.get("predicted_rating", data["rating"]),
        rating_source="app",
    )
    db.add(r)
    db.commit()
    db.refresh(r)
    logger.info(f"rating.created tourist_id={r.tourist_id} guide_id={r.guide_id} rating={r.rating}")
    return {"id": r.id, "rating": r.rating}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
