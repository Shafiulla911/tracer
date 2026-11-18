"""
routes/tracking.py — Trap-link generation and click-capture endpoints.
"""

import uuid
from datetime import datetime
from typing import List, Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from user_agents import parse as ua_parse

from pathlib import Path

from config import settings
from database import get_db
from models import Scammer, TrapLink, TrackLog
from schemas import (
    QuickTrapCreate,
    TrapLinkCreate,
    TrapLinkLogsOut,
    TrapLinkOut,
    TrackLogOut,
)

router = APIRouter(tags=["Tracking"])

# Jinja2 template directory (resolved relative to backend directory)
TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "templates"
templates = Jinja2Templates(directory=TEMPLATES_DIR)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_client_ip(request: Request) -> str:
    """
    Extract the real client IP from request headers.
    Handles common proxy/load-balancer headers before falling back to the
    direct connection IP.
    """
    # Prefer X-Forwarded-For (set by most proxies/CDNs)
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        # The header may contain a comma-separated chain; first entry is the client
        return forwarded_for.split(",")[0].strip()

    # Other common headers
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip.strip()

    # Direct connection fallback
    return request.client.host if request.client else "127.0.0.1"


async def _fetch_ip_info(ip: str) -> dict:
    """
    Call ip-api.com to resolve geolocation data for the given IP address.
    Falls back to mock location data for localhost / private IPs.
    """
    # Localhost / private ranges — use mock data for development
    private_prefixes = ("127.", "192.168.", "10.", "172.", "::1", "localhost")
    if any(ip.startswith(p) for p in private_prefixes) or ip == "localhost":
        return settings.MOCK_LOCATION

    url = settings.IP_API_URL.format(ip=ip)
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(url)
            data = resp.json()
            if data.get("status") == "success":
                return data
    except Exception:
        pass  # Network error — fall through to mock data

    return settings.MOCK_LOCATION


def _parse_user_agent(ua_string: Optional[str]) -> dict:
    """
    Parse a User-Agent string into device type, browser, and OS components.
    """
    if not ua_string:
        return {"device_type": "Unknown", "browser": "Unknown", "os": "Unknown"}

    ua = ua_parse(ua_string)

    # Determine high-level device category
    if ua.is_mobile:
        device_type = "Mobile"
    elif ua.is_tablet:
        device_type = "Tablet"
    elif ua.is_pc:
        device_type = "Desktop"
    elif ua.is_bot:
        device_type = "Bot"
    else:
        device_type = "Unknown"

    browser = ua.browser.family or "Unknown"
    os_name = ua.os.family or "Unknown"
    if ua.os.version_string:
        os_name += f" {ua.os.version_string}"

    return {"device_type": device_type, "browser": browser, "os": os_name}


# ---------------------------------------------------------------------------
# POST /api/links/generate — create a trap link
# ---------------------------------------------------------------------------

@router.post(
    "/api/links/generate",
    response_model=TrapLinkOut,
    status_code=status.HTTP_201_CREATED,
    summary="Generate a trap link for a scammer",
)
async def generate_trap_link(
    payload: TrapLinkCreate, db: AsyncSession = Depends(get_db)
):
    """
    Generate a unique trap link for the specified scammer.

    The returned `trap_url` should be shared with (or sent to) the scammer.
    When they open it, their IP address, geolocation, and device details are
    silently captured and stored in `track_logs`.
    """
    # Validate that the scammer exists
    result = await db.execute(select(Scammer).where(Scammer.id == payload.scammer_id))
    scammer: Optional[Scammer] = result.scalars().first()
    if not scammer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Scammer with id={payload.scammer_id} not found.",
        )

    # Generate a UUID-based link identifier
    link_id = str(uuid.uuid4())

    trap_link = TrapLink(
        link_id=link_id,
        scammer_id=payload.scammer_id,
        template_type=payload.template_type or "warning",
        created_at=datetime.utcnow(),
        is_clicked=False,
    )
    db.add(trap_link)
    await db.commit()
    await db.refresh(trap_link)

    trap_url = f"{settings.SERVER_HOST}/track/{link_id}"

    return TrapLinkOut(
        link_id=link_id,
        trap_url=trap_url,
        scammer_id=payload.scammer_id,
        template_type=trap_link.template_type,
        created_at=trap_link.created_at,
    )


