"""
routes/search.py — Endpoint for searching scammers by phone number or UPI ID.
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional

from database import get_db
from models import Scammer
from schemas import ScammerSearchResult

router = APIRouter(prefix="/api/search", tags=["Search"])


@router.get(
    "",
    response_model=List[ScammerSearchResult],
    summary="Search scammers by phone number or UPI ID",
)
async def search_scammers(
    q: Optional[str] = Query(None, description="Phone number or UPI ID to search for (returns top scammers if empty)"),
    db: AsyncSession = Depends(get_db),
):
    """
    Search the database for scammers matching the query string.

    If `q` is empty or omitted, returns top reported scammers.
    Otherwise matches are performed as case-insensitive substring searches
    against both `phone_number` and `upi_id` columns.

    Returns a list of matching scammers with a `is_dangerous` flag set to
    `True` when `reported_count >= 3`.
    """
    query_str = (q or "").strip()
    if query_str:
        pattern = f"%{query_str}%"
        stmt = (
            select(Scammer)
            .where(
                or_(
                    Scammer.phone_number.ilike(pattern),
                    Scammer.upi_id.ilike(pattern),
                )
            )
            .order_by(Scammer.reported_count.desc())
            .limit(50)
        )
    else:
        stmt = select(Scammer).order_by(Scammer.reported_count.desc()).limit(50)

    result = await db.execute(stmt)
    scammers = result.scalars().all()

    return [
        ScammerSearchResult(
            id=s.id,
            phone_number=s.phone_number,
            upi_id=s.upi_id,
            name=s.name,
            reported_count=s.reported_count,
            is_dangerous=s.reported_count >= 3,
            created_at=s.created_at,
        )
        for s in scammers
    ]
