"""
main.py — FastAPI application entry point for the Tracer backend.
"""

import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from contextlib import asynccontextmanager

from database import create_tables, get_db
from models import Report, Scammer, TrapLink
from routes import reports as reports_router
from routes import search as search_router
from routes import tracking as tracking_router
from schemas import StatsOut

# ---------------------------------------------------------------------------
# Lifespan — startup & shutdown events
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create all database tables on first run (idempotent)."""
    try:
        await create_tables()
    except Exception as e:
        print(f"Warning: Database initialization deferred or failed: {e}")
    yield

# ---------------------------------------------------------------------------
# Application factory
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Tracer API",
    description=(
        "Cyber security scam reporting and tracking platform. "
        "Report scammers, generate trap links, and trace fraudsters."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# ---------------------------------------------------------------------------
# CORS — allow all origins during development
# ---------------------------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Static files (CSS for the warning page)
# ---------------------------------------------------------------------------

app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")

# ---------------------------------------------------------------------------
# Include routers
# ---------------------------------------------------------------------------

app.include_router(reports_router.router)
app.include_router(search_router.router)
app.include_router(tracking_router.router)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/", tags=["Health"], summary="Health check")
async def root():
    return {"status": "ok", "message": "Tracer API is running 🛡️"}


# ---------------------------------------------------------------------------
# GET /api/stats — platform-wide statistics
# ---------------------------------------------------------------------------

@app.get("/api/stats", response_model=StatsOut, tags=["Stats"], summary="Platform statistics")
async def get_stats(db: AsyncSession = Depends(get_db)):
    """
    Return aggregate platform statistics:
    - Total unique scammers in the database
    - Total reports submitted
    - Total trap links that have been clicked (i.e. scammers traced)
    """
    total_scammers_result = await db.execute(select(func.count()).select_from(Scammer))
    total_scammers = total_scammers_result.scalar() or 0

    total_reports_result = await db.execute(select(func.count()).select_from(Report))
    total_reports = total_reports_result.scalar() or 0

    total_traced_result = await db.execute(
        select(func.count()).select_from(TrapLink).where(TrapLink.is_clicked == True)
    )
    total_traced = total_traced_result.scalar() or 0

    return StatsOut(
        total_scammers=total_scammers,
        total_reports=total_reports,
        total_traced=total_traced,
    )


# ---------------------------------------------------------------------------
# Dev entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
