"""
schemas.py — Pydantic schemas for request validation and response serialisation.
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Report schemas
# ---------------------------------------------------------------------------

class ReportCreate(BaseModel):
    """Payload sent by a victim to report a scammer."""

    phone_number: Optional[str] = Field(None, max_length=20, example="+919876543210")
    upi_id: Optional[str] = Field(None, max_length=100, example="scammer@upi")
    name: Optional[str] = Field(None, max_length=100, example="Fake Ramesh")
    description: str = Field(..., example="Pretended to be a bank officer and asked for OTP")
    victim_name: str = Field(..., max_length=100, example="John Doe")
    amount_lost: Optional[float] = Field(None, example=5000.00)
    payment_method: Optional[str] = Field(None, max_length=50, example="UPI")
    utr_number: Optional[str] = Field(None, max_length=50, example="321456987412")
    scam_category: Optional[str] = Field(None, max_length=50, example="Electricity Bill Scam")
    risk_level: Optional[str] = Field("High", max_length=20, example="Severe")


class ReportOut(BaseModel):
    """Minimal response returned after creating a report."""

    id: int
    scammer_id: int
    message: str

    class Config:
        from_attributes = True


class ReportDetail(BaseModel):
    """Full details of a single report."""

    id: int
    scammer_id: int
    victim_name: str
    amount_lost: Optional[float] = None
    payment_method: Optional[str] = None
    utr_number: Optional[str] = None
    scam_category: Optional[str] = None
    risk_level: Optional[str] = None
    description: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ---------------------------------------------------------------------------
# Track-log schemas
# ---------------------------------------------------------------------------

class TrackLogOut(BaseModel):
    """Details of a single click captured from a trap link."""

    id: int
    link_id: str
    ip_address: str
    country: Optional[str] = None
    region: Optional[str] = None
    city: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    isp: Optional[str] = None
    device_type: Optional[str] = None
    browser: Optional[str] = None
    os: Optional[str] = None
    raw_user_agent: Optional[str] = None
    clicked_at: datetime

    class Config:
        from_attributes = True


# ---------------------------------------------------------------------------
# Scammer schemas
# ---------------------------------------------------------------------------

class ScammerOut(BaseModel):
    """Full scammer profile including all associated reports and track logs."""

    id: int
    phone_number: Optional[str] = None
    upi_id: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    reported_count: int
    created_at: datetime
    updated_at: datetime
    reports: List[ReportDetail] = []
    track_logs: List[TrackLogOut] = []

    class Config:
        from_attributes = True


class ScammerSearchResult(BaseModel):
    """Lightweight scammer summary used in search results."""

    id: int
    phone_number: Optional[str] = None
    upi_id: Optional[str] = None
    name: Optional[str] = None
    reported_count: int
    is_dangerous: bool  # True when reported_count >= 3
    created_at: datetime

    class Config:
        from_attributes = True


# ---------------------------------------------------------------------------
# Trap-link schemas
# ---------------------------------------------------------------------------

class TrapLinkCreate(BaseModel):
    """Payload to generate a trap link for a scammer."""

    scammer_id: int = Field(..., example=1)
    template_type: Optional[str] = Field("warning", example="payment_receipt")


class QuickTrapCreate(BaseModel):
    """Payload to instantly generate a trap link from phone or UPI."""

    phone_number: Optional[str] = Field(None, max_length=20, example="+919876543210")
    upi_id: Optional[str] = Field(None, max_length=100, example="fraud@upi")
    name: Optional[str] = Field(None, max_length=100, example="Suspicious Caller")
    template_type: Optional[str] = Field("payment_receipt", example="payment_receipt")


class TrapLinkOut(BaseModel):
    """Response after generating a trap link."""

    link_id: str
    trap_url: str
    scammer_id: int
    template_type: str = "warning"
    created_at: datetime

    class Config:
        from_attributes = True


class AIAnalysisRequest(BaseModel):
    """Request payload for AI scam analysis."""

    text: str = Field(..., example="Sir your electricity will be disconnected tonight at 9:30 PM call 9876543210")


class AIAnalysisResponse(BaseModel):
    """Response returned by the AI scam analyzer."""

    scam_category: str
    risk_level: str  # Low, Moderate, High, Severe
    confidence: float
    indicators: List[str]
    immediate_actions: List[str]
    helpline: str = "1930 (National Cyber Crime Reporting Portal)"


class TrapLinkLogsOut(BaseModel):
    """All tracking logs associated with a trap link."""

    link_id: str
    scammer_id: int
    is_clicked: bool
    created_at: datetime
    logs: List[TrackLogOut] = []

    class Config:
        from_attributes = True


# ---------------------------------------------------------------------------
# Stats schema
# ---------------------------------------------------------------------------

class StatsOut(BaseModel):
    """Platform-wide statistics."""

    total_scammers: int
    total_reports: int
    total_traced: int  # number of trap links that have been clicked at least once


# ---------------------------------------------------------------------------
# Auth & User schemas
# ---------------------------------------------------------------------------

class UserCreate(BaseModel):
    full_name: str = Field(..., max_length=100, example="Alex Mercer")
    email: str = Field(..., max_length=120, example="agent.alex@sentinel.org")
    phone: Optional[str] = Field(None, max_length=20, example="+919876543210")
    password: str = Field(..., min_length=6, example="SentinelPass@123")


class UserLogin(BaseModel):
    email: str = Field(..., example="agent.alex@sentinel.org")
    password: str = Field(..., example="SentinelPass@123")


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    badge: Optional[str] = None


class UserOut(BaseModel):
    id: int
    full_name: str
    email: str
    phone: Optional[str] = None
    badge: str
    role: str
    avatar_url: Optional[str] = None
    created_at: datetime
    reports_count: int = 0
    traps_count: int = 0
    hits_count: int = 0

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    token: str
    user: UserOut
    message: str = "Authenticated successfully"

