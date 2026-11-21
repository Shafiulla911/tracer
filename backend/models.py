"""
models.py — SQLAlchemy ORM models for the Tracer database.
"""

from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.orm import relationship

from database import Base


class User(Base):
    """
    Represents an authorized Tracer / Sentinel agent or citizen user.
    """

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    full_name = Column(String(100), nullable=False)
    email = Column(String(120), unique=True, nullable=False, index=True)
    phone = Column(String(20), nullable=True)
    password_hash = Column(String(256), nullable=False)
    salt = Column(String(64), nullable=False)
    token = Column(String(128), unique=True, nullable=True, index=True)
    badge = Column(String(60), default="Field Investigator", nullable=False)
    role = Column(String(40), default="Agent", nullable=False)
    avatar_url = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_login = Column(DateTime, nullable=True)

    # Relationships
    reports = relationship("Report", back_populates="user", lazy="selectin")


class Scammer(Base):
    """
    Represents a scammer entity. A scammer can be identified by phone number
    and/or UPI ID. Multiple victims can file reports against the same scammer.
    """

    __tablename__ = "scammers"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    phone_number = Column(String(20), nullable=True, index=True)
    upi_id = Column(String(100), nullable=True, index=True)
    name = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)
    reported_count = Column(Integer, default=1, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    # Relationships
    reports = relationship("Report", back_populates="scammer", lazy="selectin")
    trap_links = relationship("TrapLink", back_populates="scammer", lazy="selectin")


class Report(Base):
    """
    A single victim's report about a scammer.
    """

    __tablename__ = "reports"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    user_id = Column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    scammer_id = Column(
        Integer, ForeignKey("scammers.id", ondelete="CASCADE"), nullable=False
    )
    victim_name = Column(String(100), nullable=False)
    amount_lost = Column(Numeric(10, 2), nullable=True)
    payment_method = Column(String(50), nullable=True)  # UPI, QR, Net Banking, etc.
    utr_number = Column(String(50), nullable=True)  # Transaction/UTR reference number
    scam_category = Column(String(50), nullable=True)  # Task Scam, KYC, Courier, etc.
    risk_level = Column(String(20), default="High", nullable=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationship back to parent scammer and user
    scammer = relationship("Scammer", back_populates="reports")
    user = relationship("User", back_populates="reports")


class TrapLink(Base):
    """
    A unique trap link generated for a specific scammer.
    When the scammer opens the link their IP/location is captured.
    Supports decoy templates (e.g. payment receipt, courier parcel, or warning).
    """

    __tablename__ = "trap_links"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    link_id = Column(String(36), unique=True, nullable=False, index=True)  # UUID v4
    scammer_id = Column(
        Integer, ForeignKey("scammers.id", ondelete="CASCADE"), nullable=False
    )
    template_type = Column(String(50), default="warning", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_clicked = Column(Boolean, default=False, nullable=False)

    # Relationships
    scammer = relationship("Scammer", back_populates="trap_links")
    logs = relationship("TrackLog", back_populates="trap_link", lazy="selectin")


class TrackLog(Base):
    """
    A single click/visit log entry captured when a scammer opens a trap link.
    """

    __tablename__ = "track_logs"

    id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    link_id = Column(
        String(36),
        ForeignKey("trap_links.link_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    ip_address = Column(String(50), nullable=False)
    country = Column(String(100), nullable=True)
    region = Column(String(100), nullable=True)
    city = Column(String(100), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    isp = Column(String(200), nullable=True)
    device_type = Column(String(100), nullable=True)
    browser = Column(String(100), nullable=True)
    os = Column(String(100), nullable=True)
    raw_user_agent = Column(Text, nullable=True)
    clicked_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationship back to the trap link
    trap_link = relationship("TrapLink", back_populates="logs")
