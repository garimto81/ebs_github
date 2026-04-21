"""Series / Event / Flight routers — API-01 §5.4~5.6."""
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel  # kept for backward-compat import
from sqlmodel import Session

from src.models.base import EbsBaseModel

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    ClockAdjust,
    ClockState,
    EventCreate,
    EventResponse,
    EventUpdate,
    FlightCreate,
    FlightResponse,
    FlightUpdate,
    SeriesCreate,
    SeriesResponse,
    SeriesUpdate,
)
from src.models.user import User
from src.services.clock_service import (
    adjust_clock,
    get_clock_state,
    pause_clock,
    restart_level,
    resume_clock,
    start_clock,
)
from src.services.series_service import (
    cancel_flight,
    complete_flight,
    create_event,
    create_flight,
    create_series,
    delete_event,
    delete_flight,
    delete_series,
    get_event,
    get_flight,
    get_series,
    list_all_events,
    list_all_flights,
    list_events_by_series,
    list_flights_by_event,
    list_series,
    update_event,
    update_flight,
    update_series,
)

router = APIRouter(prefix="/api/v1", tags=["series"])


# ── Series ──────────────────────────────────────────


@router.get("/series")
def api_list_series(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_series(db, skip, limit)
    return ApiResponse(
        data=[SeriesResponse.model_validate(s, from_attributes=True) for s in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/series", status_code=201)
def api_create_series(
    body: SeriesCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    s = create_series(body, db)
    return ApiResponse(data=SeriesResponse.model_validate(s, from_attributes=True))


@router.get("/series/{series_id}")
def api_get_series(
    series_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    s = get_series(series_id, db)
    return ApiResponse(data=SeriesResponse.model_validate(s, from_attributes=True))


@router.put("/series/{series_id}")
def api_update_series(
    series_id: int,
    body: SeriesUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    s = update_series(series_id, body, db)
    return ApiResponse(data=SeriesResponse.model_validate(s, from_attributes=True))


@router.delete("/series/{series_id}")
def api_delete_series(
    series_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_series(series_id, db)
    return ApiResponse(data={"deleted": True})


# ── Events ──────────────────────────────────────────


@router.get("/series/{series_id}/events")
def api_list_events(
    series_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_events_by_series(series_id, db, skip, limit)
    return ApiResponse(
        data=[EventResponse.model_validate(e, from_attributes=True) for e in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/series/{series_id}/events", status_code=201)
def api_create_event(
    series_id: int,
    body: EventCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    # Override series_id from path
    body.series_id = series_id
    e = create_event(body, db)
    return ApiResponse(data=EventResponse.model_validate(e, from_attributes=True))


@router.get("/events")
def api_list_all_events(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    series_id: int | None = Query(None),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_all_events(db, skip, limit, series_id)
    return ApiResponse(
        data=[EventResponse.model_validate(e, from_attributes=True) for e in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/events", status_code=201)
def api_create_event_flat(
    body: EventCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L263 — flat POST. `series_id` required in body."""
    e = create_event(body, db)
    return ApiResponse(data=EventResponse.model_validate(e, from_attributes=True))


@router.get("/events/{event_id}")
def api_get_event(
    event_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    e = get_event(event_id, db)
    return ApiResponse(data=EventResponse.model_validate(e, from_attributes=True))


@router.put("/events/{event_id}")
def api_update_event(
    event_id: int,
    body: EventUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    e = update_event(event_id, body, db)
    return ApiResponse(data=EventResponse.model_validate(e, from_attributes=True))


@router.delete("/events/{event_id}")
def api_delete_event(
    event_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_event(event_id, db)
    return ApiResponse(data={"deleted": True})


# ── Flights ─────────────────────────────────────────


@router.get("/flights")
def api_list_flights_flat(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    event_id: int | None = Query(None),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L302 — flat list with optional ?event_id= filter."""
    items, total = list_all_flights(db, skip, limit, event_id)
    return ApiResponse(
        data=[FlightResponse.model_validate(f, from_attributes=True) for f in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/flights", status_code=201)
def api_create_flight_flat(
    body: FlightCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L304 — flat POST. `event_id` required in body."""
    f = create_flight(body, db)
    return ApiResponse(data=FlightResponse.model_validate(f, from_attributes=True))


@router.get("/events/{event_id}/flights")
def api_list_flights(
    event_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deprecated (nested) alias. Prefer GET /flights?event_id=."""
    items, total = list_flights_by_event(event_id, db, skip, limit)
    return ApiResponse(
        data=[FlightResponse.model_validate(f, from_attributes=True) for f in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/events/{event_id}/flights", status_code=201)
def api_create_flight(
    event_id: int,
    body: FlightCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Deprecated (nested) alias. Prefer POST /flights with event_id in body."""
    # Override event_id from path
    body.event_id = event_id
    f = create_flight(body, db)
    return ApiResponse(data=FlightResponse.model_validate(f, from_attributes=True))


@router.get("/flights/{flight_id}")
def api_get_flight(
    flight_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    f = get_flight(flight_id, db)
    return ApiResponse(data=FlightResponse.model_validate(f, from_attributes=True))


@router.put("/flights/{flight_id}")
def api_update_flight(
    flight_id: int,
    body: FlightUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    f = update_flight(flight_id, body, db)
    return ApiResponse(data=FlightResponse.model_validate(f, from_attributes=True))


@router.delete("/flights/{flight_id}")
def api_delete_flight(
    flight_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_flight(flight_id, db)
    return ApiResponse(data={"deleted": True})


# ── CCR-050 Flight lifecycle transitions ──────────────


class FlightCompleteRequest(EbsBaseModel):
    final_results: dict | None = None


class FlightCancelRequest(EbsBaseModel):
    reason: str | None = None
    refund_policy: str | None = None


@router.put("/flights/{flight_id}/complete")
def api_complete_flight(
    flight_id: int,
    body: FlightCompleteRequest,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L306 — Running → Completed (CCR-050)."""
    f = complete_flight(flight_id, body.final_results, db)
    return ApiResponse(data=FlightResponse.model_validate(f, from_attributes=True))


@router.put("/flights/{flight_id}/cancel")
def api_cancel_flight(
    flight_id: int,
    body: FlightCancelRequest,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L307 — {Created,Announce,Registering,Running} → Canceled."""
    f = cancel_flight(flight_id, body.reason, db)
    return ApiResponse(data=FlightResponse.model_validate(f, from_attributes=True))


# ── Clock ──────────────────────────────────────────────


@router.get("/flights/{flight_id}/clock")
def api_get_clock(
    flight_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    state = get_clock_state(flight_id, db)
    return ApiResponse(data=ClockState(**state))


@router.post("/flights/{flight_id}/clock/start")
def api_start_clock(
    flight_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    state = start_clock(flight_id, db)
    return ApiResponse(data=ClockState(**state))


@router.post("/flights/{flight_id}/clock/pause")
def api_pause_clock(
    flight_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    state = pause_clock(flight_id, db)
    return ApiResponse(data=ClockState(**state))


@router.post("/flights/{flight_id}/clock/resume")
def api_resume_clock(
    flight_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    state = resume_clock(flight_id, db)
    return ApiResponse(data=ClockState(**state))


@router.post("/flights/{flight_id}/clock/restart")
def api_restart_clock(
    flight_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    state = restart_level(flight_id, db)
    return ApiResponse(data=ClockState(**state))


@router.put("/flights/{flight_id}/clock")
def api_adjust_clock(
    flight_id: int,
    body: ClockAdjust,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    state = adjust_clock(flight_id, body.level_diff, body.time_diff, db)
    return ApiResponse(data=ClockState(**state))


# ── CCR-050 Clock extensions ─────────────────────


class ClockDetailRequest(EbsBaseModel):
    theme: str | None = None
    announcement: str | None = None
    group_name: str | None = None


class ClockAdjustStackRequest(EbsBaseModel):
    average_stack: int
    reason: str | None = None


@router.put("/flights/{flight_id}/clock/detail")
def api_clock_detail(
    flight_id: int,
    body: ClockDetailRequest,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT L342 — CCR-050 clock theme/announcement/group_name update.

    Phase 1: accepts and acknowledges; persistence of theme/announcement is
    tracked in Backlog B-066 (requires Clock model extension).
    """
    _ = get_flight(flight_id, db)
    return ApiResponse(data={"flight_id": flight_id, **body.model_dump(exclude_none=True)})


@router.put("/flights/{flight_id}/clock/reload-page")
def api_clock_reload_page(
    flight_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT L343 — CCR-050 dashboard reload signal.

    Phase 1: returns ack. Real WebSocket broadcast (`clock_reload_requested`)
    is added with the Lobby event publisher work in Backlog B-066.
    """
    _ = get_flight(flight_id, db)
    return ApiResponse(data={"flight_id": flight_id, "reload_requested": True})


@router.put("/flights/{flight_id}/clock/adjust-stack")
def api_clock_adjust_stack(
    flight_id: int,
    body: ClockAdjustStackRequest,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT L344 — CCR-050 average chip stack manual adjustment."""
    _ = get_flight(flight_id, db)
    if body.average_stack < 0:
        from fastapi import HTTPException, status as fa_status
        raise HTTPException(
            status_code=fa_status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_VALUE", "message": "average_stack must be >= 0"},
        )
    return ApiResponse(data={
        "flight_id": flight_id,
        "averageStack": body.average_stack,
        "reason": body.reason,
    })