# ---------------------------------------------------------------------------
# POST /api/links/quick — instant trap link without filing formal report
# ---------------------------------------------------------------------------

@router.post(
    "/api/links/quick",
    response_model=TrapLinkOut,
    status_code=status.HTTP_201_CREATED,
    summary="Instant Trap Link without full report",
)
async def generate_quick_trap_link(
    payload: QuickTrapCreate, db: AsyncSession = Depends(get_db)
):
    """
    Instantly create or link a scammer record by phone or UPI and generate
    a tracking link with a chosen decoy template in 1 click.
    """
    clean_phone = (payload.phone_number or "").strip() or None
    clean_upi = (payload.upi_id or "").strip() or None

    if not clean_phone and not clean_upi:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="At least one of phone_number or upi_id must be provided for Quick Trap.",
        )

    # Find or create lightweight scammer record
    conditions = []
    if clean_phone:
        conditions.append(Scammer.phone_number == clean_phone)
    if clean_upi:
        conditions.append(Scammer.upi_id == clean_upi)

    from sqlalchemy import or_
    stmt = select(Scammer).where(or_(*conditions))
    result = await db.execute(stmt)
    scammer: Optional[Scammer] = result.scalars().first()

    if not scammer:
        scammer = Scammer(
            phone_number=clean_phone,
            upi_id=clean_upi,
            name=payload.name or "Suspect Contact",
            description="Quick Trap created by user.",
            reported_count=1,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(scammer)
        await db.flush()

    link_id = str(uuid.uuid4())
    template_type = payload.template_type or "payment_receipt"

    trap_link = TrapLink(
        link_id=link_id,
        scammer_id=scammer.id,
        template_type=template_type,
        created_at=datetime.utcnow(),
        is_clicked=False,
    )
    db.add(trap_link)
    await db.commit()
    await db.refresh(trap_link)

    trap_url = f"{settings.SERVER_HOST}/track/{link_id}"

    return TrapLinkOut(
        link_id=link_id,
        trap_url=trap_url,
        scammer_id=scammer.id,
        template_type=template_type,
        created_at=trap_link.created_at,
    )


# ---------------------------------------------------------------------------
# POST /api/links/gps — receive high-accuracy HTML5 GPS coordinates
# ---------------------------------------------------------------------------

@router.post(
    "/api/links/gps",
    summary="Receive optional high-accuracy HTML5 browser GPS coordinates",
    include_in_schema=False,
)
async def update_gps_coordinates(
    payload: dict, db: AsyncSession = Depends(get_db)
):
    link_id = payload.get("link_id")
    lat = payload.get("latitude")
    lon = payload.get("longitude")

    if link_id and lat and lon:
        result = await db.execute(
            select(TrackLog)
            .where(TrackLog.link_id == link_id)
            .order_by(TrackLog.clicked_at.desc())
        )
        log = result.scalars().first()
        if log:
            log.latitude = float(lat)
            log.longitude = float(lon)
            await db.commit()
    return {"status": "ok"}


# ---------------------------------------------------------------------------
# GET /track/{link_id} — PUBLIC endpoint opened by the scammer
# ---------------------------------------------------------------------------

@router.get(
    "/track/{link_id}",
    response_class=HTMLResponse,
    summary="Trap-link click handler — captures scammer IP and renders warning page",
    include_in_schema=False,  # Keep off public docs
)
async def handle_trap_link(
    link_id: str, request: Request, db: AsyncSession = Depends(get_db)
):
    """
    Triggered when the scammer clicks the trap link.

    Steps:
    1. Look up the trap link record.
    2. Capture IP from request headers.
    3. Resolve geolocation via ip-api.com.
    4. Parse User-Agent for device/browser/OS info.
    5. Persist a TrackLog entry.
    6. Mark the TrapLink as clicked.
    7. Render and return the scary HTML warning page.
    """
    # 1. Find the trap link
    result = await db.execute(
        select(TrapLink).where(TrapLink.link_id == link_id)
    )
    trap_link: Optional[TrapLink] = result.scalars().first()

    if not trap_link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Link not found or has expired.",
        )

    # 2. Capture IP address
    ip_address = _get_client_ip(request)

    # 3. Fetch geolocation data
    geo = await _fetch_ip_info(ip_address)

    # 4. Parse User-Agent
    raw_ua = request.headers.get("User-Agent", "")
    ua_info = _parse_user_agent(raw_ua)

    # 5. Persist the track log
    log = TrackLog(
        link_id=link_id,
        ip_address=ip_address,
        country=geo.get("country"),
        region=geo.get("regionName"),
        city=geo.get("city"),
        latitude=geo.get("lat"),
        longitude=geo.get("lon"),
        isp=geo.get("isp"),
        device_type=ua_info["device_type"],
        browser=ua_info["browser"],
        os=ua_info["os"],
        raw_user_agent=raw_ua,
        clicked_at=datetime.utcnow(),
    )
    db.add(log)

    # 6. Mark link as clicked
    trap_link.is_clicked = True

    await db.commit()

    # 7. Build a fake "Case ID" from the first 8 characters of the UUID
    case_id = link_id.replace("-", "").upper()[:8]

    # Select the configured template (decoy payment, courier, or scary warning)
    tmpl_name = "warning.html"
    if trap_link.template_type == "payment_receipt":
        tmpl_name = "decoy_payment.html"
    elif trap_link.template_type == "courier_tracking":
        tmpl_name = "decoy_courier.html"

    # Render template
    return templates.TemplateResponse(
        request=request,
        name=tmpl_name,
        context={
            "link_id": link_id,
            "ip_address": ip_address,
            "country": geo.get("country", "Unknown"),
            "region": geo.get("regionName", "Unknown"),
            "city": geo.get("city", "Unknown"),
            "isp": geo.get("isp", "Unknown"),
            "device_type": ua_info["device_type"],
            "browser": ua_info["browser"],
            "os": ua_info["os"],
            "case_id": case_id,
            "latitude": geo.get("lat"),
            "longitude": geo.get("lon"),
        },
    )


