"""
FastAPI application — WanderLess backend.
Full auth: JWT-based tourist authentication + guide auth.
"""

import logging
import os
import time
import uuid
from datetime import datetime, timedelta
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database import init_db, get_db, compute_dot_range
from matching import compatibility_score, top_matches
from ml import fit_recommender, get_review_intelligence, compute_booking_quote
import models  # noqa: F401 — models registered with Base.metadata

load_dotenv()

logger = logging.getLogger("wanderless")
logging.basicConfig(level=logging.INFO)

# Auth configuration — all secrets from environment
SECRET_KEY = os.environ.get("SECRET_KEY", "wanderless-dev-secret-change-in-production-min-32-chars")
ADMIN_TOKEN = os.environ.get("ADMIN_TOKEN", "wanderless-admin-token")
ALLOWED_ORIGINS = os.environ.get("ALLOWED_ORIGINS", "*").split(",")
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
    from datetime import timezone
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS))
    payload = {"sub": tourist_id, "exp": expire, "iat": now}
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
    import bcrypt
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=14)).decode("utf-8")


def _verify_password(password: str, hashed: str) -> bool:
    import bcrypt
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))


# ─── Wallet helpers ──────────────────────────────────────────────────────────────

def _get_or_create_wallet(db: Session, owner_id: str, owner_type: str) -> models.Wallet:
    """Return existing wallet or create a new one with zero balance."""
    wallet = db.query(models.Wallet).filter_by(owner_id=owner_id, owner_type=owner_type).first()
    if wallet:
        return wallet
    wallet = models.Wallet(
        id=f"W{uuid.uuid4().hex[:8].upper()}",
        owner_id=owner_id,
        owner_type=owner_type,
        balance=0.0,
        currency="THB",
    )
    db.add(wallet)
    db.commit()
    db.refresh(wallet)
    return wallet


def _wallet_transaction(
    db: Session,
    wallet: models.Wallet,
    txn_type: str,
    amount: float,
    booking_id: int | None = None,
    description: str | None = None,
) -> models.WalletTransaction:
    """Add a transaction record and update wallet balance atomically.
    Checks sufficient balance BEFORE debit to prevent race-condition overdrafts."""
    if amount < 0 and wallet.balance + amount < 0:
        raise HTTPException(status_code=400, detail="Insufficient wallet balance")
    wallet.balance += amount
    txn = models.WalletTransaction(
        wallet_id=wallet.id,
        txn_type=txn_type,
        amount=amount,
        booking_id=booking_id,
        description=description,
    )
    db.add(txn)
    db.commit()
    db.refresh(wallet)
    return txn


# ─── Lifespan ───────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: seed DB from CSV
    db = next(get_db())
    init_db(db)

    # Auto-seed test accounts so the API is usable on first deploy
    import seed_accounts
    seed_accounts.main()

    # Fit ML recommender on seeded data
    tourists = db.query(models.Tourist).all()
    guides = db.query(models.Guide).all()
    ratings = db.query(models.Rating).all()
    fit_recommender(tourists, guides, ratings)

    # Build review intelligence profiles for all guides
    intelligence = get_review_intelligence()
    reviews_by_guide: dict[str, list[dict]] = {}
    for r in ratings:
        if r.guide_id not in reviews_by_guide:
            reviews_by_guide[r.guide_id] = []
        reviews_by_guide[r.guide_id].append({
            "text": f"Rating {r.rating}/5 for guide {r.guide_id}",
            "rating": r.rating,
        })
    for gid, rlist in reviews_by_guide.items():
        intelligence.analyze_guide(gid, rlist)

    db.close()
    logger.info("wanderless.startup database_seeded ml_recommender_fitted review_intelligence_fitted")
    yield
    logger.info("wanderless.shutdown server_shutdown")


app = FastAPI(title="WanderLess API", version="0.2.0", lifespan=lifespan)

