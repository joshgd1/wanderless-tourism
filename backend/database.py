"""
SQLite database setup + CSV seeding from synthetic data.
"""

import csv
import math
import os
import random
from pathlib import Path
from typing import Optional

from sqlalchemy import create_engine, delete, text
from sqlalchemy.orm import sessionmaker, Session

from models import Base, Tourist, Guide, Rating, TripPlan

DATA_DIR = Path(__file__).parent.parent / "data"

engine = create_engine(
    f"sqlite:///{Path(__file__).parent}/wanderless.db",
    connect_args={"check_same_thread": False},
)
SessionLocal = sessionmaker(bind=engine)


def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Test account password hash — same value used by seed_accounts.py
_TEST_PASSWORD_HASH = "$2b$12$eCcT/GO4Hj.fAqgihcxO/epKof8E9rxObeKjW9llKS7sViNyi7SX2"


def _seed_test_guide(db: Session) -> None:
    """Ensure guide@wanderless.com exists with the test password hash.

    Called on every init_db to handle Render free-tier container restarts
    (the database file is wiped on sleep, so seed data is lost).
    """
    existing = db.query(Guide).filter_by(email="guide@wanderless.com").first()
    if existing:
        existing.password_hash = _TEST_PASSWORD_HASH
        existing.name = "Mei Ling"
        existing.bio = (
            "Passionate Singapore guide specializing in cultural heritage walks through "
            "Chinatown, Little India, and Gardens by the Bay."
        )
        existing.photo_url = "https://picsum.photos/seed/mei_ling_guide/400/400"
        existing.license_verified = True
        db.commit()
        return

    # No guide@wanderless.com yet — bind to first available guide
    guide = db.query(Guide).first()
    if not guide:
        return  # No guides seeded yet; seed_test_guide from reseed will handle
    guide.email = "guide@wanderless.com"
    guide.password_hash = _TEST_PASSWORD_HASH
    guide.name = "Mei Ling"
    guide.bio = (
        "Passionate Singapore guide specializing in cultural heritage walks through "
        "Chinatown, Little India, and Gardens by the Bay."
    )
    guide.photo_url = "https://picsum.photos/seed/mei_ling_guide/400/400"
    guide.license_verified = True
    db.commit()