# ---------------------------------------------------------------------------
# GET /api/links/{link_id}/logs — retrieve click logs for a trap link
# ---------------------------------------------------------------------------

@router.get(
    "/api/links/{link_id}/logs",
    response_model=TrapLinkLogsOut,
    summary="Get all tracking logs for a trap link",
)
async def get_link_logs(link_id: str, db: AsyncSession = Depends(get_db)):
    """
    Return all click/visit logs captured for the given trap link.
    Useful for the Flutter app to display where and when the scammer opened
    the link.
    """
    result = await db.execute(
        select(TrapLink).where(TrapLink.link_id == link_id)
    )
    trap_link: Optional[TrapLink] = result.scalars().first()

    if not trap_link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Trap link '{link_id}' not found.",
        )

    logs_result = await db.execute(
        select(TrackLog)
        .where(TrackLog.link_id == link_id)
        .order_by(TrackLog.clicked_at.desc())
    )
    logs: List[TrackLog] = logs_result.scalars().all()

    return TrapLinkLogsOut(
        link_id=trap_link.link_id,
        scammer_id=trap_link.scammer_id,
        is_clicked=trap_link.is_clicked,
        created_at=trap_link.created_at,
        logs=[
            TrackLogOut(
                id=l.id,
                link_id=l.link_id,
                ip_address=l.ip_address,
                country=l.country,
                region=l.region,
                city=l.city,
                latitude=l.latitude,
                longitude=l.longitude,
                isp=l.isp,
                device_type=l.device_type,
                browser=l.browser,
                os=l.os,
                raw_user_agent=l.raw_user_agent,
                clicked_at=l.clicked_at,
            )
            for l in logs
        ],
    )
