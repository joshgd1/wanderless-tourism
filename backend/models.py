"""
Database models — SQLite schema seeded from CSV synthetic data.
"""

from datetime import datetime
from typing import Optional
from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    Float,
    Boolean,
    JSON,
    DateTime,
    ForeignKey,
    Text,
)
from sqlalchemy.orm import declarative_base, relationship, Session
from sqlalchemy.pool import StaticPool

Base = declarative_base()


class BusinessOwner(Base):
    __tablename__ = "business_owners"

    id = Column(String, primary_key=True)
    email = Column(String, unique=True, nullable=True)
    password_hash = Column(String, nullable=True)
    name = Column(String)  # owner's personal name
    business_name = Column(String)
    commission_rate = Column(Float, default=0.15)  # 15% platform commission
    phone = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Tourist(Base):
    __tablename__ = "tourists"

    id = Column(String, primary_key=True)
    email = Column(String, unique=True, nullable=True)
    password_hash = Column(String, nullable=True)
    name = Column(String, nullable=True)
    food_interest = Column(Float)
    culture_interest = Column(Float)
    adventure_interest = Column(Float)
    pace_preference = Column(Float)
    budget_level = Column(Float)
    language = Column(String)  # single language (backwards compat)
    languages = Column(String, nullable=True)  # pipe-delimited multi-select e.g. "en|zh|th"
    age_group = Column(String)
    travel_style = Column(String)
    experience_type = Column(String, default="authentic_local")  # 'authentic_local' | 'tourist_friendly'
    energy_curve = Column(String)  # pipe-delimited
    created_at = Column(DateTime, default=datetime.utcnow)


class Guide(Base):
    __tablename__ = "guides"

    id = Column(String, primary_key=True)
    email = Column(String, unique=True, nullable=True)
    password_hash = Column(String, nullable=True)
    name = Column(String)
    bio = Column(Text)
    photo_url = Column(String)
    expertise_tags = Column(String)  # pipe-delimited
    personality_vector = Column(String)  # pipe-delimited
    language_pairs = Column(String)  # pipe-delimited "en→th|ru→th"
    pace_style = Column(Float)
    group_size_preferred = Column(Integer)
    budget_tier = Column(String)
    location_coverage = Column(String)  # pipe-delimited
    availability = Column(JSON)
    rating_history = Column(Float)
    rating_count = Column(Integer)
    specialties = Column(String)  # pipe-delimited
    license_verified = Column(Boolean, default=False)
    owner_id = Column(String, ForeignKey("business_owners.id"), nullable=True)  # nullable: independent guides
    created_at = Column(DateTime, default=datetime.utcnow)


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, autoincrement=True)
    tourist_id = Column(String, ForeignKey("tourists.id"))
    guide_id = Column(String, ForeignKey("guides.id"))
    destination = Column(String)
    tour_date = Column(String)
    duration_hours = Column(Float)
    group_size = Column(Integer)
    gross_value = Column(Float)
    platform_commission_pct = Column(Float, default=0.15)  # commission rate at time of booking
    insurance_pct = Column(Float, default=0.05)  # 5% insurance fee
    status = Column(String)  # REQUESTED | CONFIRMED | PAID | IN_PROGRESS | COMPLETED | CANCELLED
    payment_status = Column(String)  # held_escrow | released | refunded
    created_at = Column(DateTime, default=datetime.utcnow)


class Rating(Base):
    __tablename__ = "ratings"

    id = Column(Integer, primary_key=True, autoincrement=True)
    tourist_id = Column(String, ForeignKey("tourists.id"))
    guide_id = Column(String, ForeignKey("guides.id"))
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    rating = Column(Float)
    is_poor_experience = Column(Boolean)
    norm_dot_product = Column(Float)
    language_match = Column(Float)
    budget_alignment = Column(Float)
    pace_alignment = Column(Float)
    predicted_rating = Column(Float)
    rating_source = Column(String)  # synthetic
    created_at = Column(DateTime, default=datetime.utcnow)


class Itinerary(Base):
    __tablename__ = "itineraries"

    id = Column(Integer, primary_key=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), unique=True)
    stops = Column(JSON)  # [{"name": "...", "order": 1, "duration_hours": 1.5}]
    status = Column(String)  # proposed | approved | in_progress | completed
    created_at = Column(DateTime, default=datetime.utcnow)


