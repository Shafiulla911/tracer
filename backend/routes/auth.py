"""
auth.py — Authentication and user profile routes for Tracer Sentinel.
"""

import hashlib
import secrets
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import Report, TrapLink, TrackLog, User
from schemas import AuthResponse, UserCreate, UserLogin, UserOut, UserUpdate

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


def _hash_password(password: str, salt: str) -> str:
    """Generate salted SHA-256 hash."""
    return hashlib.sha256((password + salt).encode("utf-8")).hexdigest()


def _generate_token() -> str:
    """Generate secure random 64-char hex token."""
    return secrets.token_hex(32)


async def get_current_user(
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Dependency to validate bearer token and retrieve active user."""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing",
        )
    token = authorization.replace("Bearer ", "").strip()
    result = await db.execute(select(User).where(User.token == token, User.is_active == True))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session token",
        )
    return user


async def _enrich_user_stats(user: User, db: AsyncSession) -> UserOut:
    """Calculate reports, traps, and hit statistics for the user."""
    # Count reports filed
    rep_res = await db.execute(
        select(func.count(Report.id)).where(Report.user_id == user.id)
    )
    reports_count = rep_res.scalar() or 0

    # Total platform trap links and hits as baseline or user links if associated
    trap_res = await db.execute(select(func.count(TrapLink.id)))
    traps_count = trap_res.scalar() or 0

    hits_res = await db.execute(select(func.count(TrackLog.id)))
    hits_count = hits_res.scalar() or 0

    return UserOut(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone=user.phone,
        badge=user.badge,
        role=user.role,
        avatar_url=user.avatar_url,
        created_at=user.created_at,
        reports_count=reports_count,
        traps_count=traps_count,
        hits_count=hits_count,
    )


# ---------------------------------------------------------------------------
# POST /api/auth/register
# ---------------------------------------------------------------------------

@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    """Enlist a new Tracer Sentinel investigator."""
    clean_email = payload.email.strip().lower()
    clean_name = payload.full_name.strip()

    if not clean_email or not clean_name:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Full name and valid email are required",
        )

    # Check if email exists
    existing = await db.execute(select(User).where(User.email == clean_email))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An agent account with this email already exists",
        )

    salt = secrets.token_hex(16)
    password_hash = _hash_password(payload.password, salt)
    token = _generate_token()

    user = User(
        full_name=clean_name,
        email=clean_email,
        phone=payload.phone.strip() if payload.phone else None,
        password_hash=password_hash,
        salt=salt,
        token=token,
        badge="Field Investigator • Level 1",
        role="Agent",
        created_at=datetime.utcnow(),
        last_login=datetime.utcnow(),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    user_out = await _enrich_user_stats(user, db)
    return AuthResponse(
        token=token,
        user=user_out,
        message="Agent profile enlisted successfully into Sentinel Grid",
    )


# ---------------------------------------------------------------------------
# POST /api/auth/login
# ---------------------------------------------------------------------------

@router.post("/login", response_model=AuthResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    """Authenticate agent and issue session token."""
    clean_email = payload.email.strip().lower()

    result = await db.execute(select(User).where(User.email == clean_email, User.is_active == True))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # Verify password
    expected_hash = _hash_password(payload.password, user.salt)
    if user.password_hash != expected_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # Rotate or refresh token
    user.token = _generate_token()
    user.last_login = datetime.utcnow()
    await db.commit()
    await db.refresh(user)

    user_out = await _enrich_user_stats(user, db)
    return AuthResponse(
        token=user.token,
        user=user_out,
        message="Access granted to Sentinel Command Grid",
    )


# ---------------------------------------------------------------------------
# GET /api/auth/me
# ---------------------------------------------------------------------------

@router.get("/me", response_model=UserOut)
async def get_profile(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve current authenticated agent profile and statistics."""
    return await _enrich_user_stats(user, db)


# ---------------------------------------------------------------------------
# PUT /api/auth/profile
# ---------------------------------------------------------------------------

@router.put("/profile", response_model=UserOut)
async def update_profile(
    payload: UserUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update profile information."""
    if payload.full_name is not None and payload.full_name.strip():
        user.full_name = payload.full_name.strip()
    if payload.phone is not None:
        user.phone = payload.phone.strip()
    if payload.badge is not None and payload.badge.strip():
        user.badge = payload.badge.strip()

    await db.commit()
    await db.refresh(user)
    return await _enrich_user_stats(user, db)