def _seed_test_tourist(db: Session) -> None:
    """Ensure test@wanderless.com exists with the test password hash.

    Uses a fixed ID so the touristId is stable across container restarts.
    """
    existing = db.query(Tourist).filter_by(email="test@wanderless.com").first()
    if existing:
        existing.name = "Alex Traveler"
        existing.password_hash = _TEST_PASSWORD_HASH
        existing.food_interest = 0.5
        existing.culture_interest = 0.5
        existing.adventure_interest = 0.5
        existing.pace_preference = 0.5
        existing.budget_level = 0.5
        existing.language = "en"
        existing.age_group = "26-35"
        existing.travel_style = "solo"
        existing.experience_type = "authentic_local"
        existing.energy_curve = "|".join(["0.5"] * 24)
        db.commit()
        _ensure_test_wallet(db, existing.id, "tourist")
        return

    tourist = Tourist(
        id="TTEST001",
        email="test@wanderless.com",
        password_hash=_TEST_PASSWORD_HASH,
        name="Alex Traveler",
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
    _ensure_test_wallet(db, tourist.id, "tourist")


def _seed_test_business(db: Session) -> None:
    """Ensure business@wanderless.com exists with the test password hash."""
    existing = db.query(BusinessOwner).filter_by(email="business@wanderless.com").first()
    if existing:
        existing.business_name = "Chiang Mai Adventures"
        existing.commission_rate = 0.15
        existing.phone = "+66 81 234 5678"
        db.commit()
        return

    owner = BusinessOwner(
        id="BTEST001",
        email="business@wanderless.com",
        password_hash=_TEST_PASSWORD_HASH,
        name="Business Owner",
        business_name="Chiang Mai Adventures",
        commission_rate=0.15,
        phone="+66 81 234 5678",
    )
    db.add(owner)
    db.commit()


def _ensure_test_wallet(db: Session, owner_id: str, owner_type: str) -> None:
    """Ensure a wallet exists with initial balance for the test tourist."""
    wallet = db.query(Wallet).filter_by(owner_id=owner_id, owner_type=owner_type).first()
    if wallet:
        if wallet.balance < 1000:
            wallet.balance = 5000.0
            db.commit()
        return
    wallet = Wallet(
        id=f"W{uuid.uuid4().hex[:8].upper()}",
        owner_id=owner_id,
        owner_type=owner_type,
        balance=5000.0,
        currency="SGD",
    )
    db.add(wallet)
    txn = WalletTransaction(
        wallet_id=wallet.id,
        txn_type="deposit",
        amount=5000.0,
        description="Initial demo deposit",
    )
    db.add(txn)
    db.commit()


def init_db(db: Session) -> None:
    """Create tables if missing; seed CSV data only if tables are empty."""
    Base.metadata.create_all(bind=engine)
    # Schema migrations for columns added after initial table creation
    _migrate_bookings_schema(db)
    # Only seed from CSV if tables are empty (preserve seeded accounts)
    if db.query(Tourist).count() == 0:
        _seed_tourists(db)
    if db.query(Guide).count() == 0:
        _seed_guides(db)
    if db.query(Rating).count() == 0:
        _seed_ratings(db)
    # Always ensure test accounts exist with correct credentials
    # (handles Render free-tier container restarts where DB is wiped)
    _seed_test_tourist(db)
    _seed_test_guide(db)
    _seed_test_business(db)
    db.commit()


def _migrate_bookings_schema(db: Session) -> None:
    """Add missing columns to existing tables (SQLite ALTER TABLE)."""
    # Booking schema migrations
    result = db.execute(text("PRAGMA table_info(bookings)")).fetchall()
    existing_cols = {row[1] for row in result}
    if "insurance_pct" not in existing_cols:
        db.execute(text("ALTER TABLE bookings ADD COLUMN insurance_pct REAL DEFAULT 0.05"))
    if "platform_commission_pct" not in existing_cols:
        db.execute(text("ALTER TABLE bookings ADD COLUMN platform_commission_pct REAL DEFAULT 0.15"))

    # Guide schema migrations (license fields for Singapore STB compliance)
    guide_result = db.execute(text("PRAGMA table_info(guides)")).fetchall()
    guide_cols = {row[1] for row in guide_result}
    if "license_number" not in guide_cols:
        db.execute(text("ALTER TABLE guides ADD COLUMN license_number TEXT"))
    if "license_type" not in guide_cols:
        db.execute(text("ALTER TABLE guides ADD COLUMN license_type TEXT"))
    if "license_country" not in guide_cols:
        db.execute(text("ALTER TABLE guides ADD COLUMN license_country TEXT"))
    if "license_expiry" not in guide_cols:
        db.execute(text("ALTER TABLE guides ADD COLUMN license_expiry TEXT"))


def _seed_tourists(db: Session) -> None:
    path = DATA_DIR / "tourist_profiles.csv"
    seen_ids = set()
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["tourist_id"] in seen_ids:
                continue
            seen_ids.add(row["tourist_id"])
            tourist = Tourist(
                id=row["tourist_id"],
                food_interest=float(row["food_interest"]),
                culture_interest=float(row["culture_interest"]),
                adventure_interest=float(row["adventure_interest"]),
                pace_preference=float(row["pace_preference"]),
                budget_level=float(row["budget_level"]),
                language=row["language"],
                age_group=row["age_group"],
                travel_style=row["travel_style"],
                energy_curve=row["energy_curve"],
            )
            db.add(tourist)


def _seed_guides(db: Session) -> None:
    path = DATA_DIR / "guide_profiles.csv"
    seen_ids = set()
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["guide_id"] in seen_ids:
                continue
            seen_ids.add(row["guide_id"])
            guide = Guide(
                id=row["guide_id"],
                name=f"Guide {row['guide_id']}",
                bio="Experienced local guide with deep knowledge of the region.",
                photo_url=f"https://picsum.photos/seed/{row['guide_id']}/200/200",
                expertise_tags=row["expertise_tags"],
                personality_vector=row["personality_vector"],
                language_pairs=row["language_pairs"],
                pace_style=float(row["pace_style"]),
                group_size_preferred=int(row["group_size_preferred"]),
                budget_tier=row["budget_tier"],
                location_coverage=row["location_coverage"],
                availability=row["availability"],
                rating_history=float(row["rating_history"]),
                rating_count=int(row["rating_count"]),
                specialties=row["specialties"],
                license_verified=row["license_verified"] == "True",
                license_number=row["license_number"] or None,
                license_type=row["license_type"] or None,
                license_country=row["license_country"] or None,
                license_expiry=None,  # populated below if present
            )
            # Parse license_expiry from CSV if present and non-empty
            if row.get("license_expiry"):
                from datetime import datetime
                guide.license_expiry = datetime.strptime(row["license_expiry"], "%Y-%m-%d")
            db.add(guide)


def _seed_ratings(db: Session) -> None:
    path = DATA_DIR / "synthetic_ratings.csv"
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rating = Rating(
                tourist_id=row["tourist_id"],
                guide_id=row["guide_id"],
                booking_id=None,
                rating=float(row["rating"]),
                is_poor_experience=row["is_poor_experience"] == "True",
                norm_dot_product=float(row["norm_dot_product"]),
                language_match=float(row["language_match"]),
                budget_alignment=float(row["budget_alignment"]),
                pace_alignment=float(row["pace_alignment"]),
                predicted_rating=float(row["predicted_rating"]),
                rating_source=row["rating_source"],
            )
            db.add(rating)


# Global dot range for matching (computed once from all tourist-guide pairs)
_dot_range: Optional[tuple[float, float]] = None


def compute_dot_range(db: Session) -> tuple[float, float]:
    """Compute actual dot product range across all tourist-guide pairs."""
    global _dot_range
    if _dot_range is not None:
        return _dot_range

    tourists = db.query(Tourist).all()
    guides = db.query(Guide).all()

    def interest_vec(t: Tourist) -> list[float]:
        return [t.food_interest, t.culture_interest, t.adventure_interest]

    def unit_vector(v: list[float]) -> list[float]:
        norm = math.sqrt(sum(x * x for x in v))
        return [x / norm for x in v] if norm else v

    def expertise_vec(g: Guide) -> list[float]:
        tags = (g.expertise_tags or "").split("|")
        expertise_map = {
            "food": (1.0, 0.0, 0.0),
            "culture": (0.0, 1.0, 0.0),
            "adventure": (0.0, 0.0, 1.0),
            "history": (0.1, 0.9, 0.0),
            "temples": (0.0, 0.8, 0.2),
            "nature": (0.0, 0.1, 0.9),
            "trekking": (0.0, 0.1, 0.9),
            "photography": (0.1, 0.5, 0.4),
            "art": (0.1, 0.7, 0.2),
            "nightlife": (0.3, 0.1, 0.1),
            "shopping": (0.4, 0.1, 0.1),
            "wellness": (0.2, 0.3, 0.2),
            "cooking": (0.8, 0.1, 0.1),
            "markets": (0.5, 0.2, 0.1),
            "rural": (0.0, 0.2, 0.7),
            "river": (0.0, 0.1, 0.8),
        }
        ev = [0.0, 0.0, 0.0]
        for tag in tags:
            if tag in expertise_map:
                for i, v in enumerate(expertise_map[tag]):
                    ev[i] = max(ev[i], v)
        return unit_vector(ev) if any(ev) else ev

    dots = []
    for t in tourists:
        t_vec = interest_vec(t)
        for g in guides:
            g_vec = expertise_vec(g)
            dot = sum(a * b for a, b in zip(t_vec, g_vec))
            dots.append(dot)

    _dot_range = (min(dots), max(dots))
    return _dot_range