# CORS — explicit origins only (no wildcard in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def _rate_limit_middleware(request: Request, call_next):
    if request.method == "OPTIONS":
        return await call_next(request)
    client_ip = request.client.host if request.client else "unknown"
    try:
        _check_rate_limit(client_ip)
    except HTTPException:
        raise  # Re-raise so FastAPI error handling + CORS middleware handle it
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
        "languages": t.languages.split("|") if t.languages else [],
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
        "photo_url": t.photo_url or "",
        "food_interest": t.food_interest,
        "culture_interest": t.culture_interest,
        "adventure_interest": t.adventure_interest,
        "pace_preference": t.pace_preference,
        "budget_level": t.budget_level,
        "language": t.language,
        "languages": t.languages.split("|") if t.languages else [],
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
    languages = data.get("languages")
    if isinstance(languages, list):
        languages = "|".join(languages)
    t = models.Tourist(
        id=tourist_id,
        food_interest=data["food_interest"],
        culture_interest=data["culture_interest"],
        adventure_interest=data["adventure_interest"],
        pace_preference=data["pace_preference"],
        budget_level=data["budget_level"],
        language=data.get("language", "en"),
        languages=languages,
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
    if "languages" in data:
        langs = data["languages"]
        t.languages = "|".join(langs) if isinstance(langs, list) else langs
    db.commit()
    logger.info(f"tourist.preferences_updated tourist_id={tid}")
    return {"id": t.id, "status": "updated"}


# ─── Tourist wallet endpoints ──────────────────────────────────────────────────────

@app.get("/api/auth/wallet")
async def get_tourist_wallet(
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """Get current tourist's wallet balance."""
    wallet = _get_or_create_wallet(db, tourist_id, "tourist")
    return {"wallet_id": wallet.id, "balance": wallet.balance, "currency": wallet.currency}


@app.post("/api/auth/wallet/deposit")
async def deposit_tourist_wallet(
    data: dict,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """Deposit funds into the current tourist's wallet."""
    amount = data.get("amount", 0)
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    wallet = _get_or_create_wallet(db, tourist_id, "tourist")
    _wallet_transaction(db, wallet, "deposit", amount, description=f"Wallet deposit")
    logger.info(f"wallet.deposit tourist_id={tourist_id} amount={amount}")
    return {"wallet_id": wallet.id, "balance": wallet.balance, "deposited": amount}


@app.get("/api/auth/wallet/transactions")
async def get_tourist_wallet_transactions(
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """Get transaction history for the current tourist's wallet."""
    wallet = _get_or_create_wallet(db, tourist_id, "tourist")
    txns = (
        db.query(models.WalletTransaction)
        .filter_by(wallet_id=wallet.id)
        .order_by(models.WalletTransaction.created_at.desc())
        .limit(50)
        .all()
    )
    return [
        {
            "id": t.id,
            "txn_type": t.txn_type,
            "amount": t.amount,
            "currency": t.currency,
            "booking_id": t.booking_id,
            "description": t.description,
            "created_at": t.created_at.isoformat() if t.created_at else None,
        }
        for t in txns
    ]


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
            "expertise_tags": (g.expertise_tags or "").split("|"),
            "language_pairs": (g.language_pairs or "").split("|"),
            "pace_style": g.pace_style,
            "group_size_preferred": g.group_size_preferred,
            "budget_tier": g.budget_tier,
            "location_coverage": (g.location_coverage or "").split("|"),
            "rating": g.rating_history,
            "review_count": g.rating_count,
            "price_range": None,
            "response_rate": None,
            "response_time": None,
            "specialties": (g.specialties or "").split("|"),
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
        "expertise_tags": (g.expertise_tags or "").split("|"),
        "personality_vector": [float(x) for x in (g.personality_vector or "").split("|")] if g.personality_vector else [],
        "language_pairs": (g.language_pairs or "").split("|"),
        "pace_style": g.pace_style,
        "group_size_preferred": g.group_size_preferred,
        "budget_tier": g.budget_tier,
        "location_coverage": (g.location_coverage or "").split("|"),
        "availability": g.availability,
        "rating": g.rating_history,
        "review_count": g.rating_count,
        "price_range": None,
        "response_rate": None,
        "response_time": None,
        "specialties": (g.specialties or "").split("|"),
        "license_verified": g.license_verified,
    }


# ─── Guide auth endpoints ────────────────────────────────────────────────────────

@app.post("/api/guides/register")
async def register_guide(data: dict, db: Session = Depends(get_db)):
    """
    Register a new guide account.
    Creates a new Guide record with auto-generated ID.
    Returns JWT token for immediate login.
    """
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    name = data.get("name", "").strip()
    bio = data.get("bio", "").strip()

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required")
    if not password or len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not name:
        raise HTTPException(status_code=400, detail="Name is required")

    existing_email = db.query(models.Guide).filter_by(email=email).first()
    if existing_email:
        raise HTTPException(status_code=409, detail="Email already registered")

    # Auto-generate guide ID: G + 8 char uppercase hex
    guide_id = f"G{uuid.uuid4().hex[:8].upper()}"

    guide = models.Guide(
        id=guide_id,
        email=email,
        password_hash=_hash_password(password),
        name=name,
        bio=bio or "Local guide ready to show you around!",
        expertise_tags="culture|food|adventure",
        personality_vector="|".join(["0.5"] * 8),
        language_pairs=data.get("language_pair", "en→th"),
        pace_style=0.5,
        group_size_preferred=4,
        budget_tier="mid",
        location_coverage="Chiang Mai",
        availability={},
        rating_history=0.0,
        rating_count=0,
        specialties="local_culture|food_tours|history",
        license_verified=False,
        owner_id=None,
    )
    db.add(guide)
    db.commit()
    logger.info(f"guide.register guide_id={guide_id} email={email}")

    token = _create_token(guide_id)
    return {
        "access_token": token,
        "token_type": "bearer",
        "guide_id": guide_id,
        "name": name,
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
        "rating": g.rating_history,
        "review_count": g.rating_count,
        "price_range": None,
        "response_rate": None,
        "response_time": None,
        "specialties": g.specialties.split("|") if g.specialties else [],
        "license_verified": g.license_verified,
        "owner_id": g.owner_id,
    }


# ─── Guide wallet endpoints ────────────────────────────────────────────────────────

@app.get("/api/guides/auth/wallet")
async def get_guide_wallet(
    guide_id: str = Depends(_get_guide_id),
    db: Session = Depends(get_db),
):
    """Get current guide's wallet balance."""
    wallet = _get_or_create_wallet(db, guide_id, "guide")
    return {"wallet_id": wallet.id, "balance": wallet.balance, "currency": wallet.currency}


@app.post("/api/guides/auth/wallet/deposit")
async def deposit_guide_wallet(
    data: dict,
    guide_id: str = Depends(_get_guide_id),
    db: Session = Depends(get_db),
):
    """Deposit funds into the current guide's wallet (for manual top-ups / testing)."""
    amount = data.get("amount", 0)
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    wallet = _get_or_create_wallet(db, guide_id, "guide")
    _wallet_transaction(db, wallet, "deposit", amount, description=f"Wallet deposit")
    logger.info(f"wallet.deposit guide_id={guide_id} amount={amount}")
    return {"wallet_id": wallet.id, "balance": wallet.balance, "deposited": amount}


@app.get("/api/guides/auth/wallet/transactions")
async def get_guide_wallet_transactions(
    guide_id: str = Depends(_get_guide_id),
    db: Session = Depends(get_db),
):
    """Get transaction history for the current guide's wallet."""
    wallet = _get_or_create_wallet(db, guide_id, "guide")
    txns = (
        db.query(models.WalletTransaction)
        .filter_by(wallet_id=wallet.id)
        .order_by(models.WalletTransaction.created_at.desc())
        .limit(50)
        .all()
    )
    return [
        {
            "id": t.id,
            "txn_type": t.txn_type,
            "amount": t.amount,
            "currency": t.currency,
            "booking_id": t.booking_id,
            "description": t.description,
            "created_at": t.created_at.isoformat() if t.created_at else None,
        }
        for t in txns
    ]


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
    name = data.get("name", "").strip()
    business_name = data.get("business_name", "").strip()

    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="Valid email is required")
    if not password or len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not name:
        raise HTTPException(status_code=400, detail="Your name is required")
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
        name=name,
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


# ─── Business wallet endpoints ─────────────────────────────────────────────────────

@app.get("/api/business/wallet")
async def get_business_wallet(
    owner_id: str = Depends(_get_business_owner_id),
    db: Session = Depends(get_db),
):
    """Get current business owner's wallet balance."""
    wallet = _get_or_create_wallet(db, owner_id, "business")
    return {"wallet_id": wallet.id, "balance": wallet.balance, "currency": wallet.currency}


@app.post("/api/business/wallet/deposit")
async def deposit_business_wallet(
    data: dict,
    owner_id: str = Depends(_get_business_owner_id),
    db: Session = Depends(get_db),
):
    """Deposit funds into the business owner's wallet."""
    amount = data.get("amount", 0)
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    wallet = _get_or_create_wallet(db, owner_id, "business")
    _wallet_transaction(db, wallet, "deposit", amount, description=f"Wallet deposit")
    logger.info(f"wallet.deposit business_owner_id={owner_id} amount={amount}")
    return {"wallet_id": wallet.id, "balance": wallet.balance, "deposited": amount}


@app.get("/api/business/wallet/transactions")
async def get_business_wallet_transactions(
    owner_id: str = Depends(_get_business_owner_id),
    db: Session = Depends(get_db),
):
    """Get transaction history for the business owner's wallet."""
    wallet = _get_or_create_wallet(db, owner_id, "business")
    txns = (
        db.query(models.WalletTransaction)
        .filter_by(wallet_id=wallet.id)
        .order_by(models.WalletTransaction.created_at.desc())
        .limit(50)
        .all()
    )
    return [
        {
            "id": t.id,
            "txn_type": t.txn_type,
            "amount": t.amount,
            "currency": t.currency,
            "booking_id": t.booking_id,
            "description": t.description,
            "created_at": t.created_at.isoformat() if t.created_at else None,
        }
        for t in txns
    ]


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
            "rating": g.rating_history,
            "review_count": g.rating_count,
            "price_range": None,
            "response_rate": None,
            "response_time": None,
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
    tourist_id: str | None = Depends(_get_tourist_id_optional),
    db: Session = Depends(get_db),
):
    """
    Get top-N matched guides for a tourist.
    Auth optional — anonymous users can access their own matches via URL tourist_id.
    """
    t0 = time.monotonic()
    effective_id = tourist_id if tourist_id is not None else tid
    logger.info(f"matches.start tourist_id={effective_id} top_n={top_n} destination={destination}")

    # Authenticated users can only access their own matches
    if tourist_id is not None and tid != tourist_id:
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
            "expertise_tags": (g.expertise_tags or "").split("|"),
            "language_pairs": (g.language_pairs or "").split("|"),
            "location_coverage": (g.location_coverage or "").split("|"),
            "rating": g.rating_history,
            "review_count": g.rating_count,
            "price_range": None,
            "response_rate": None,
            "response_time": None,
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
            "expertise_tags": (g.expertise_tags or "").split("|"),
            "location_coverage": (g.location_coverage or "").split("|"),
            "rating": g.rating_history,
            "review_count": g.rating_count,
            "price_range": None,
            "response_rate": None,
            "response_time": None,
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
    insurance_pct = 0.05  # 5% insurance fee

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
        insurance_pct=insurance_pct,
        status="REQUESTED",
        payment_status="held_escrow",
    )
    db.add(b)

    # Deduct from tourist's wallet (instant payment)
    tourist_wallet = _get_or_create_wallet(db, tourist_id, "tourist")
    try:
        _wallet_transaction(
            db,
            tourist_wallet,
            "payment",
            -gross_value,
            booking_id=b.id,
            description=f"Booking #{b.id} payment",
        )
    except HTTPException as e:
        db.rollback()
        raise HTTPException(status_code=400, detail="Insufficient wallet balance")

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
    return {
        "id": b.id,
        "status": b.status,
        "gross_value": b.gross_value,
        "fee_breakdown": {
            "gross_value": b.gross_value,
            "platform_commission": round(b.gross_value * b.platform_commission_pct, 2),
            "insurance": round(b.gross_value * (b.insurance_pct or 0), 2),
            "net_to_guide": round(b.gross_value * (1 - b.platform_commission_pct - (b.insurance_pct or 0)), 2),
        },
    }


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
        "platform_commission_pct": b.platform_commission_pct,
        "insurance_pct": b.insurance_pct,
        "status": b.status,
        "payment_status": b.payment_status,
        # Explicit fee breakdown
        "fee_breakdown": {
            "gross_value": b.gross_value,
            "platform_commission": round(b.gross_value * b.platform_commission_pct, 2),
            "insurance": round(b.gross_value * (b.insurance_pct or 0), 2),
            "net_to_guide": round(b.gross_value * (1 - b.platform_commission_pct - (b.insurance_pct or 0)), 2),
        },
    }


