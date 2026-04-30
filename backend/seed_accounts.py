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
sys.path.insert(0, '.')

from database import SessionLocal, init_db
from models import Tourist, Guide, BusinessOwner

TEST_PASSWORD_HASH = "$2b$12$ZHbhAaNbDlM2HAk4vdw7COPsdw/oqL/2Hc0uFpOZUUgzBMVsmz3Xy"


def seed_test_business(db: SessionLocal):
    existing = db.query(BusinessOwner).filter_by(email="business@wanderless.com").first()
    if existing:
        print(f"  Business owner already exists: {existing.id}")
        return existing
    owner = BusinessOwner(
        id=f"B{uuid.uuid4().hex[:8].upper()}",
        email="business@wanderless.com",
        password_hash=TEST_PASSWORD_HASH,
        business_name="Chiang Mai Tours Co.",
        commission_rate=0.15,
    )
    db.add(owner)
    db.commit()
    print(f"  Business: business@wanderless.com / wanderless123  (id={owner.id})")
    return owner


def seed_test_tourist(db: SessionLocal):
    existing = db.query(Tourist).filter_by(email="test@wanderless.com").first()
    if existing:
        print(f"  Tourist already exists: {existing.id}")
        return
    tourist = Tourist(
        id=f"T{uuid.uuid4().hex[:8].upper()}",
        email="test@wanderless.com",
        password_hash=TEST_PASSWORD_HASH,
        name="Test Tourist",
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
        print(f"  Guide already exists: {existing.id} — updating password_hash")
        existing.password_hash = TEST_PASSWORD_HASH
        db.commit()
        return existing
    # Bind to an existing seeded guide (first guide in database)
    guide = db.query(Guide).first()
    if not guide:
        print("  ERROR: No guides found — run init_db first")
        return None
    guide.email = "guide@wanderless.com"
    guide.password_hash = TEST_PASSWORD_HASH
    guide.license_verified = True
    db.commit()
    print(f"  Guide: guide@wanderless.com / wanderless123  (id={guide.id}, name={guide.name})")
    return guide


def main():
    db = SessionLocal()
    init_db(db)
    print("Seeding test accounts...")
    owner = seed_test_business(db)
    seed_test_tourist(db)
    guide = seed_test_guide(db)

    # Link the guide to the business owner
    if guide and owner and not guide.owner_id:
        guide.owner_id = owner.id
        db.commit()
        print(f"  Linked guide {guide.id} -> business {owner.id}")

    db.close()
    print("Done.")


if __name__ == "__main__":
    main()

