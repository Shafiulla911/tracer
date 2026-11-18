"""
routes/reports.py — Endpoints for creating and retrieving scammer reports.
"""

from datetime import datetime
from typing import Optional
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import Report, Scammer, TrackLog, TrapLink
from schemas import (
    AIAnalysisRequest,
    AIAnalysisResponse,
    ReportCreate,
    ReportOut,
    ScammerOut,
)

router = APIRouter(prefix="/api/reports", tags=["Reports"])
TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "templates"
templates = Jinja2Templates(directory=TEMPLATES_DIR)


# ---------------------------------------------------------------------------
# Helper: find or create a scammer record
# ---------------------------------------------------------------------------

async def _get_or_create_scammer(
    db: AsyncSession,
    phone_number: Optional[str],
    upi_id: Optional[str],
    name: Optional[str],
    description: str,
) -> Scammer:
    """
    Look up an existing scammer by phone number or UPI ID.
    If found, increment their reported_count and update description if blank.
    If not found, create a new scammer record.
    """
    # Build a flexible query — match on either identifier if provided
    stmt = select(Scammer)
    conditions = []
    if phone_number:
        conditions.append(Scammer.phone_number == phone_number)
    if upi_id:
        conditions.append(Scammer.upi_id == upi_id)

    if conditions:
        from sqlalchemy import or_
        stmt = stmt.where(or_(*conditions))
        result = await db.execute(stmt)
        existing: Optional[Scammer] = result.scalars().first()
    else:
        existing = None

    if existing:
        # Update the existing record
        existing.reported_count += 1
        existing.updated_at = datetime.utcnow()
        # Fill in missing fields from the new report
        if not existing.name and name:
            existing.name = name
        if not existing.description and description:
            existing.description = description
        return existing

    # Create a brand new scammer
    scammer = Scammer(
        phone_number=phone_number,
        upi_id=upi_id,
        name=name,
        description=description,
        reported_count=1,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(scammer)
    return scammer


# ---------------------------------------------------------------------------
# POST /api/reports — file a new report
# ---------------------------------------------------------------------------

@router.post(
    "",
    response_model=ReportOut,
    status_code=status.HTTP_201_CREATED,
    summary="Report a scammer",
)
async def create_report(payload: ReportCreate, db: AsyncSession = Depends(get_db)):
    """
    Create a report against a scammer.

    - If the scammer (matched by phone_number or upi_id) already exists in the
      database, the existing record is reused and its `reported_count` is
      incremented.
    - Otherwise a new scammer record is created.
    - A corresponding `reports` row is always inserted.
    """
    if not payload.phone_number and not payload.upi_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="At least one of phone_number or upi_id must be provided.",
        )

    # Upsert scammer
    scammer = await _get_or_create_scammer(
        db,
        phone_number=payload.phone_number,
        upi_id=payload.upi_id,
        name=payload.name,
        description=payload.description,
    )
    await db.flush()  # Assign scammer.id without committing yet

    # Create the victim's report
    report = Report(
        scammer_id=scammer.id,
        victim_name=payload.victim_name,
        amount_lost=payload.amount_lost,
        payment_method=payload.payment_method,
        utr_number=payload.utr_number,
        scam_category=payload.scam_category,
        risk_level=payload.risk_level or "High",
        description=payload.description,
        created_at=datetime.utcnow(),
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)

    return ReportOut(
        id=report.id,
        scammer_id=scammer.id,
        message="Report submitted successfully. Thank you for helping us fight scammers.",
    )


# ---------------------------------------------------------------------------
# GET /api/reports/{scammer_id}/docket — export police complaint document
# ---------------------------------------------------------------------------

@router.get(
    "/{scammer_id}/docket",
    response_class=HTMLResponse,
    summary="Generate Cyber Crime Police Complaint & Evidence Docket",
)
async def generate_police_docket(
    scammer_id: int, request: Request, db: AsyncSession = Depends(get_db)
):
    """
    Generate an official, printable legal evidence docket for police reporting
    and National Cyber Crime Reporting Portal (1930 / cybercrime.gov.in).
    """
    result = await db.execute(select(Scammer).where(Scammer.id == scammer_id))
    scammer: Optional[Scammer] = result.scalars().first()

    if not scammer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No scammer found with id={scammer_id}.",
        )

    logs_result = await db.execute(
        select(TrackLog)
        .join(TrapLink, TrackLog.link_id == TrapLink.link_id)
        .where(TrapLink.scammer_id == scammer_id)
        .order_by(TrackLog.clicked_at.desc())
    )
    track_logs = logs_result.scalars().all()

    case_id = f"{scammer.id:04d}-{int(datetime.utcnow().timestamp()) % 100000}"

    return templates.TemplateResponse(
        request=request,
        name="docket_report.html",
        context={
            "scammer": scammer,
            "track_logs": track_logs,
            "case_id": case_id,
            "cur_time": datetime.utcnow().strftime("%d %b %Y, %I:%M %p UTC"),
        },
    )


