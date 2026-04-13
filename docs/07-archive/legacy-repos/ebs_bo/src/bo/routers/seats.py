import random

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Table, TableSeat, User
from bo.db.models.base import utcnow
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.seat import SeatRead, SeatUpdate
from bo.services.audit_service import record_audit

router = APIRouter(prefix="/tables/{table_id}/seats", tags=["Seats"])


@router.get("", response_model=ApiResponse[list[SeatRead]])
def list_seats(
    table_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    seats = session.exec(
        select(TableSeat)
        .where(TableSeat.table_id == table_id)
        .order_by(TableSeat.seat_no)
    ).all()
    return ApiResponse(data=seats)


@router.put("/{seat_no}", response_model=ApiResponse[SeatRead])
def update_seat(
    table_id: int,
    seat_no: int,
    body: SeatUpdate,
    _: User = Depends(require_role("admin", "operator")),
    session: Session = Depends(get_session),
):
    seat = session.exec(
        select(TableSeat).where(
            TableSeat.table_id == table_id,
            TableSeat.seat_no == seat_no,
        )
    ).first()
    if not seat:
        raise HTTPException(status_code=404, detail=f"Seat {seat_no} not found")
    for key, value in body.model_dump(exclude_unset=True).items():
        if hasattr(seat, key):
            setattr(seat, key, value)
    session.add(seat)
    session.commit()
    session.refresh(seat)
    return ApiResponse(data=seat)


@router.post("/clear", response_model=ApiResponse[dict])
def clear_seats(
    table_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    """Admin: Clear all seat assignments for a table (vacate all seats)."""
    table = session.get(Table, table_id)
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")

    seats = session.exec(
        select(TableSeat).where(TableSeat.table_id == table_id)
    ).all()
    cleared = 0
    for seat in seats:
        if seat.player_id is not None:
            seat.player_id = None
            seat.player_name = None
            seat.wsop_id = None
            seat.nationality = None
            seat.country_code = None
            seat.chip_count = 0
            seat.profile_image = None
            seat.status = "vacant"
            seat.updated_at = utcnow()
            session.add(seat)
            cleared += 1
    session.commit()
    record_audit(session, user_id=current_user.user_id, action="seat.clear", entity_type="table", entity_id=table_id)
    return ApiResponse(data={"table_id": table_id, "cleared": cleared})


@router.post("/random", response_model=ApiResponse[list[SeatRead]])
def random_seat_assignment(
    table_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    """Admin: Randomly reassign all currently seated players to seats."""
    table = session.get(Table, table_id)
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")

    seats = session.exec(
        select(TableSeat)
        .where(TableSeat.table_id == table_id)
        .order_by(TableSeat.seat_no)
    ).all()

    # Collect occupied player data
    players_info = []
    for seat in seats:
        if seat.player_id is not None:
            players_info.append({
                "player_id": seat.player_id,
                "player_name": seat.player_name,
                "wsop_id": seat.wsop_id,
                "nationality": seat.nationality,
                "country_code": seat.country_code,
                "chip_count": seat.chip_count,
                "profile_image": seat.profile_image,
            })

    if not players_info:
        raise HTTPException(status_code=409, detail="No players seated to randomize")

    # Clear all seats first
    for seat in seats:
        seat.player_id = None
        seat.player_name = None
        seat.wsop_id = None
        seat.nationality = None
        seat.country_code = None
        seat.chip_count = 0
        seat.profile_image = None
        seat.status = "vacant"

    # Shuffle players and assign to random seats
    random.shuffle(players_info)
    available_seats = list(seats)[:len(players_info)]
    random.shuffle(available_seats)

    for seat, pinfo in zip(available_seats, players_info):
        seat.player_id = pinfo["player_id"]
        seat.player_name = pinfo["player_name"]
        seat.wsop_id = pinfo["wsop_id"]
        seat.nationality = pinfo["nationality"]
        seat.country_code = pinfo["country_code"]
        seat.chip_count = pinfo["chip_count"]
        seat.profile_image = pinfo["profile_image"]
        seat.status = "occupied"
        seat.updated_at = utcnow()

    for seat in seats:
        session.add(seat)
    session.commit()

    # Re-fetch for fresh data
    refreshed = session.exec(
        select(TableSeat)
        .where(TableSeat.table_id == table_id)
        .order_by(TableSeat.seat_no)
    ).all()
    record_audit(session, user_id=current_user.user_id, action="seat.random", entity_type="table", entity_id=table_id)
    return ApiResponse(data=refreshed)


@router.delete("/{seat_no}", response_model=ApiResponse[dict])
def vacate_seat(
    table_id: int,
    seat_no: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    """Admin: Vacate a specific seat."""
    seat = session.exec(
        select(TableSeat).where(
            TableSeat.table_id == table_id,
            TableSeat.seat_no == seat_no,
        )
    ).first()
    if not seat:
        raise HTTPException(status_code=404, detail=f"Seat {seat_no} not found")
    seat.player_id = None
    seat.player_name = None
    seat.wsop_id = None
    seat.nationality = None
    seat.country_code = None
    seat.chip_count = 0
    seat.profile_image = None
    seat.status = "vacant"
    seat.updated_at = utcnow()
    session.add(seat)
    session.commit()
    record_audit(session, user_id=current_user.user_id, action="seat.vacate", entity_type="table", entity_id=table_id, detail=f"seat_no={seat_no}")
    return ApiResponse(data={"table_id": table_id, "seat_no": seat_no, "vacated": True})


@router.put("/{seat_no}/move", response_model=ApiResponse[dict])
def move_seat(
    table_id: int,
    seat_no: int,
    body: dict,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    """Admin: Move player from seat_no to target_seat_no. Swaps if target occupied."""
    target_no = body.get("target_seat_no")
    if target_no is None:
        raise HTTPException(422, "target_seat_no is required")
    source = session.exec(
        select(TableSeat).where(TableSeat.table_id == table_id, TableSeat.seat_no == seat_no)
    ).first()
    target = session.exec(
        select(TableSeat).where(TableSeat.table_id == table_id, TableSeat.seat_no == target_no)
    ).first()
    if not source or not target:
        raise HTTPException(404, "Seat not found")
    if source.player_id is None:
        raise HTTPException(409, "Source seat is empty")
    # Swap player data
    for field in ("player_id", "player_name", "wsop_id", "nationality", "country_code", "chip_count", "profile_image", "status"):
        src_val = getattr(source, field)
        tgt_val = getattr(target, field)
        setattr(source, field, tgt_val)
        setattr(target, field, src_val)
    source.updated_at = utcnow()
    target.updated_at = utcnow()
    session.add(source)
    session.add(target)
    session.commit()
    record_audit(session, user_id=current_user.user_id, action="seat.move", entity_type="table", entity_id=table_id, detail=f"seat {seat_no} → {target_no}")
    return ApiResponse(data={"table_id": table_id, "from": seat_no, "to": target_no, "swapped": True})
