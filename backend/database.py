"""
database.py — SQLAlchemy async engine setup and session factory.
"""

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from config import settings

# Replace the sync pymysql driver with the async aiomysql driver for AsyncEngine.
# We keep pymysql in requirements for migrations/sync fallback but use
# aiomysql (bundled with SQLAlchemy async support) at runtime.
ASYNC_DATABASE_URL = settings.DATABASE_URL.replace(
    "mysql+pymysql://", "mysql+aiomysql://"
)

# Create the async engine
engine = create_async_engine(
    ASYNC_DATABASE_URL,
    echo=False,          # Set True to log SQL queries during development
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=3600,   # Recycle connections every hour
)

# Session factory bound to the async engine
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """Base class for all ORM models."""
    pass


async def get_db() -> AsyncSession:
    """
    FastAPI dependency that provides a database session per request.
    Automatically closes the session when the request is done.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def create_tables():
    """
    Create all tables defined in models if they do not exist.
    Called once at application startup.
    """
    # Import models here to ensure they are registered with Base
    import models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