class TripPlan(Base):
    __tablename__ = "trip_plans"

    id = Column(Integer, primary_key=True, autoincrement=True)
    tourist_id = Column(String, ForeignKey("tourists.id"))
    destination = Column(String)
    interests = Column(String)  # pipe-delimited e.g. "food|culture|adventure"
    proposed_stops = Column(JSON)  # [{"name": "...", "duration_hours": 1.5, "notes": "..."}]
    status = Column(String)  # OPEN | GUIDE_PROPOSED | TOURIST_REVIEWING | ACCEPTED | REJECTED | COMPLETED | CANCELLED
    guide_id = Column(String, ForeignKey("guides.id"), nullable=True)
    tour_date = Column(String, nullable=True)
    duration_hours = Column(Float, nullable=True)
    group_size = Column(Integer, nullable=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True)
    negotiation_rounds = Column(Integer, default=0)  # increments on each counteroffer; cap at 2
    alternatives = Column(JSON, nullable=True)  # [{"rejected_stop": "...", "alternatives": ["Alt1", "Alt2"]}]
    guide_proposed_stops = Column(JSON, nullable=True)  # guide's counter-proposed stops
    created_at = Column(DateTime, default=datetime.utcnow)


class Wallet(Base):
    """One wallet per user — Tourist, Guide, or BusinessOwner."""
    __tablename__ = "wallets"

    id = Column(String, primary_key=True)
    owner_id = Column(String, nullable=False)  # tourist_id / guide_id / business_owner_id
    owner_type = Column(String, nullable=False)  # "tourist" | "guide" | "business"
    balance = Column(Float, default=0.0)
    currency = Column(String, default="THB")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class WalletTransaction(Base):
    """Immutable transaction ledger for wallet deposits, payments, and payouts."""
    __tablename__ = "wallet_transactions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    wallet_id = Column(String, ForeignKey("wallets.id"), nullable=False)
    txn_type = Column(String, nullable=False)  # deposit | payment | payout | refund | commission
    amount = Column(Float, nullable=False)  # positive = credit, negative = debit
    currency = Column(String, default="THB")
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class LocationTracking(Base):
    """Real-time GPS location for guide and tourist during active tour."""
    __tablename__ = "location_tracking"

    id = Column(Integer, primary_key=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), unique=True)
    guide_lat = Column(Float, nullable=True)
    guide_lng = Column(Float, nullable=True)
    tourist_lat = Column(Float, nullable=True)
    tourist_lng = Column(Float, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class MatchBid(Base):
    """Tinder-style mutual acceptance bid. Created when guide or tourist expresses interest."""
    __tablename__ = "match_bids"

    id = Column(Integer, primary_key=True, autoincrement=True)
    # The bidder (guide or tourist)
    bidder_id = Column(String, nullable=False)  # guide_id or tourist_id
    bidder_type = Column(String, nullable=False)  # "guide" | "tourist"
    # The target of the bid (who the bidder is interested in)
    target_id = Column(String, nullable=False)  # guide_id or tourist_id
    target_type = Column(String, nullable=False)  # "guide" | "tourist"
    # Trip plan context (optional — when bidding on a specific plan)
    trip_plan_id = Column(Integer, ForeignKey("trip_plans.id"), nullable=True)
    # Proposed stops at time of bid (captured for the other party to review)
    proposed_stops = Column(JSON, nullable=True)
    status = Column(String, default="PENDING")  # PENDING | MATCHED | REJECTED | EXPIRED
    created_at = Column(DateTime, default=datetime.utcnow)


class Checkpoint(Base):
    """GPS + photo checkpoint during an active tour. Souvenir montage assembled from all checkpoints."""
    __tablename__ = "checkpoints"

    id = Column(Integer, primary_key=True, autoincrement=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    stop_name = Column(String, nullable=False)
    # GPS where photo was taken
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    # URL to the photo taken at this checkpoint
    photo_url = Column(String, nullable=True)  # stored externally (Cloudinary/S3 URL)
    # Souvenir caption/tag from tourist
    caption = Column(String, nullable=True)
    sequence_order = Column(Integer, nullable=False)  # order in the montage
    created_at = Column(DateTime, default=datetime.utcnow)


class RejectionLog(Base):
    """
    Tracks rejection signals for the ML feedback loop.
    Records when guides reject trip plans or tourists auto-reject due to round cap.
    Used to improve future guide-tourist matching.
    """
    __tablename__ = "rejection_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    trip_plan_id = Column(Integer, ForeignKey("trip_plans.id"), nullable=False)
    guide_id = Column(String, ForeignKey("guides.id"), nullable=True)  # null when guide not yet assigned
    tourist_id = Column(String, ForeignKey("tourists.id"), nullable=False)
    rejection_reason = Column(String, nullable=True)  # "round_cap_reached" | "guide_declined" | "tourist_declined" | "unavailable_stop"
    rejected_stops = Column(JSON, nullable=True)  # list of stop names that were rejected
    alternatives_offered = Column(JSON, nullable=True)  # list of alternative stops offered
    created_at = Column(DateTime, default=datetime.utcnow)