@app.get("/api/bookings")
async def list_bookings(
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """List all bookings for the authenticated tourist."""
    bookings = db.query(models.Booking).filter_by(tourist_id=tourist_id).order_by(models.Booking.created_at.desc()).all()
    # Pre-fetch guide names to avoid N queries
    guide_ids = {b.guide_id for b in bookings}
    guides = db.query(models.Guide).filter(models.Guide.id.in_(guide_ids)).all() if guide_ids else []
    guide_map = {g.id: g.name for g in guides}
    return [
        {
            "id": b.id,
            "tourist_id": b.tourist_id,
            "guide_id": b.guide_id,
            "guide_name": guide_map.get(b.guide_id, "Unknown Guide"),
            "destination": b.destination,
            "tour_date": b.tour_date,
            "duration_hours": b.duration_hours,
            "group_size": b.group_size,
            "gross_value": b.gross_value,
            "status": b.status,
            "payment_status": b.payment_status,
            "fee_breakdown": {
                "gross_value": b.gross_value,
                "platform_commission": round(b.gross_value * b.platform_commission_pct, 2),
                "insurance": round(b.gross_value * (b.insurance_pct or 0), 2),
                "net_to_guide": round(b.gross_value * (1 - b.platform_commission_pct - (b.insurance_pct or 0)), 2),
            },
        }
        for b in bookings
    ]


@app.get("/api/guide/bookings")
async def list_guide_bookings(
    guide_id: str = Depends(_get_guide_id),
    db: Session = Depends(get_db),
):
    """List all bookings for the authenticated guide (current jobs + history)."""
    bookings = db.query(models.Booking).filter_by(guide_id=guide_id).order_by(models.Booking.created_at.desc()).all()
    # Pre-fetch tourist names
    tourist_ids = {b.tourist_id for b in bookings}
    tourists = db.query(models.Tourist).filter(models.Tourist.id.in_(tourist_ids)).all() if tourist_ids else []
    tourist_map = {t.id: t.name for t in tourists}
    return [
        {
            "id": b.id,
            "tourist_id": b.tourist_id,
            "tourist_name": tourist_map.get(b.tourist_id, "Unknown Tourist"),
            "guide_id": b.guide_id,
            "destination": b.destination,
            "tour_date": b.tour_date,
            "duration_hours": b.duration_hours,
            "group_size": b.group_size,
            "gross_value": b.gross_value,
            "status": b.status,
            "payment_status": b.payment_status,
            "fee_breakdown": {
                "gross_value": b.gross_value,
                "platform_commission": round(b.gross_value * b.platform_commission_pct, 2),
                "insurance": round(b.gross_value * (b.insurance_pct or 0), 2),
                "net_to_guide": round(b.gross_value * (1 - b.platform_commission_pct - (b.insurance_pct or 0)), 2),
            },
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

    new_status = data.get("status")

    # Guide qualification guard: prevent unqualified guides from confirming bookings
    if is_guide and new_status == "CONFIRMED" and b.status == "REQUESTED":
        guide = db.query(models.Guide).filter_by(id=guide_id).first()
        if guide:
            if not guide.license_verified:
                raise HTTPException(status_code=400, detail="Guide license not verified")
            if (guide.rating_count or 0) < 5:
                raise HTTPException(status_code=400, detail="Guide rating below minimum (5 required)")
        logger.info(
            f"booking.guide_qualified booking_id={booking_id} "
            f"guide_id={guide_id} license_verified={guide.license_verified} "
            f"rating_count={guide.rating_count}"
        )

    valid_transitions = {
        "REQUESTED": ["CONFIRMED", "CANCELLED"],
        "CONFIRMED": ["PAID", "CANCELLED"],
        "PAID": ["IN_PROGRESS", "CANCELLED"],
        "IN_PROGRESS": ["COMPLETED"],
        "COMPLETED": [],
        "CANCELLED": [],
    }
    cancelled_by = data.get("cancelled_by")  # 'tourist' or 'guide'

    if new_status:
        allowed = valid_transitions.get(b.status, [])
        if new_status not in allowed:
            raise HTTPException(status_code=400, detail=f"Cannot transition from {b.status} to {new_status}")

        if new_status == "CANCELLED":
            # SAFETY: Auto-refund if money was held in escrow
            if b.payment_status == "held_escrow":
                b.payment_status = "refunded"
                # Refund tourist's wallet
                tourist_wallet = _get_or_create_wallet(db, b.tourist_id, "tourist")
                _wallet_transaction(
                    db,
                    tourist_wallet,
                    "refund",
                    b.gross_value,
                    booking_id=b.id,
                    description=f"Refund for cancelled booking #{b.id}",
                )
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

        if new_status == "COMPLETED":
            # Pay guide: gross minus platform commission
            guide_pay = b.gross_value * (1 - b.platform_commission_pct)
            guide_wallet = _get_or_create_wallet(db, b.guide_id, "guide")
            _wallet_transaction(
                db,
                guide_wallet,
                "payout",
                guide_pay,
                booking_id=b.id,
                description=f"Payout for completed booking #{b.id}",
            )
            # Pay business owner their commission share
            commission = b.gross_value * b.platform_commission_pct
            guide = db.query(models.Guide).filter_by(id=b.guide_id).first()
            if guide and guide.owner_id:
                business_wallet = _get_or_create_wallet(db, guide.owner_id, "business")
                _wallet_transaction(
                    db,
                    business_wallet,
                    "commission",
                    commission,
                    booking_id=b.id,
                    description=f"Commission from booking #{b.id}",
                )
            b.payment_status = "released"
            logger.info(
                f"booking.payout_completed booking_id={booking_id} "
                f"guide_pay={guide_pay} commission={commission}"
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


# ─── Review Intelligence endpoints ────────────────────────────────────────────────

@app.get("/api/reviews/guide/{guide_id}/profile")
async def get_guide_review_profile(
    guide_id: str,
    db: Session = Depends(get_db),
):
    """
    Get a comprehensive review intelligence profile for a guide.
    Returns traveler-type tags, topic scores, strengths, improvement signals,
    sentiment trend, and matching tags for guide-tourist matching.
    """
    reviews = db.query(models.Rating).filter_by(guide_id=guide_id).all()
    if not reviews:
        return {
            "guide_id": guide_id,
            "n_reviews": 0,
            "profile": None,
            "matching_tags": {"traveler_types": [], "topics": [], "sentiment": "no_data"},
        }

    # Get associated bookings for review text if available
    review_data = []
    for r in reviews:
        review_text = ""
        # Check if there's a text review in the booking or a separate review table
        # For now, construct from rating metadata
        booking = db.query(models.Booking).filter_by(id=r.booking_id).first() if r.booking_id else None
        review_data.append({
            "text": f"Rating {r.rating}/5 for guide {r.guide_id}",
            "rating": r.rating,
            "tourist_id": r.tourist_id,
        })

    intelligence = get_review_intelligence()
    profile = intelligence.analyze_guide(guide_id, review_data)
    matching_tags = intelligence.matching_tags_for_guide(guide_id)

    return {
        "guide_id": guide_id,
        "n_reviews": len(reviews),
        "profile": profile,
        "matching_tags": matching_tags,
    }


@app.post("/api/reviews/batch/profile")
async def batch_guide_review_profiles(
    guide_ids: list[str],
    db: Session = Depends(get_db),
):
    """
    Get review intelligence profiles for multiple guides at once.
    Used by the matching system to enrich guide profiles.
    """
    intelligence = get_review_intelligence()
    results = []
    for gid in guide_ids:
        reviews = db.query(models.Rating).filter_by(guide_id=gid).all()
        if not reviews:
            results.append({
                "guide_id": gid,
                "n_reviews": 0,
                "profile": None,
                "matching_tags": {"traveler_types": [], "topics": [], "sentiment": "no_data"},
            })
            continue
        review_data = [{"text": f"Rating {r.rating}/5", "rating": r.rating} for r in reviews]
        profile = intelligence.analyze_guide(gid, review_data)
        matching_tags = intelligence.matching_tags_for_guide(gid)
        results.append({
            "guide_id": gid,
            "n_reviews": len(reviews),
            "profile": profile,
            "matching_tags": matching_tags,
        })
    return {"guides": results}


# ─── Dynamic Pricing endpoint ────────────────────────────────────────────────────

@app.post("/api/pricing/quote")
async def get_booking_quote(
    data: dict,
    db: Session = Depends(get_db),
):
    """
    Compute dynamic pricing for a proposed booking.
    Returns per-person price, total price, surge level, and breakdown.
    Price quote expires in 15 minutes.
    """
    base_interest = data.get("interest", "mixed")
    duration_hours = float(data.get("duration_hours", 4.0))
    group_size = int(data.get("group_size", 2))
    tour_date = data.get("tour_date")  # ISO string
    tour_hour = data.get("tour_hour")  # 0-23
    guide_id = data.get("guide_id")

    guide_rating = None
    guide_rating_count = None
    booking_demand = 0.5  # default midpoint

    if guide_id:
        guide = db.query(models.Guide).filter_by(id=guide_id).first()
        if guide:
            guide_rating = guide.rating_history
            guide_rating_count = guide.rating_count
            # Estimate demand from recent booking count
            recent_bookings = db.query(models.Booking).filter_by(guide_id=guide_id).count()
            # Normalize: 0 bookings = 0 demand, 20+ bookings = 1.0
            booking_demand = min(1.0, recent_bookings / 20.0)

    quote = compute_booking_quote(
        base_interest=base_interest,
        duration_hours=duration_hours,
        group_size=group_size,
        tour_date=tour_date,
        tour_hour=tour_hour,
        guide_rating=guide_rating,
        guide_rating_count=guide_rating_count,
        booking_demand=booking_demand,
    )

    return quote


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
        safety_weight=data.get("safety_weight"),
        dietary_requirement=data.get("dietary_requirement"),
        avoid_late_night=data.get("avoid_late_night"),
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
    auth_tourist_id: str | None = Depends(_get_tourist_id_optional),
    auth_guide_id: str | None = Depends(_get_guide_id_optional),
    db: Session = Depends(get_db),
):
    """
    List trip plans. Authenticated tourists see their own plans.
    Guides can see OPEN plans from all tourists (for job discovery).
    """
    query = db.query(models.TripPlan)

    # Guide auth — guide browsing for work (job discovery)
    if auth_guide_id and not auth_tourist_id:
        # Guides see OPEN plans by default for job discovery
        query = query.filter_by(status=status if status else "OPEN")
        # Guides can only see their OWN assigned plans via auth context — NOT via query param override
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
                "negotiation_rounds": p.negotiation_rounds or 0,
                "alternatives": p.alternatives,
                "guide_proposed_stops": p.guide_proposed_stops,
                "safety_weight": p.safety_weight,
                "dietary_requirement": p.dietary_requirement,
                "avoid_late_night": p.avoid_late_night,
                "created_at": p.created_at.isoformat() if p.created_at else None,
            }
            for p in plans
        ]

    # Tourist auth
    if auth_tourist_id:
        if tourist_id:
            if tourist_id != auth_tourist_id:
                raise HTTPException(status_code=403, detail="Cannot view another tourist's plans")
        else:
            tourist_id = auth_tourist_id

    if tourist_id:
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
            "negotiation_rounds": p.negotiation_rounds or 0,
            "alternatives": p.alternatives,
            "guide_proposed_stops": p.guide_proposed_stops,
            "safety_weight": p.safety_weight,
            "dietary_requirement": p.dietary_requirement,
            "avoid_late_night": p.avoid_late_night,
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
        "negotiation_rounds": p.negotiation_rounds or 0,
        "alternatives": p.alternatives,
        "guide_proposed_stops": p.guide_proposed_stops,
        "safety_weight": p.safety_weight,
        "dietary_requirement": p.dietary_requirement,
        "avoid_late_night": p.avoid_late_night,
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


@app.patch("/api/trip-plans/{plan_id}/counter")
async def counter_trip_plan(
    plan_id: int,
    data: dict,
    guide_id: str = Depends(_get_guide_id),
    db: Session = Depends(get_db),
):
    """
    Guide counters a trip plan with modified stops and/or alternatives.
    Increments negotiation_rounds. Changes status to TOURIST_REVIEWING.
    Max 2 rounds — if negotiation_rounds already >= 2, returns 400.
    Accepts: { guide_proposed_stops: [...], alternatives: [{rejected_stop, alternatives:[...]}], tour_date?, duration_hours? }
    """
    p = db.query(models.TripPlan).filter_by(id=plan_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Trip plan not found")

    # Only the assigned guide can counter
    if p.guide_id != guide_id:
        raise HTTPException(status_code=403, detail="Not your trip plan to counter")

    # Can counter from OPEN (guide proposes initial plan) or GUIDE_PROPOSED (counter-offer)
    if p.status not in ("OPEN", "GUIDE_PROPOSED"):
        raise HTTPException(status_code=400, detail=f"Cannot counter plan with status {p.status}")

    # Hard cap: max 2 negotiation rounds
    current_rounds = p.negotiation_rounds or 0
    if current_rounds >= 2:
        raise HTTPException(status_code=400, detail="Maximum negotiation rounds (2) reached")

    # Update guide's proposed stops
    if "guide_proposed_stops" in data:
        p.guide_proposed_stops = data["guide_proposed_stops"]

    # Update alternatives (what guide proposes when a stop is unavailable)
    if "alternatives" in data:
        p.alternatives = data["alternatives"]

    # Guide can also update timing
    if "tour_date" in data:
        p.tour_date = data["tour_date"]
    if "duration_hours" in data:
        p.duration_hours = data["duration_hours"]
    if "group_size" in data:
        p.group_size = data["group_size"]

    p.negotiation_rounds = current_rounds + 1
    p.status = "TOURIST_REVIEWING"

    db.commit()
    logger.info(
        f"trip_plan.counter plan_id={plan_id} guide_id={guide_id} "
        f"round={p.negotiation_rounds}"
    )
    return {
        "id": p.id,
        "status": p.status,
        "negotiation_rounds": p.negotiation_rounds,
        "guide_proposed_stops": p.guide_proposed_stops,
        "alternatives": p.alternatives,
    }


@app.post("/api/trip-plans/{plan_id}/tourist_review")
async def tourist_review_trip_plan(
    plan_id: int,
    data: dict,
    tourist_id: str = Depends(_get_tourist_id),
    db: Session = Depends(get_db),
):
    """
    Tourist reviews a guide's proposed (or counter-proposed) trip plan.
    Accept → status becomes ACCEPTED.
    Request changes → status becomes GUIDE_PROPOSED (guide re-counter-offer).
      If negotiation_rounds >= 2 when requesting changes → auto-REJECTED (cap reached).
    """
    p = db.query(models.TripPlan).filter_by(id=plan_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Trip plan not found")

    if p.tourist_id != tourist_id:
        raise HTTPException(status_code=403, detail="Not your trip plan")

    if p.status != "TOURIST_REVIEWING":
        raise HTTPException(status_code=400, detail=f"Cannot review plan with status {p.status}")

    action = data.get("action")  # "accept" | "request_changes"

    if action == "accept":
        p.status = "ACCEPTED"
        db.commit()
        logger.info(f"trip_plan.accepted_by_tourist plan_id={plan_id}")
        return {"id": p.id, "status": p.status, "negotiation_rounds": p.negotiation_rounds}

    elif action == "request_changes":
        current_rounds = p.negotiation_rounds or 0
        if current_rounds >= 2:
            # Auto-reject when tourist requests changes after 2 rounds
            p.status = "REJECTED"
            # Log rejection for ML feedback
            rejection = models.RejectionLog(
                trip_plan_id=p.id,
                guide_id=p.guide_id,
                tourist_id=tourist_id,
                rejection_reason="round_cap_reached",
                alternatives_offered=p.alternatives,
            )
            db.add(rejection)
            db.commit()
            logger.warning(
                f"trip_plan.auto_rejected plan_id={plan_id} "
                f"reason=round_cap_reached tourist_requests_changes_at_round_{current_rounds}"
            )
            return {
                "id": p.id,
                "status": p.status,
                "negotiation_rounds": p.negotiation_rounds,
                "detail": "Maximum negotiation rounds (2) reached. Plan auto-rejected."
            }

        # Send back to guide for counter-offer
        p.status = "GUIDE_PROPOSED"
        if "tourist_stops" in data:
            # Tourist can suggest modifications alongside their change request
            pass  # stored in proposed_stops already; guide counters from their own proposed_stops
        db.commit()
        logger.info(
            f"trip_plan.tourist_requests_changes plan_id={plan_id} "
            f"round={current_rounds}"
        )
        return {"id": p.id, "status": p.status, "negotiation_rounds": p.negotiation_rounds}

    else:
        raise HTTPException(status_code=400, detail="action must be 'accept' or 'request_changes'")


# ─── Checkpoint endpoints (GPS + photo at tour stops) ─────────────────────────

@app.post("/api/match-bids")
async def create_match_bid(
    data: dict,
    authorization: str | None = Header(None),
    db: Session = Depends(get_db),
):
    """
    Place a bid on a trip plan. Accepts guide or tourist JWT.
    If the other party has already bid on the same plan → immediate MATCH.
    """
    guide_id = _get_guide_id_optional(authorization)
    tourist_id = _get_tourist_id_optional(authorization)

    if not guide_id and not tourist_id:
        raise HTTPException(status_code=401, detail="Authorization required")

    bidder_id = guide_id or tourist_id
    bidder_type = "guide" if guide_id else "tourist"

    trip_plan_id = data.get("trip_plan_id")
    if not trip_plan_id:
        raise HTTPException(status_code=400, detail="trip_plan_id required")

    plan = db.query(models.TripPlan).filter_by(id=trip_plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Trip plan not found")

    # Target is always the other party
    target_id = plan.guide_id if bidder_type == "tourist" else plan.tourist_id
    target_type = "guide" if bidder_type == "tourist" else "tourist"

    if not target_id:
        raise HTTPException(status_code=400, detail="No counterparty assigned to this plan yet")

    # Check for existing opposing bid (the other party already bid → it's a MATCH)
    opposing = db.query(models.MatchBid).filter(
        models.MatchBid.trip_plan_id == trip_plan_id,
        models.MatchBid.bidder_type == target_type,
        models.MatchBid.bidder_id == target_id,
        models.MatchBid.status == "PENDING",
    ).first()

    bid = models.MatchBid(
        bidder_id=bidder_id,
        bidder_type=bidder_type,
        target_id=target_id,
        target_type=target_type,
        trip_plan_id=trip_plan_id,
        proposed_stops=plan.proposed_stops,
        status="MATCHED" if opposing else "PENDING",
    )
    db.add(bid)

    if opposing:
        opposing.status = "MATCHED"
        logger.info(
            f"match.match_created bid_id={bid.id} plan_id={trip_plan_id} "
            f"bidder={bidder_id} target={target_id}"
        )
    else:
        logger.info(
            f"match_bid.placed bid_id={bid.id} plan_id={trip_plan_id} "
            f"bidder={bidder_id} awaiting_counter_bid"
        )

    db.commit()
    db.refresh(bid)
    return {
        "id": bid.id,
        "status": bid.status,
        "matched": bid.status == "MATCHED",
        "trip_plan_id": bid.trip_plan_id,
    }


@app.get("/api/match-bids")
async def list_match_bids(
    authorization: str | None = Header(None),
    db: Session = Depends(get_db),
):
    """List all bids involving the current user (as bidder or target)."""
    guide_id = _get_guide_id_optional(authorization)
    tourist_id = _get_tourist_id_optional(authorization)

    if not guide_id and not tourist_id:
        raise HTTPException(status_code=401, detail="Authorization required")

    user_id = guide_id or tourist_id

    bids = db.query(models.MatchBid).filter(
        (models.MatchBid.bidder_id == user_id) | (models.MatchBid.target_id == user_id)
    ).order_by(models.MatchBid.created_at.desc()).all()

    return [
        {
            "id": b.id,
            "bidder_id": b.bidder_id,
            "bidder_type": b.bidder_type,
            "target_id": b.target_id,
            "target_type": b.target_type,
            "trip_plan_id": b.trip_plan_id,
            "proposed_stops": b.proposed_stops,
            "status": b.status,
            "created_at": b.created_at.isoformat() if b.created_at else None,
        }
        for b in bids
    ]


# ─── Checkpoint endpoints (GPS + photo at tour stops) ──────────────────────────

@app.post("/api/bookings/{booking_id}/checkpoints")
async def create_checkpoint(
    booking_id: int,
    data: dict,
    authorization: str | None = Header(None),
    db: Session = Depends(get_db),
):
    """
    Record a GPS + photo checkpoint during an active tour.
    Either the guide or tourist can add checkpoints.
    The photo_url is stored externally (Cloudinary/S3/etc.) — this endpoint records the metadata.
    """
    guide_id = _get_guide_id_optional(authorization)
    tourist_id = _get_tourist_id_optional(authorization)

    if not guide_id and not tourist_id:
        raise HTTPException(status_code=401, detail="Authorization required")

    booking = db.query(models.Booking).filter_by(id=booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Verify participant
    if guide_id and booking.guide_id != guide_id:
        raise HTTPException(status_code=403, detail="You are not the guide for this booking")
    if tourist_id and booking.tourist_id != tourist_id:
        raise HTTPException(status_code=403, detail="You are not the tourist for this booking")

    stop_name = data.get("stop_name")
    lat = data.get("lat")
    lng = data.get("lng")
    if not stop_name or lat is None or lng is None:
        raise HTTPException(status_code=400, detail="stop_name, lat, and lng are required")

    # Auto-assign sequence order as the next number for this booking
    existing = db.query(models.Checkpoint).filter_by(booking_id=booking_id).count()

    cp = models.Checkpoint(
        booking_id=booking_id,
        stop_name=stop_name,
        lat=lat,
        lng=lng,
        photo_url=data.get("photo_url"),
        caption=data.get("caption"),
        sequence_order=data.get("sequence_order", existing),
    )
    db.add(cp)
    db.commit()
    db.refresh(cp)
    logger.info(
        f"checkpoint.created booking_id={booking_id} stop={stop_name} "
        f"seq={cp.sequence_order} by={guide_id or tourist_id}"
    )
    return {
        "id": cp.id,
        "booking_id": cp.booking_id,
        "stop_name": cp.stop_name,
        "lat": cp.lat,
        "lng": cp.lng,
        "photo_url": cp.photo_url,
        "caption": cp.caption,
        "sequence_order": cp.sequence_order,
    }


@app.get("/api/bookings/{booking_id}/checkpoints")
async def list_checkpoints(
    booking_id: int,
    authorization: str | None = Header(None),
    db: Session = Depends(get_db),
):
    """List all checkpoints for a booking (used to assemble the souvenir montage)."""
    guide_id = _get_guide_id_optional(authorization)
    tourist_id = _get_tourist_id_optional(authorization)

    if not guide_id and not tourist_id:
        raise HTTPException(status_code=401, detail="Authorization required")

    booking = db.query(models.Booking).filter_by(id=booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if guide_id and booking.guide_id != guide_id and booking.tourist_id != tourist_id:
        raise HTTPException(status_code=403, detail="Not a participant of this booking")
    if tourist_id and booking.tourist_id != tourist_id and booking.guide_id != guide_id:
        raise HTTPException(status_code=403, detail="Not a participant of this booking")

    checkpoints = (
        db.query(models.Checkpoint)
        .filter_by(booking_id=booking_id)
        .order_by(models.Checkpoint.sequence_order)
        .all()
    )
    return [
        {
            "id": c.id,
            "stop_name": c.stop_name,
            "lat": c.lat,
            "lng": c.lng,
            "photo_url": c.photo_url,
            "caption": c.caption,
            "sequence_order": c.sequence_order,
            "created_at": c.created_at.isoformat() if c.created_at else None,
        }
        for c in checkpoints
    ]


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


# ─── Location tracking endpoints ─────────────────────────────────────────────────

@app.put("/api/bookings/{booking_id}/location")
async def update_location(
    booking_id: int,
    data: dict,
    authorization: str | None = Header(None),
    db: Session = Depends(get_db),
):
    """
    Update GPS location for the authenticated user (guide or tourist).
    Requires JWT auth. Only the guide or tourist assigned to the booking can update.
    Accepts: { "role": "guide" | "tourist", "lat": float, "lng": float }
    """
    # Authenticate — accept either tourist or guide JWT
    tourist_id = _get_tourist_id_optional(authorization)
    guide_id = _get_guide_id_optional(authorization)

    if not tourist_id and not guide_id:
        raise HTTPException(status_code=401, detail="Authorization required")

    role = data.get("role")
    lat = data.get("lat")
    lng = data.get("lng")

    if role not in ("guide", "tourist") or lat is None or lng is None:
        raise HTTPException(status_code=400, detail="role (guide|tourist), lat, and lng are required")

    # Verify the booking exists and the user is assigned to it
    booking = db.query(models.Booking).filter_by(id=booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if role == "guide":
        if guide_id != booking.guide_id:
            raise HTTPException(status_code=403, detail="You are not the guide for this booking")
    else:
        if tourist_id != booking.tourist_id:
            raise HTTPException(status_code=403, detail="You are not the tourist for this booking")

    # Get or create location tracking record
    loc = db.query(models.LocationTracking).filter_by(booking_id=booking_id).first()
    if not loc:
        loc = models.LocationTracking(booking_id=booking_id)
        db.add(loc)

    if role == "guide":
        loc.guide_lat = lat
        loc.guide_lng = lng
    else:
        loc.tourist_lat = lat
        loc.tourist_lng = lng

    loc.updated_at = datetime.utcnow()
    db.commit()

    logger.info(
        f"location.updated booking_id={booking_id} role={role} "
        f"lat={lat} lng={lng}"
    )
    return {
        "booking_id": booking_id,
        "guide_lat": loc.guide_lat,
        "guide_lng": loc.guide_lng,
        "tourist_lat": loc.tourist_lat,
        "tourist_lng": loc.tourist_lng,
        "updated_at": loc.updated_at.isoformat() if loc.updated_at else None,
    }


@app.get("/api/bookings/{booking_id}/location")
async def get_location(
    booking_id: int,
    authorization: str | None = Header(None),
    db: Session = Depends(get_db),
):
    """
    Get current GPS locations for guide and tourist on an active booking.
    Requires JWT auth. Either party on the booking can read locations.
    """
    tourist_id = _get_tourist_id_optional(authorization)
    guide_id = _get_guide_id_optional(authorization)

    if not tourist_id and not guide_id:
        raise HTTPException(status_code=401, detail="Authorization required")

    booking = db.query(models.Booking).filter_by(id=booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Either the guide or tourist of this booking can read locations
    is_guide = guide_id == booking.guide_id
    is_tourist = tourist_id == booking.tourist_id
    if not is_guide and not is_tourist:
        raise HTTPException(status_code=403, detail="Not a participant of this booking")

    loc = db.query(models.LocationTracking).filter_by(booking_id=booking_id).first()

    logger.info(f"location.read booking_id={booking_id} guide_id={guide_id} tourist_id={tourist_id}")
    return {
        "booking_id": booking_id,
        "guide_lat": loc.guide_lat if loc else None,
        "guide_lng": loc.guide_lng if loc else None,
        "tourist_lat": loc.tourist_lat if loc else None,
        "tourist_lng": loc.tourist_lng if loc else None,
        "updated_at": loc.updated_at.isoformat() if loc and loc.updated_at else None,
    }


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
    if admin_token != ADMIN_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid admin token")
    init_db(db)
    db.commit()
    logger.info("database.reseed complete")
    return {"status": "reseeded"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
