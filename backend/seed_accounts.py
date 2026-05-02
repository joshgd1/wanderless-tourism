"""
Seed test accounts for development/testing.

Usage:
    python seed_accounts.py

Creates:
    Tourist: test@wanderless.com / wanderless123
    Guide:   guide@wanderless.com / wanderless123
    Business Owner: business@wanderless.com / wanderless123

Login the app with any of these accounts.
"""

import uuid
import sys
from datetime import datetime, timedelta
sys.path.insert(0, '.')

from database import SessionLocal, init_db
from models import Tourist, Guide, BusinessOwner, Booking, LocationTracking

TEST_PASSWORD_HASH = "$2b$12$eCcT/GO4Hj.fAqgihcxO/epKof8E9rxObeKjW9llKS7sViNyi7SX2"


def seed_test_business(db: SessionLocal):
    existing = db.query(BusinessOwner).filter_by(email="business@wanderless.com").first()
    if existing:
        print(f"  Business owner already exists: {existing.id} — updating fields")
        existing.business_name = "Chiang Mai Adventures"
        existing.commission_rate = 0.15
        existing.phone = "+66 81 234 5678"
        db.commit()
        return existing
    owner = BusinessOwner(
        id=f"B{uuid.uuid4().hex[:8].upper()}",
        email="business@wanderless.com",
        password_hash=TEST_PASSWORD_HASH,
        business_name="Chiang Mai Adventures",
        commission_rate=0.15,
        phone="+66 81 234 5678",
    )
    db.add(owner)
    db.commit()
    print(f"  Business: business@wanderless.com / wanderless123  (id={owner.id})")
    return owner


def seed_test_tourist(db: SessionLocal):
    existing = db.query(Tourist).filter_by(email="test@wanderless.com").first()
    if existing:
        print(f"  Tourist already exists: {existing.id} — updating fields")
        existing.name = "Alex Traveler"
        existing.photo_url = f"https://picsum.photos/seed/alex_tourist/400/400"
        db.commit()
        return
    tourist = Tourist(
        id=f"T{uuid.uuid4().hex[:8].upper()}",
        email="test@wanderless.com",
        password_hash=TEST_PASSWORD_HASH,
        name="Alex Traveler",
        photo_url=f"https://picsum.photos/seed/alex_tourist/400/400",
        food_interest=0.5,
        culture_interest=0.5,
        adventure_interest=0.5,
        pace_preference=0.5,
        budget_level=0.5,
        language="en",
        age_group="26-35",
        travel_style="solo",
        experience_type="authentic_local",
        energy_curve="|".join(["0.5"] * 24),
    )
    db.add(tourist)
    db.commit()
    print(f"  Tourist: test@wanderless.com / wanderless123  (id={tourist.id})")


def seed_test_guide(db: SessionLocal):
    existing = db.query(Guide).filter_by(email="guide@wanderless.com").first()
    if existing:
        print(f"  Guide already exists: {existing.id} — updating fields")
        existing.password_hash = TEST_PASSWORD_HASH
        existing.name = "Somchai Thailand"
        existing.bio = "Local guide with 8 years of experience showing visitors the authentic side of Chiang Mai — from hidden temples to the best street food stalls. Born and raised here, I love sharing my culture."
        existing.photo_url = f"https://picsum.photos/seed/somchai_guide/400/400"
        existing.license_verified = True
        db.commit()
        return existing
    # Bind to an existing seeded guide (first guide in database)
    guide = db.query(Guide).first()
    if not guide:
        print("  ERROR: No guides found — run init_db first")
        return None
    guide.email = "guide@wanderless.com"
    guide.password_hash = TEST_PASSWORD_HASH
    guide.name = "Somchai Thailand"
    guide.bio = "Local guide with 8 years of experience showing visitors the authentic side of Chiang Mai — from hidden temples to the best street food stalls. Born and raised here, I love sharing my culture."
    guide.photo_url = f"https://picsum.photos/seed/somchai_guide/400/400"
    guide.license_verified = True
    db.commit()
    print(f"  Guide: guide@wanderless.com / wanderless123  (id={guide.id}, name={guide.name})")
    return guide


def seed_fake_location_tracking(db: SessionLocal, guide: Guide, tourist: Tourist):
    """Seed fake GPS location for demo — guide and tourist markers on the map."""
    existing = db.query(LocationTracking).join(Booking).filter(
        Booking.guide_id == guide.id
    ).first()
    if existing:
        print(f"  Location tracking already exists for guide {guide.id}")
        return
    booking = db.query(Booking).filter_by(guide_id=guide.id).first()
    if not booking:
        print("  No booking found for location tracking seed")
        return
    loc = LocationTracking(
        booking_id=booking.id,
        # Guide at a popular temple viewpoint
        guide_lat=18.8047,
        guide_lng=98.9219,
        # Tourist slightly south at a nearby point
        tourist_lat=18.7923,
        tourist_lng=98.9853,
    )
    db.add(loc)
    db.commit()
    print(f"  Fake location tracking seeded for booking {booking.id}")


def seed_synthetic_bookings(db: SessionLocal, guide: Guide, tourist: Tourist):
    """Create synthetic bookings for the test guide so business dashboard isn't empty."""
    # Only seed if no bookings exist for this guide
    existing = db.query(Booking).filter_by(guide_id=guide.id).first()
    if existing:
        print(f"  Bookings already exist for guide {guide.id}")
        return

    destinations = [
        ("Doi Suthep Temple", 4.0, 2),
        ("Old City Walking Tour", 3.0, 3),
        ("Mae Sa Valley Trek", 6.0, 2),
        ("Night Bazaar Food Tour", 2.5, 4),
        ("Doi Inthanon National Park", 8.0, 2),
    ]

    now = datetime.utcnow()
    for i, (dest, duration, group_size) in enumerate(destinations):
        # Vary statuses: mix of COMPLETED, CONFIRMED, IN_PROGRESS
        statuses = ["COMPLETED", "COMPLETED", "CONFIRMED", "IN_PROGRESS"]
        status = statuses[i % len(statuses)]
        payment_status = "released" if status == "COMPLETED" else "held_escrow"
        gross = 1500.0 + (i * 250)

        booking = Booking(
            tourist_id=tourist.id,
            guide_id=guide.id,
            destination=dest,
            tour_date=(now + timedelta(days=i + 1)).strftime("%Y-%m-%d"),
            duration_hours=duration,
            group_size=group_size,
            gross_value=gross,
            platform_commission_pct=0.15,
            status=status,
            payment_status=payment_status,
        )
        db.add(booking)

    db.commit()
    print(f"  Created {len(destinations)} synthetic bookings for guide {guide.id}")


def main():
    db = SessionLocal()
    init_db(db)
    print("Seeding test accounts...")
    owner = seed_test_business(db)
    seed_test_tourist(db)
    guide = seed_test_guide(db)

    # Get the tourist object for booking creation
    tourist = db.query(Tourist).filter_by(email="test@wanderless.com").first()

    # Link the guide to the business owner
    if guide and owner and not guide.owner_id:
        guide.owner_id = owner.id
        db.commit()
        print(f"  Linked guide {guide.id} -> business {owner.id}")

    # Seed synthetic bookings for the guide
    if guide and tourist:
        seed_synthetic_bookings(db, guide, tourist)

    # Seed fake GPS locations for map tracking demo
    if guide and tourist:
        seed_fake_location_tracking(db, guide, tourist)

    db.close()
    print("Done.")


if __name__ == "__main__":
    main()

