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


def seed_sea_guides(db: SessionLocal):
    """Seed ~20 guides across Singapore and SEA countries with realistic names."""
    sea_guides = [
        # Singapore
        {"name": "Wei Ling Tan", "country": "Singapore", "city": "Singapore", "specialty": "City Tours", "language": "en→en", "bio": "Passionate Singaporean guide specializing in cultural heritage walks through Chinatown, Little India, and Kampong Glam."},
        {"name": "Jun Hao Lim", "country": "Singapore", "city": "Singapore", "specialty": "Food Tours", "language": "en→en,zh→en", "bio": "Foodie and storyteller — let me take you through the best hawker centres and Michelin-starred street food."},
        {"name": "Aisha Mohamed", "country": "Singapore", "city": "Singapore", "specialty": "Heritage Sites", "language": "en→en,ms→en", "bio": "Historic Singapore specialist — from colonial architecture to modern gardens and everything in between."},
        # Thailand
        {"name": "Manee Prasert", "country": "Thailand", "city": "Chiang Mai", "specialty": "Temples & Culture", "language": "en→th", "bio": "Born and raised in Chiang Mai — I show visitors the real Northern Thailand, from mountain tribes to hidden waterfalls."},
        {"name": "Siriwan Boom", "country": "Thailand", "city": "Bangkok", "specialty": "Nightlife & Markets", "language": "en→th", "bio": "Bangkok insider — floating markets before dawn, rooftop bars at sunset, and the best pad thai you've ever tasted."},
        {"name": "Krit Kong", "country": "Thailand", "city": "Phuket", "specialty": "Island Hopping", "language": "en→th", "bio": "Island life expert — private boat tours, hidden beaches, and snorkeling spots only locals know about."},
        {"name": "Nakorn Sri", "country": "Thailand", "city": "Ayutthaya", "specialty": "Ancient Ruins", "language": "en→th", "bio": "History buff specializing in the ancient Siam capital — temples, Buddha statues, and riverfront sunsets."},
        # Vietnam
        {"name": "Thi Mai Nguyen", "country": "Vietnam", "city": "Hanoi", "specialty": "Street Food", "language": "en→vi", "bio": "Hanoi native and food lover — join me for a cyclo ride through the Old Quarter's best banh mi and pho spots."},
        {"name": "Minh Tran", "country": "Vietnam", "city": "Ho Chi Minh", "specialty": "War History", "language": "en→vi", "bio": "Historian and guide — I bring Vietnam's modern history alive through its tunnels, museums, and street life."},
        {"name": "Lan Huynh", "country": "Vietnam", "city": "Hoi An", "specialty": "Tailoring & Culture", "language": "en→vi", "bio": "Hoi An's golden age comes alive — lantern-lit streets, custom tailoring, and the region's best cao lầu."},
        {"name": "Son Nguyen", "country": "Vietnam", "city": "Da Nang", "specialty": "Beach & Mountains", "language": "en→vi", "bio": "Da Nang native — from Marble Mountain temples to the world's most scenic Hai Van Pass drives."},
        # Malaysia
        {"name": "Rashid Hassan", "country": "Malaysia", "city": "Kuala Lumpur", "specialty": "Cultural Diversity", "language": "en→ms,en→zh", "bio": "KL is three cities in one — Malay, Chinese, Indian. I'll show you all the layers from Petronas to Penang Laksa."},
        {"name": "Siew Mei Chew", "country": "Malaysia", "city": "George Town", "specialty": "Colonial Heritage", "language": "en→zh,en→ms", "bio": "Penang specialist — UNESCO George Town's street art, colonial mansions, and the best Assam Laksa in Malaysia."},
        {"name": "Zulkifli Omar", "country": "Malaysia", "city": "Kuching", "specialty": "Wildlife & Nature", "language": "en→ms", "bio": "Borneo guide — orangutan sanctuaries, cave systems, and the wildlife of Sarawak's rainforests."},
        # Indonesia
        {"name": "Ayu Dewi", "country": "Indonesia", "city": "Ubud", "specialty": "Arts & Temples", "language": "en→id", "bio": "Balinese artist and guide — temple ceremonies, rice terrace walks, and traditional dance performances in Ubud."},
        {"name": "Made Suryani", "country": "Indonesia", "city": "Seminyak", "specialty": "Beach Life", "language": "en→id", "bio": "Surf instructor turned guide — Bali's best beaches, beach clubs, and hidden coves away from the crowds."},
        {"name": "Komang Sari", "country": "Indonesia", "city": "Yogyakarta", "specialty": "Ancient Java", "language": "en→id", "bio": "Javanese culture specialist — Borobudur at sunrise, Prambanan at dusk, and traditional batik workshops."},
        # Philippines
        {"name": "Maria Santos", "country": "Philippines", "city": "Cebu", "specialty": "Island Hopping", "language": "en→fil,en→tl", "bio": "Cebuano guide — whale shark encounters, white sand islands, and the best lechon you've ever tasted."},
        {"name": "Jay Arcilla", "country": "Philippines", "city": "Palawan", "specialty": "Underground River", "language": "en→fil", "bio": "Palawan native — the Puerto Princesa underground river, Kayangan Lake, and El Nido's hidden lagoons."},
        # Myanmar
        {"name": "Khin Thida", "country": "Myanmar", "city": "Yangon", "specialty": "Buddhist Heritage", "language": "en→my", "bio": "Shwedagon Paya caretaker turned guide — ancient pagodas, colonial Yangon, and the warmth of Burmese hospitality."},
        # Laos
        {"name": "Bounmy Phommasak", "country": "Laos", "city": "Luang Prabang", "specialty": "Temple & River Life", "language": "en→lo", "bio": "Luang Prabang local — alms giving ceremonies, Kuang Si waterfalls, and the peaceful banks of the Mekong."},
        # Cambodia
        {"name": "Sokha Chan", "country": "Cambodia", "city": "Siem Reap", "specialty": "Angkor Wat", "language": "en→km", "bio": "Angkor specialist — I've guided at the temples for 12 years. Sunrise at Angkor Wat is just the beginning."},
        # Brunei
        {"name": "Haji Abdullah", "country": "Brunei", "city": "Bandar Seri Begawan", "specialty": "Royal Heritage", "language": "en→ms", "bio": "Bruneian guide — the Empire Hotel, Kampong Ayer water village, and the opulence of the Sultan's palace."},
    ]

    count = 0
    for g in sea_guides:
        existing = db.query(Guide).filter_by(email=f"guide_{g['country'].lower().replace(' ', '')}@wanderless.com").first()
        if existing:
            print(f"  SEA Guide already exists: {existing.id} — {g['name']}")
            continue
        guide = Guide(
            id=f"G{uuid.uuid4().hex[:8].upper()}",
            email=f"guide_{g['country'].lower().replace(' ', '')}@wanderless.com",
            password_hash=TEST_PASSWORD_HASH,
            name=g["name"],
            bio=g["bio"],
            photo_url=f"https://picsum.photos/seed/{g['name'].lower().replace(' ', '_')}/400/400",
            license_verified=True,
            specialties=g["specialty"],
            language_pairs=g["language"],
            location_coverage=g["city"],
            owner_id=None,  # independent guides
        )
        db.add(guide)
        count += 1

    db.commit()
    print(f"  Seeded {count} SEA guides across {len(sea_guides)} countries")


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

    # Seed SEA guides
    seed_sea_guides(db)

    db.close()
    print("Done.")


if __name__ == "__main__":
    main()

