"""
Seed test accounts for development/testing.

Usage:
    python seed_accounts.py

Creates:
    Tourist: test@wanderless.com / wanderless123
    Guide:   guide@wanderless.com / wanderless123  (binds to G001)

Login the app with any of these accounts.
"""

import uuid
import sys
sys.path.insert(0, '.')

from database import SessionLocal, init_db
from models import Tourist, Guide

TEST_PASSWORD_HASH = "$2b$12$ZHbhAaNbDlM2HAk4vdw7COPsdw/oqL/2Hc0uFpOZUUgzBMVsmz3Xy"


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
        print(f"  Guide already exists: {existing.id}")
        return
    # Bind to an existing seeded guide (first guide in database)
    guide = db.query(Guide).first()
    if not guide:
        print("  ERROR: No guides found — run init_db first")
        return
    if guide.email:
        print(f"  Guide G001 already has email: {guide.email}")
        return
    guide.email = "guide@wanderless.com"
    guide.password_hash = TEST_PASSWORD_HASH
    db.commit()
    print(f"  Guide: guide@wanderless.com / wanderless123  (id={guide.id}, name={guide.name})")


def main():
    db = SessionLocal()
    init_db(db)
    print("Seeding test accounts...")
    seed_test_tourist(db)
    seed_test_guide(db)
    db.close()
    print("Done.")


if __name__ == "__main__":
    main()

