"""Tables & Seats router — API-01 §5.7~5.8."""
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    SeatResponse,
    SeatUpdate,
    TableCreate,
    TableResponse,
)
from src.models.user import User
from src.services.table_service import (
    assign_seat,
    create_table,
    get_table,
    get_table_seats,
    list_tables,
    update_seat_status,
)

router = APIRouter(prefix="/api/v1", tags=["tables"])


# ── Tables ──────────────────────────────────────────


@router.get("/flights/{flight_id}/tables")
def api_list_tables(
    flight_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
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