# ---------------------------------------------------------------------------
# POST /api/reports/analyze — AI Scam Pattern Classifier
# ---------------------------------------------------------------------------

@router.post(
    "/analyze",
    response_model=AIAnalysisResponse,
    summary="AI Scam Pattern & Risk Level Analyzer",
)
async def analyze_scam_pattern(payload: AIAnalysisRequest):
    """
    Intelligently inspects victim descriptions or suspicious chat messages
    to detect category, threat level, red flags, and emergency mitigation advice.
    """
    text = payload.text.lower()

    # Rule-based pattern matching (extensible to external LLM calls)
    category = "General Cyber Fraud"
    risk = "Moderate"
    confidence = 0.85
    indicators = []
    actions = [
        "Do not click any unknown links or approve payment requests.",
        "Report the transaction to your bank immediately to freeze the account.",
        "Dial 1930 (National Cyber Crime Helpline) within the golden hour.",
    ]

    if any(k in text for k in ["electric", "power", "light", "bill", "disconnect"]):
        category = "Electricity Bill Disconnection Scam"
        risk = "High"
        confidence = 0.94
        indicators.extend([
            "Threat of immediate power disconnection at specific time",
            "Urging call to personal mobile instead of official DISCOM board",
            "Demand to install remote access apps (AnyDesk, QuickSupport, RustDesk)",
        ])
        actions.insert(0, "Never install APKs or screen-sharing tools sent via SMS/WhatsApp.")

    elif any(k in text for k in ["courier", "parcel", "custom", "drugs", "police", "arrest", "cbi"]):
        category = "Digital Arrest & Courier Drugs Scam"
        risk = "Severe"
        confidence = 0.96
        indicators.extend([
            "Impersonation of customs, FedEx/DHL, or police officials",
            "Allegation of illicit parcels or financial crime under your Aadhaar",
            "Coercion into video calls under false 'Digital Arrest'",
        ])
        actions.insert(0, "Law enforcement NEVER conducts arrests or takes statements via WhatsApp/Skype.")

    elif any(k in text for k in ["like", "youtube", "task", "telegram", "crypto", "rating", "part time"]):
        category = "Work-from-Home & Task-Based Fraud"
        risk = "High"
        confidence = 0.92
        indicators.extend([
            "Initial payout of ₹150 - ₹500 to gain trust",
            "Migration to Telegram group with fake earning screenshots",
            "Demand for 'prepaid investment tasks' that cannot be withdrawn",
        ])
        actions.insert(0, "Refuse further transfers; any deposited balance is unrecoverable without police hold.")

    elif any(k in text for k in ["kyc", "pan", "aadhar", "sim", "block", "lottery", "winner"]):
        category = "KYC & Identity Phishing"
        risk = "High"
        confidence = 0.89
        indicators.extend([
            "Urgent deadline claiming SIM or bank account will be blocked",
            "Fake verification link mimicking bank/telecom portals",
        ])

    return AIAnalysisResponse(
        scam_category=category,
        risk_level=risk,
        confidence=confidence,
        indicators=indicators or ["Suspicious payment or personal detail solicitation"],
        immediate_actions=actions,
        helpline="1930 (National Cyber Crime Helpline)",
    )


# ---------------------------------------------------------------------------
# GET /api/reports/{scammer_id} — full scammer profile
# ---------------------------------------------------------------------------

@router.get(
    "/{scammer_id}",
    response_model=ScammerOut,
    summary="Get scammer details with all reports",
)
async def get_scammer_reports(scammer_id: int, db: AsyncSession = Depends(get_db)):
    """
    Retrieve a scammer's profile including all victim reports filed against them
    and all track logs captured by trap links generated for them.
    """
    result = await db.execute(select(Scammer).where(Scammer.id == scammer_id))
    scammer: Optional[Scammer] = result.scalars().first()

    if not scammer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No scammer found with id={scammer_id}.",
        )

    logs_result = await db.execute(
        select(TrackLog)
        .join(TrapLink, TrackLog.link_id == TrapLink.link_id)
        .where(TrapLink.scammer_id == scammer_id)
        .order_by(TrackLog.clicked_at.desc())
    )
    track_logs = logs_result.scalars().all()

    return ScammerOut(
        id=scammer.id,
        phone_number=scammer.phone_number,
        upi_id=scammer.upi_id,
        name=scammer.name,
        description=scammer.description,
        reported_count=scammer.reported_count,
        created_at=scammer.created_at,
        updated_at=scammer.updated_at,
        reports=scammer.reports,
        track_logs=track_logs,
    )
