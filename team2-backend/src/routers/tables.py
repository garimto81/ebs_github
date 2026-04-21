"""Tables & Seats router — API-01 §5.7~5.8."""
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    RebalanceRequest,
    SeatResponse,
    SeatUpdate,
    TableCreate,
    TableResponse,
    TableUpdate,
)
from src.models.user import User
from src.services.table_service import (
    assign_seat,
    create_table,
    delete_table,
    get_table,
    get_table_seats,
    list_all_tables,
    list_tables,
    rebalance_tables,
    update_seat_status,
    update_table,
)

# SG-008-b11 결정 (2026-04-20): launch_cc() 서비스는 삭제하지 않음 — 다른 내부 소비자 가능성.
# 엔드포인트만 삭제. deep-link 패턴 전환은 team1 (Lobby) + team4 (CC protocol handler) 소관.

router = APIRouter(prefix="/api/v1", tags=["tables"])


# ── Tables (static paths first) ────────────────────


@router.post("/tables/rebalance")
def api_rebalance(
    body: RebalanceRequest,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    result = rebalance_tables(
        body.event_flight_id, body.strategy, body.target_players_per_table, body.dry_run, db
    )
    return ApiResponse(data=result)


@router.get("/tables")
def api_list_tables_flat(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    flight_id: int | None = Query(None),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L402 — flat list with optional ?flight_id= filter."""
    items, total = list_all_tables(db, skip, limit, flight_id)
    return ApiResponse(
        data=[TableResponse.model_validate(t, from_attributes=True) for t in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/tables", status_code=201)
def api_create_table_flat(
    body: TableCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L404 — flat POST. `event_flight_id` required in body."""
    from fastapi import HTTPException, status as fa_status
    if body.event_flight_id is None:
        raise HTTPException(
            status_code=fa_status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "FIELD_REQUIRED", "message": "event_flight_id required for flat POST /tables"},
        )
    t = create_table(body.event_flight_id, body, db)
    return ApiResponse(data=TableResponse.model_validate(t, from_attributes=True))


@router.get("/flights/{flight_id}/tables")
def api_list_tables(
    flight_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deprecated (nested) alias. Prefer GET /tables?flight_id=."""
    items, total = list_tables(flight_id, db, skip, limit)
    return ApiResponse(
        data=[TableResponse.model_validate(t, from_attributes=True) for t in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/flights/{flight_id}/tables", status_code=201)
def api_create_table(
    flight_id: int,
    body: TableCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Deprecated (nested) alias. Prefer POST /tables with event_flight_id in body."""
    t = create_table(flight_id, body, db)
    return ApiResponse(data=TableResponse.model_validate(t, from_attributes=True))


@router.get("/tables/{table_id}")
def api_get_table(
    table_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    t = get_table(table_id, db)
    return ApiResponse(data=TableResponse.model_validate(t, from_attributes=True))


@router.put("/tables/{table_id}")
def api_update_table(
    table_id: int,
    body: TableUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    t = update_table(table_id, body, db)
    return ApiResponse(data=TableResponse.model_validate(t, from_attributes=True))


@router.delete("/tables/{table_id}")
def api_delete_table(
    table_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_table(table_id, db)
    return ApiResponse(data={"deleted": True})


# SG-008-b11 결정 (2026-04-20): `POST /tables/{table_id}/launch-cc` 옵션 1 채택 — deep-link 전환 + 엔드포인트 삭제.
#   WSOP LIVE Staff App §Launch 는 deep-link (`wsop-staff://table/{id}`) 패턴 — EBS 도 동일하게 정렬.
#   Lobby: `window.location = ebs-cc://table/${id}?token=${short_lived_token}` (team1 Backlog)
#   CC: Flutter `app_links` 패키지로 OS protocol handler 등록 (team4 Backlog)


@router.get("/tables/{table_id}/status")
def api_get_table_status(
    table_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L408 — real-time table status."""
    t = get_table(table_id, db)
    seats = get_table_seats(table_id, db)
    occupied = sum(1 for s in seats if s.status != "empty")
    return ApiResponse(data={
        "tableId": t.table_id,
        "status": t.status,
        "occupiedSeats": occupied,
        "maxPlayers": t.max_players,
    })


# ── Seats ───────────────────────────────────────────


@router.get("/tables/{table_id}/seats")
def api_get_seats(
    table_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    seats = get_table_seats(table_id, db)
    return ApiResponse(
        data=[SeatResponse.model_validate(s, from_attributes=True) for s in seats],
    )


@router.put("/tables/{table_id}/seats/{seat_no}")
def api_update_seat(
    table_id: int,
    seat_no: int,
    body: SeatUpdate,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a seat — assign player, change status, or update chip count.

    Logic:
    - If player_id is provided and seat is empty → assign (empty→new)
    - If status is provided → transition validation
    - If player_id is None and status is "empty" → vacate
    """
    # If assigning a player
    if body.player_id is not None and body.status is None:
        seat = assign_seat(table_id, seat_no, body.player_id, db, body.chip_count or 0)
        return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))

    # If changing status
    if body.status is not None:
        # Special: assigning with explicit status (player_id + status)
        if body.player_id is not None:
            seat = assign_seat(table_id, seat_no, body.player_id, db, body.chip_count or 0)
            # If requested status is not 'new', do a follow-up transition
            if body.status != "new":
                seat = update_seat_status(table_id, seat_no, body.status, db)
            return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))
        else:
            seat = update_seat_status(table_id, seat_no, body.status, db)
            return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))

    # Nothing meaningful to update
    from src.services.table_service import _get_seat
    seat = _get_seat(table_id, seat_no, db)
    return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))
