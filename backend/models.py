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
    status = Column(String)  # OPEN | ACCEPTED | COMPLETED | CANCELLED
    guide_id = Column(String, ForeignKey("guides.id"), nullable=True)
    tour_date = Column(String, nullable=True)
    duration_hours = Column(Float, nullable=True)
    group_size = Column(Integer, nullable=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True)
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
