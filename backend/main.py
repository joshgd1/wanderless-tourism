"""
FastAPI application — WanderLess backend.
Full auth: JWT-based tourist authentication + guide auth.
"""

import logging
import time
import uuid
from datetime import datetime, timedelta
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database import init_db, get_db, compute_dot_range
from matching import compatibility_score, top_matches
from ml import fit_recommender
import models  # noqa: F401 — models registered with Base.metadata

logger = logging.getLogger("wanderless")
logging.basicConfig(level=logging.INFO)

# Auth configuration — change SECRET_KEY in production
SECRET_KEY = "wanderless-dev-secret-change-in-production-min-32-chars"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 24

# In-memory rate limiter (per-IP)
_rate_limit_store: dict[str, list[float]] = {}
RATE_LIMIT_REQUESTS = 100
RATE_LIMIT_WINDOW_SECONDS = 60.0


def _check_rate_limit(client_ip: str) -> None:
    """Block if client exceeds RATE_LIMIT_REQUESTS in RATE_LIMIT_WINDOW_SECONDS."""
    now = time.time()
    window = _rate_limit_store.get(client_ip, [])
    window = [t for t in window if now - t < RATE_LIMIT_WINDOW_SECONDS]
    if len(window) >= RATE_LIMIT_REQUESTS:
        raise HTTPException(status_code=429, detail="Rate limit exceeded")
    window.append(now)
    _rate_limit_store[client_ip] = window


# ─── JWT helpers ─────────────────────────────────────────────────────────────────

def _create_token(tourist_id: str, expires_delta: timedelta | None = None) -> str:
    from jose import jwt
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS))
    payload = {"sub": tourist_id, "exp": expire, "iat": datetime.utcnow()}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def _verify_token(token: str) -> str | None:
    from jose import jwt, JWTError
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None


# ─── Auth dependency ─────────────────────────────────────────────────────────────

def _get_tourist_id(authorization: str | None = Header(None)) -> str:
    """Verify JWT and return tourist_id. Raises 401 if invalid."""
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Invalid authorization header format")
    tourist_id = _verify_token(parts[1])
    if not tourist_id:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return tourist_id


def _get_tourist_id_optional(authorization: str | None = Header(None)) -> str | None:
    """Verify JWT and return tourist_id. Returns None if no valid auth header."""
    if not authorization:
        return None
    try:
        parts = authorization.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return None
        tourist_id = _verify_token(parts[1])
        return tourist_id or None
    except Exception:
        return None


def _get_guide_id(authorization: str | None = Header(None)) -> str:
    """Verify JWT and return guide_id. Raises 401 if invalid."""
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Invalid authorization header format")
    guide_id = _verify_token(parts[1])
    if not guide_id:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return guide_id


def _get_guide_id_optional(authorization: str | None = Header(None)) -> str | None:
    """Verify JWT and return guide_id. Returns None if no valid auth header."""
    if not authorization:
        return None
    try:
        parts = authorization.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return None
        guide_id = _verify_token(parts[1])
        return guide_id or None
    except Exception:
        return None


# ─── Database helpers ────────────────────────────────────────────────────────────

def _hash_password(password: str) -> str:
    from passlib.context import CryptContext
    return CryptContext(schemes=["bcrypt"], deprecated="auto").hash(password)


def _verify_password(password: str, hashed: str) -> bool:
    from passlib.context import CryptContext
    return CryptContext(schemes=["bcrypt"], deprecated="auto").verify(password, hashed)


# ─── Lifespan ───────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: seed DB from CSV
    db = next(get_db())
    init_db(db)

    # Fit ML recommender on seeded data
    tourists = db.query(models.Tourist).all()
    guides = db.query(models.Guide).all()
    ratings = db.query(models.Rating).all()
    fit_recommender(tourists, guides, ratings)

    db.close()
    logger.info("wanderless.startup database_seeded ml_recommender_fitted")
    yield
    logger.info("wanderless.shutdown server_shutdown")


app = FastAPI(title="WanderLess API", version="0.2.0", lifespan=lifespan)

# CORS — explicit origins only (no wildcard in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://10.0.2.2:8080",  # Android emulator to host
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def _rate_limit_middleware(request: Request, call_next):
    client_ip = request.client.host if request.client else "unknown"
    try:
        _check_rate_limit(client_ip)
    except HTTPException:
        return
    return await call_next(request)


@app.get("/api/health")
async def health():
    return {"status": "ok"}


# ─── Auth endpoints ─────────────────────────────────────────────────────────────

@app.post("/api/auth/register")
async def register(data: dict, db: Session = Depends(get_db)):
    """
    Register a new tourist account.
    Returns JWT token for immediate login.
    """
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    name = data.get("name", "").strip()

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required")
    if not password or len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not name:
        raise HTTPException(status_code=400, detail="Name is required")

    # Check if email already exists
    existing = db.query(models.Tourist).filter_by(email=email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    tourist_id = f"T{uuid.uuid4().hex[:8].upper()}"
    tourist = models.Tourist(
        id=tourist_id,
        email=email,
        password_hash=_hash_password(password),
        name=name,
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
    logger.info(f"auth.register tourist_id={tourist_id} email={email}")

    token = _create_token(tourist_id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "tourist_id": tourist_id,
        "name": name,
    }


@app.post("/api/auth/login")
async def login(data: dict, db: Session = Depends(get_db)):
    """
    Authenticate with email + password.
    Returns JWT token.
    """
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password are required")

    tourist = db.query(models.Tourist).filter_by(email=email).first()
    if not tourist or not tourist.password_hash:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not _verify_password(password, tourist.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = _create_token(tourist.id)
    logger.info(f"auth.login tourist_id={tourist.id} email={email}")
    return {
        "access_token": token,
        "token_type": "bearer",
        "tourist_id": tourist.id,
        "name": tourist.name or "Tourist",
    }


@app.get("/api/auth/me")
async def get_me(tourist_id: str = Depends(_get_tourist_id), db: Session = Depends(get_db)):
    """Get current authenticated tourist's profile."""
    t = db.query(models.Tourist).filter_by(id=tourist_id).first()
    if not t:
        raise HTTPException(status_code=404, detail="Tourist not found")
    return {
        "id": t.id,
        "email": t.email,
        "name": t.name,
        "food_interest": t.food_interest,
        "culture_interest": t.culture_interest,
        "adventure_interest": t.adventure_interest,
        "pace_preference": t.pace_preference,
        "budget_level": t.budget_level,
        "language": t.language,
        "age_group": t.age_group,
        "travel_style": t.travel_style,
        "experience_type": t.experience_type,
    }


# ─── Tourist endpoints ───────────────────────────────────────────────────────────

@app.get("/api/tourists/{tid}")
async def get_tourist(tid: str, db: Session = Depends(get_db)):
    t = db.query(models.Tourist).filter_by(id=tid).first()
    if not t:
        raise HTTPException(status_code=404, detail="Tourist not found")
    return {
        "id": t.id,
        "email": t.email,
        "name": t.name,
        "food_interest": t.food_interest,
        "culture_interest": t.culture_interest,
        "adventure_interest": t.adventure_interest,
        "pace_preference": t.pace_preference,
        "budget_level": t.budget_level,
        "language": t.language,
        "age_group": t.age_group,
        "travel_style": t.travel_style,
        "experience_type": t.experience_type,
    }


@app.post("/api/tourists")
async def create_tourist(data: dict, db: Session = Depends(get_db)):
    """
    Create a tourist profile (from onboarding).
    Requires valid JWT auth — onboarding is only for registered users who
    complete the preference flow AFTER registration.
    """
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
        experience_type=data.get("experience_type", "authentic_local"),
        energy_curve="|".join(["0.5"] * 24),
    )
    db.add(t)
    db.commit()
    db.refresh(t)
    return {"id": t.id}


@app.put("/api/tourists/{tid}/preferences")
async def update_preferences(
    tid: str,
    data: dict,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """Update tourist preferences. Requires auth; can only update own profile."""
    if tid != tourist_id:
        raise HTTPException(status_code=403, detail="Cannot update another tourist's profile")
    t = db.query(models.Tourist).filter_by(id=tid).first()
    if not t:
        raise HTTPException(status_code=404, detail="Tourist not found")

    for field in ["food_interest", "culture_interest", "adventure_interest",
                  "pace_preference", "budget_level", "language", "age_group",
                  "travel_style", "experience_type"]:
        if field in data:
            setattr(t, field, data[field])
    db.commit()
    logger.info(f"tourist.preferences_updated tourist_id={tid}")
    return {"id": t.id, "status": "updated"}


# ─── Guide endpoints ─────────────────────────────────────────────────────────────

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
            "license_verified": g.license_verified,
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
        "license_verified": g.license_verified,
    }


# ─── Guide auth endpoints ────────────────────────────────────────────────────────

@app.post("/api/guides/register")
async def register_guide(data: dict, db: Session = Depends(get_db)):
    """
    Register a new guide account.
    Returns JWT token for immediate login.
    """
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    guide_id = data.get("guide_id", "").strip()

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required")
    if not password or len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not guide_id:
        raise HTTPException(status_code=400, detail="guide_id is required")

    existing_email = db.query(models.Guide).filter_by(email=email).first()
    if existing_email:
        raise HTTPException(status_code=409, detail="Email already registered")

    guide = db.query(models.Guide).filter_by(id=guide_id).first()
    if not guide:
        raise HTTPException(status_code=404, detail="Guide not found in system")
    if guide.email:
        raise HTTPException(status_code=409, detail="Guide already has an account")

    guide.email = email
    guide.password_hash = _hash_password(password)
    db.commit()
    logger.info(f"guide.register guide_id={guide_id} email={email}")

    token = _create_token(guide_id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "guide_id": guide_id,
        "name": guide.name,
    }


@app.post("/api/guides/login")
async def guide_login(data: dict, db: Session = Depends(get_db)):
    """
    Authenticate guide with email + password.
    Returns JWT token.
    """
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password are required")

    guide = db.query(models.Guide).filter_by(email=email).first()
    if not guide or not guide.password_hash:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not _verify_password(password, guide.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = _create_token(guide.id)
    logger.info(f"guide.login guide_id={guide.id} email={email}")
    return {
        "access_token": token,
        "token_type": "bearer",
        "guide_id": guide.id,
        "name": guide.name,
    }


@app.get("/api/guides/auth/me")
async def get_guide_me(guide_id: str = Depends(_get_guide_id), db: Session = Depends(get_db)):
    """Get current authenticated guide's profile."""
    g = db.query(models.Guide).filter_by(id=guide_id).first()
    if not g:
        raise HTTPException(status_code=404, detail="Guide not found")
    return {
        "id": g.id,
        "email": g.email,
        "name": g.name,
        "bio": g.bio,
        "photo_url": g.photo_url,
        "expertise_tags": g.expertise_tags.split("|") if g.expertise_tags else [],
        "language_pairs": g.language_pairs.split("|") if g.language_pairs else [],
        "pace_style": g.pace_style,
        "group_size_preferred": g.group_size_preferred,
        "budget_tier": g.budget_tier,
        "location_coverage": g.location_coverage.split("|") if g.location_coverage else [],
        "rating_history": g.rating_history,
        "rating_count": g.rating_count,
        "specialties": g.specialties.split("|") if g.specialties else [],
        "license_verified": g.license_verified,
        "owner_id": g.owner_id,
    }


# ─── Business Owner auth endpoints ─────────────────────────────────────────────

def _get_business_owner_id(authorization: str | None = Header(None)) -> str:
    """Verify JWT and return business_owner_id. Raises 401 if invalid."""
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Invalid authorization header format")
    owner_id = _verify_token(parts[1])
    if not owner_id:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return owner_id


@app.post("/api/business/register")
async def register_business(data: dict, db: Session = Depends(get_db)):
    """
    Register a new business owner account.
    Returns JWT token for immediate login.
    """
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    business_name = data.get("business_name", "").strip()

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required")
    if not password or len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not business_name:
        raise HTTPException(status_code=400, detail="Business name is required")

    existing = db.query(models.BusinessOwner).filter_by(email=email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    owner_id = f"B{uuid.uuid4().hex[:8].upper()}"
    owner = models.BusinessOwner(
        id=owner_id,
        email=email,
        password_hash=_hash_password(password),
        business_name=business_name,
        phone=data.get("phone"),
        commission_rate=0.15,
    )
    db.add(owner)
    db.commit()
    logger.info(f"business.register owner_id={owner_id} email={email}")

    token = _create_token(owner_id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "business_owner_id": owner_id,
        "business_name": business_name,
    }


@app.post("/api/business/login")
async def business_login(data: dict, db: Session = Depends(get_db)):
    """
    Authenticate business owner with email + password.
    Returns JWT token.
    """
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password are required")

    owner = db.query(models.BusinessOwner).filter_by(email=email).first()
    if not owner or not owner.password_hash:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not _verify_password(password, owner.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = _create_token(owner.id)
    logger.info(f"business.login owner_id={owner.id} email={email}")
    return {
        "access_token": token,
        "token_type": "bearer",
        "business_owner_id": owner.id,
        "business_name": owner.business_name,
    }


@app.get("/api/business/me")
async def get_business_me(
    owner_id: str = Depends(_get_business_owner_id),
    db: Session = Depends(get_db),
):
    """Get current authenticated business owner's profile."""
    o = db.query(models.BusinessOwner).filter_by(id=owner_id).first()
    if not o:
        raise HTTPException(status_code=404, detail="Business owner not found")
    return {
        "id": o.id,
        "email": o.email,
        "business_name": o.business_name,
        "commission_rate": o.commission_rate,
        "phone": o.phone,
    }


@app.get("/api/business/dashboard")
async def get_business_dashboard(
    owner_id: str = Depends(_get_business_owner_id),
    db: Session = Depends(get_db),
):
    """
    Dashboard for business owner — bookings, revenue, guide performance.
    """
    # Get all guides owned by this business
    owned_guides = db.query(models.Guide).filter_by(owner_id=owner_id).all()
    owned_guide_ids = [g.id for g in owned_guides]

    if not owned_guide_ids:
        return {
            "business_owner_id": owner_id,
            "total_bookings": 0,
            "total_revenue": 0.0,
            "total_commission": 0.0,
            "guides": [],
            "recent_bookings": [],
        }

    # All bookings for owned guides
    bookings = (
        db.query(models.Booking)
        .filter(models.Booking.guide_id.in_(owned_guide_ids))
        .order_by(models.Booking.created_at.desc())
        .all()
    )

    total_revenue = sum(b.gross_value for b in bookings)
    total_commission = sum(
        b.gross_value * b.platform_commission_pct for b in bookings
    )

    # Per-guide breakdown
    guide_stats = {}
    for gid in owned_guide_ids:
        guide_stats[gid] = {"guide_id": gid, "bookings": 0, "revenue": 0.0, "guide_name": ""}

    guide_map = {g.id: g for g in owned_guides}
    for b in bookings:
        if b.guide_id in guide_stats:
            guide_stats[b.guide_id]["bookings"] += 1
            guide_stats[b.guide_id]["revenue"] += b.gross_value
            guide_stats[b.guide_id]["guide_name"] = guide_map[b.guide_id].name

    # Recent bookings (last 10)
    recent = bookings[:10]
    recent_serialized = []
    for b in recent:
        guide = guide_map.get(b.guide_id)
        tourist = db.query(models.Tourist).filter_by(id=b.tourist_id).first()
        recent_serialized.append({
            "id": b.id,
            "guide_id": b.guide_id,
            "guide_name": guide.name if guide else "?",
            "tourist_name": tourist.name if tourist else "?",
            "destination": b.destination,
            "tour_date": b.tour_date,
            "gross_value": b.gross_value,
            "status": b.status,
            "payment_status": b.payment_status,
            "created_at": b.created_at.isoformat() if b.created_at else None,
        })

    logger.info(
        f"business.dashboard owner_id={owner_id} "
        f"bookings={len(bookings)} revenue={total_revenue:.2f}"
    )
    return {
        "business_owner_id": owner_id,
        "total_bookings": len(bookings),
        "total_revenue": round(total_revenue, 2),
        "total_commission": round(total_commission, 2),
        "guides": list(guide_stats.values()),
        "recent_bookings": recent_serialized,
    }


@app.get("/api/business/guides")
async def get_business_guides(
    owner_id: str = Depends(_get_business_owner_id),
    db: Session = Depends(get_db),
):
    """List all guides owned by this business owner."""
    guides = db.query(models.Guide).filter_by(owner_id=owner_id).all()
    return [
        {
            "id": g.id,
            "name": g.name,
            "email": g.email,
            "photo_url": g.photo_url,
            "rating_history": g.rating_history,
            "rating_count": g.rating_count,
            "license_verified": g.license_verified,
        }
        for g in guides
    ]


# ─── Matching ────────────────────────────────────────────────────────────────────

@app.get("/api/matches/{tid}")
async def get_matches(
    tid: str,
    top_n: int = 5,
    destination: str | None = None,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """
    Get top-N matched guides for a tourist.
    Requires JWT auth — only the authenticated tourist can get their matches.
    """
    t0 = time.monotonic()
    logger.info(f"matches.start tourist_id={tourist_id} top_n={top_n} destination={destination}")

    # Verify the requesting tourist matches the URL param
    if tid != tourist_id:
        raise HTTPException(status_code=403, detail="Cannot access another tourist's matches")

    tourist = db.query(models.Tourist).filter_by(id=tid).first()
    if not tourist:
        raise HTTPException(status_code=404, detail="Tourist not found")

    guides = db.query(models.Guide).all()
    dot_range = compute_dot_range(db)
    scored = top_matches(tourist, guides, dot_range, top_n, destination)

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
            "language_pairs": g.language_pairs.split("|"),
            "location_coverage": g.location_coverage.split("|"),
            "rating_history": g.rating_history,
            "rating_count": g.rating_count,
            "budget_tier": g.budget_tier,
            "license_verified": g.license_verified,
            "score": item["score"],
            "lang_match": item["lang_match"],
        })

    logger.info(f"matches.ok tourist_id={tourist_id} count={len(results)} latency_ms={(time.monotonic() - t0) * 1000:.1f}")
    return results


# ─── ML Recommendations ────────────────────────────────────────────────────────

from ml import get_recommender


@app.get("/api/recommendations/{tourist_id}/guides")
async def get_ml_guide_recommendations(
    tourist_id: str,
    destination: str | None = None,
    top_n: int = 5,
    auth_tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """
    ML-powered guide recommendations combining content-based + collaborative filtering.

    Returns top-N guides ranked by hybrid score with per-score breakdown:
      - score: overall hybrid score (0–1)
      - score_content: content-based similarity (0–1)
      - score_collab: collaborative-filter rating prediction (0–1)
      - score_dest: destination affinity bonus (0–1)
    Requires JWT auth — tourist can only get their own recommendations.
    """
    if tourist_id != auth_tourist_id:
        raise HTTPException(status_code=403, detail="Cannot access another tourist's recommendations")

    tourist = db.query(models.Tourist).filter_by(id=tourist_id).first()
    if not tourist:
        raise HTTPException(status_code=404, detail="Tourist not found")

    recommender = get_recommender()
    scored = recommender.recommend_guides(tourist_id, destination=destination, top_n=top_n)

    guide_map = {g.id: g for g in db.query(models.Guide).all()}
    results = []
    for item in scored:
        gid = item["guide_id"]
        g = guide_map.get(gid)
        if not g:
            continue
        results.append({
            "guide_id": gid,
            "name": g.name,
            "photo_url": g.photo_url,
            "bio": g.bio,
            "expertise_tags": g.expertise_tags.split("|"),
            "location_coverage": g.location_coverage.split("|"),
            "rating_history": g.rating_history,
            "rating_count": g.rating_count,
            "budget_tier": g.budget_tier,
            "license_verified": g.license_verified,
            "score": item["score"],
            "score_content": item["score_content"],
            "score_collab": item["score_collab"],
            "score_dest": item["score_dest"],
            "ml_explanation": (
                f"Content match={item['score_content']:.0%}, "
                f"Collaborative={item['score_collab']:.0%}, "
                f"Overall={item['score']:.0%}"
            ),
        })

    logger.info(f"ml_guide_recommendations.ok tourist_id={tourist_id} count={len(results)}")
    return results


@app.get("/api/recommendations/{tourist_id}/destinations")
async def get_ml_destination_recommendations(
    tourist_id: str,
    auth_tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """
    ML-powered destination recommendations for a tourist.

    Returns all destinations ranked by content-based similarity to tourist's
    preference profile, with ML-generated explanation per destination.
    Requires JWT auth.
    """
    if tourist_id != auth_tourist_id:
        raise HTTPException(status_code=403, detail="Cannot access another tourist's recommendations")

    tourist = db.query(models.Tourist).filter_by(id=tourist_id).first()
    if not tourist:
        raise HTTPException(status_code=404, detail="Tourist not found")

    recommender = get_recommender()
    results = recommender.recommend_destinations(tourist_id)

    logger.info(f"ml_dest_recommendations.ok tourist_id={tourist_id} count={len(results)}")
    return results


# Price lookup by budget tier (server-side, not client-controlled)
_TIER_HOURLY_RATE = {"budget": 250.0, "mid": 500.0, "premium": 1000.0}


# ─── Booking endpoints ───────────────────────────────────────────────────────────

@app.post("/api/bookings")
async def create_booking(
    data: dict,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """
    Create a booking. Requires JWT auth; tourist_id comes from token.
    """
    guide_id = data.get("guide_id")
    if not guide_id:
        raise HTTPException(status_code=400, detail="guide_id is required")
    if not data.get("tour_date"):
        raise HTTPException(status_code=400, detail="tour_date is required")

    guide = db.query(models.Guide).filter_by(id=guide_id).first()
    if not guide:
        raise HTTPException(status_code=404, detail="Guide not found")

    duration = data.get("duration_hours", 4.0)
    group_size = data.get("group_size", 1)
    if duration <= 0:
        raise HTTPException(status_code=400, detail="duration_hours must be positive")
    if group_size <= 0:
        raise HTTPException(status_code=400, detail="group_size must be positive")

    hourly_rate = _TIER_HOURLY_RATE.get(guide.budget_tier, 500.0)
    gross_value = hourly_rate * duration

    # Capture commission rate from guide's owner at booking time
    commission_rate = 0.15
    if guide.owner_id:
        owner = db.query(models.BusinessOwner).filter_by(id=guide.owner_id).first()
        if owner:
            commission_rate = owner.commission_rate or 0.15

    b = models.Booking(
        tourist_id=tourist_id,
        guide_id=guide_id,
        destination=data.get("destination", "Chiang Mai"),
        tour_date=data["tour_date"],
        duration_hours=duration,
        group_size=group_size,
        gross_value=gross_value,
        platform_commission_pct=commission_rate,
        status="REQUESTED",
        payment_status="held_escrow",
    )
    db.add(b)
    db.commit()
    db.refresh(b)

    # SAFETY: Link this booking to any ACCEPTED TripPlan for this tourist+guide
    # This enables coordinated cancellation (cancel plan → cancel booking)
    trip_plan = db.query(models.TripPlan).filter(
        models.TripPlan.tourist_id == tourist_id,
        models.TripPlan.guide_id == guide_id,
        models.TripPlan.status == "ACCEPTED",
    ).first()
    if trip_plan:
        trip_plan.booking_id = b.id
        db.commit()
        logger.info(f"booking.linked_to_trip_plan booking_id={b.id} plan_id={trip_plan.id}")

    logger.info(f"booking.created booking_id={b.id} tourist_id={b.tourist_id} guide_id={b.guide_id} gross_value={gross_value}")
    return {"id": b.id, "status": b.status, "gross_value": gross_value}


@app.get("/api/bookings/{booking_id}")
async def get_booking(
    booking_id: int,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """Get booking. Requires JWT; tourist can only access own bookings."""
    b = db.query(models.Booking).filter_by(id=booking_id).first()
    if not b:
        raise HTTPException(status_code=404, detail="Booking not found")
    if b.tourist_id != tourist_id:
        raise HTTPException(status_code=403, detail="Not your booking")
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


@app.get("/api/bookings")
async def list_bookings(
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """List all bookings for the authenticated tourist."""
    bookings = db.query(models.Booking).filter_by(tourist_id=tourist_id).order_by(models.Booking.created_at.desc()).all()
    return [
        {
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
        for b in bookings
    ]


@app.put("/api/bookings/{booking_id}/status")
async def update_booking_status(
    booking_id: int,
    data: dict | None = None,
    tourist_id: str | None = Depends(_get_tourist_id_optional),
    guide_id: str | None = Depends(_get_guide_id_optional),
    db: Session = Depends(get_db),
):
    """Update booking status. Requires JWT; tourist or guide can update their bookings.

    - Tourist: can cancel own bookings (auto-refund from escrow)
    - Guide: can confirm (REQUESTED→CONFIRMED) or cancel own bookings
    - Cancellation reason stored for dispute resolution
    - Guide cancellation triggers penalty tracking
    """
    if data is None:
        data = {}
    b = db.query(models.Booking).filter_by(id=booking_id).first()
    if not b:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Authorization: tourist owns tourist_id, guide owns guide_id
    is_tourist = tourist_id is not None and b.tourist_id == tourist_id
    is_guide = guide_id is not None and b.guide_id == guide_id
    if not is_tourist and not is_guide:
        raise HTTPException(status_code=403, detail="Not your booking")

    valid_transitions = {
        "REQUESTED": ["CONFIRMED", "CANCELLED"],
        "CONFIRMED": ["PAID", "CANCELLED"],
        "PAID": ["IN_PROGRESS", "CANCELLED"],
        "IN_PROGRESS": ["COMPLETED"],
        "COMPLETED": [],
        "CANCELLED": [],
    }
    new_status = data.get("status")
    cancelled_by = data.get("cancelled_by")  # 'tourist' or 'guide'

    if new_status:
        allowed = valid_transitions.get(b.status, [])
        if new_status not in allowed:
            raise HTTPException(status_code=400, detail=f"Cannot transition from {b.status} to {new_status}")

        if new_status == "CANCELLED":
            # SAFETY: Auto-refund if money was held in escrow
            if b.payment_status == "held_escrow":
                b.payment_status = "refunded"
                logger.info(
                    f"booking.refunded booking_id={booking_id} "
                    f"cancelled_by={cancelled_by or 'unknown'} "
                    f"gross_value={b.gross_value}"
                )
            # Guide cancellation penalty — log for review
            if cancelled_by == "guide":
                logger.warning(
                    f"booking.guide_cancel penalty flagged booking_id={booking_id} guide_id={b.guide_id}"
                )

        b.status = new_status

    db.commit()
    logger.info(f"booking.status_updated booking_id={booking_id} status={b.status}")
    return {
        "id": b.id,
        "status": b.status,
        "payment_status": b.payment_status,
    }


# ─── Itinerary endpoints ────────────────────────────────────────────────────────

@app.get("/api/itineraries/{booking_id}")
async def get_itinerary(booking_id: int, db: Session = Depends(get_db)):
    it = db.query(models.Itinerary).filter_by(booking_id=booking_id).first()
    if not it:
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


# ─── Rating endpoints ───────────────────────────────────────────────────────────

@app.post("/api/ratings")
async def create_rating(
    data: dict,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """Create a rating. Requires JWT; tourist_id from token."""
    if data.get("booking_id"):
        booking = db.query(models.Booking).filter_by(id=data["booking_id"]).first()
        if booking and booking.tourist_id != tourist_id:
            raise HTTPException(status_code=403, detail="Not your booking to rate")

    r = models.Rating(
        tourist_id=tourist_id,
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
    logger.info(f"rating.created tourist_id={tourist_id} guide_id={r.guide_id} rating={r.rating}")
    return {"id": r.id, "rating": r.rating}


# ─── TripPlan endpoints (Grab-style tourist-proposes flow) ─────────────────────

@app.post("/api/trip-plans")
async def create_trip_plan(
    data: dict,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """Create a trip plan proposal. Requires JWT; tourist_id from token."""
    plan = models.TripPlan(
        tourist_id=tourist_id,
        destination=data.get("destination", ""),
        interests=data.get("interests", ""),
        proposed_stops=data.get("proposed_stops", []),
        status="OPEN",
        tour_date=data.get("tour_date"),
        duration_hours=data.get("duration_hours"),
        group_size=data.get("group_size"),
    )
    db.add(plan)
    db.commit()
    db.refresh(plan)
    logger.info(f"trip_plan.created plan_id={plan.id} tourist_id={tourist_id}")
    return {"id": plan.id, "status": plan.status}


@app.get("/api/trip-plans")
async def list_trip_plans(
    tourist_id: str | None = None,
    guide_id: str | None = None,
    status: str | None = None,
    auth_tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """
    List trip plans. Authenticated tourists see their own plans.
    Guides (guide_id in query) see OPEN plans from all tourists.
    """
    query = db.query(models.TripPlan)
    if tourist_id:
        # Tourists can only see their own plans
        if tourist_id != auth_tourist_id:
            raise HTTPException(status_code=403, detail="Cannot view another tourist's plans")
        query = query.filter_by(tourist_id=tourist_id)
    if guide_id:
        query = query.filter_by(guide_id=guide_id)
    if status:
        query = query.filter_by(status=status)
    plans = query.order_by(models.TripPlan.created_at.desc()).all()

    return [
        {
            "id": p.id,
            "tourist_id": p.tourist_id,
            "destination": p.destination,
            "interests": p.interests.split("|") if p.interests else [],
            "proposed_stops": p.proposed_stops,
            "status": p.status,
            "guide_id": p.guide_id,
            "tour_date": p.tour_date,
            "duration_hours": p.duration_hours,
            "group_size": p.group_size,
            "created_at": p.created_at.isoformat() if p.created_at else None,
        }
        for p in plans
    ]


@app.get("/api/trip-plans/{plan_id}")
async def get_trip_plan(plan_id: int, db: Session = Depends(get_db)):
    p = db.query(models.TripPlan).filter_by(id=plan_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Trip plan not found")
    return {
        "id": p.id,
        "tourist_id": p.tourist_id,
        "destination": p.destination,
        "interests": p.interests.split("|") if p.interests else [],
        "proposed_stops": p.proposed_stops,
        "status": p.status,
        "guide_id": p.guide_id,
        "tour_date": p.tour_date,
        "duration_hours": p.duration_hours,
        "group_size": p.group_size,
        "created_at": p.created_at.isoformat() if p.created_at else None,
    }


@app.post("/api/trip-plans/{plan_id}/accept")
async def accept_trip_plan(
    plan_id: int,
    guide_id: str = Depends(_get_guide_id),
    db: Session = Depends(get_db),
):
    """
    Guide accepts an OPEN trip plan.
    Requires guide JWT auth — guide_id comes from the token, not the request body.
    """
    p = db.query(models.TripPlan).filter_by(id=plan_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Trip plan not found")
    if p.status != "OPEN":
        raise HTTPException(status_code=400, detail=f"Cannot accept plan with status {p.status}")

    guide = db.query(models.Guide).filter_by(id=guide_id).first()
    if not guide:
        raise HTTPException(status_code=404, detail="Guide not found")
    if not guide.license_verified:
        raise HTTPException(status_code=400, detail="Guide is not license verified")
    if (guide.rating_count or 0) < 5:
        raise HTTPException(status_code=400, detail="Guide does not meet minimum rating threshold")

    p.status = "ACCEPTED"
    p.guide_id = guide_id

    # SAFETY: Also confirm any REQUESTED booking for this tourist+guide
    # The booking was created before the trip plan was accepted, so it wasn't
    # linked at creation time. Find and confirm it now.
    linked_booking = db.query(models.Booking).filter(
        models.Booking.tourist_id == p.tourist_id,
        models.Booking.guide_id == guide_id,
        models.Booking.status == "REQUESTED",
    ).first()
    if linked_booking:
        linked_booking.status = "CONFIRMED"
        logger.info(
            f"booking.confirmed_via_plan_accept booking_id={linked_booking.id} "
            f"plan_id={plan_id} guide_id={guide_id}"
        )

    db.commit()
    logger.info(f"trip_plan.accepted plan_id={plan_id} guide_id={guide_id}")
    return {"id": p.id, "status": p.status, "guide_id": p.guide_id}


@app.put("/api/trip-plans/{plan_id}")
async def update_trip_plan(
    plan_id: int,
    data: dict,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """Update a trip plan. Requires JWT; tourist can only update own plans.

    SAFETY: When cancelling a TripPlan that has a linked booking,
    the booking is also cancelled and payment is auto-refunded.
    """
    p = db.query(models.TripPlan).filter_by(id=plan_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Trip plan not found")
    if p.tourist_id != tourist_id:
        raise HTTPException(status_code=403, detail="Not your trip plan")

    new_status = data.get("status")
    if new_status:
        # SAFETY: If cancelling a plan with a linked booking, cancel the booking too
        if new_status == "CANCELLED" and p.booking_id:
            booking = db.query(models.Booking).filter_by(id=p.booking_id).first()
            if booking:
                booking.payment_status = "refunded"
                booking.status = "CANCELLED"
                logger.info(
                    f"trip_plan_cancel.cancelled_linked_booking "
                    f"plan_id={plan_id} booking_id={booking.id} "
                    f"gross_value={booking.gross_value}"
                )
        p.status = new_status

    if "tour_date" in data:
        p.tour_date = data["tour_date"]
    if "duration_hours" in data:
        p.duration_hours = data["duration_hours"]
    if "group_size" in data:
        p.group_size = data["group_size"]
    if "destination" in data:
        p.destination = data["destination"]
    db.commit()
    logger.info(f"trip_plan.updated plan_id={plan_id} status={p.status}")
    return {"id": p.id, "status": p.status}


# ─── Admin ─────────────────────────────────────────────────────────────────────

@app.post("/api/admin/reseed")
async def reseed_database(
    data: dict | None = None,
    db: Session = Depends(get_db),
):
    """
    Reseed the database. Requires admin token in request body.
    """
    admin_token = data.get("admin_token") if data else None
    if admin_token != "wanderless-admin-token":
        raise HTTPException(status_code=403, detail="Invalid admin token")
    init_db(db)
    db.commit()
    logger.info("database.reseed complete")
    return {"status": "reseeded"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
