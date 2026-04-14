"""Table / Seat CRUD service."""
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.table import VALID_SEAT_TRANSITIONS, Player, Table, TableSeat
from src.models.schemas import SeatUpdate, TableCreate
from src.services.series_service import get_flight


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


# ── Table CRUD ──────────────────────────────────────


def create_table(flight_id: int, data: TableCreate, db: Session) -> Table:
    """Create a table + auto-generate 10 seats (0-9, status=empty)."""
    # Validate flight FK
    _ = get_flight(flight_id, db)

    t = Table(
        event_flight_id=flight_id,
        **data.model_dump(),
    )
    db.add(t)
    db.commit()
    db.refresh(t)

    # Auto-create 10 seats
    for seat_no in range(10):
        seat = TableSeat(table_id=t.table_id, seat_no=seat_no, status="empty")
        db.add(seat)
    db.commit()

    return t


def list_tables(flight_id: int, db: Session, skip: int = 0, limit: int = 20) -> tuple[list[Table], int]:
    _ = get_flight(flight_id, db)
    stmt = select(Table).where(Table.event_flight_id == flight_id)
    total = len(db.exec(stmt).all())
    items = db.exec(stmt.offset(skip).limit(limit)).all()
    return items, total


def get_table(table_id: int, db: Session) -> Table:
    t = db.exec(select(Table).where(Table.table_id == table_id)).first()
    if t is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Table {table_id} not found"},
        )
    return t


# ── Seat operations ─────────────────────────────────


def get_table_seats(table_id: int, db: Session) -> list[TableSeat]:
    _ = get_table(table_id, db)
    seats = db.exec(
        select(TableSeat).where(TableSeat.table_id == table_id).order_by(TableSeat.seat_no)
    ).all()
    return seats


def _get_seat(table_id: int, seat_no: int, db: Session) -> TableSeat:
    seat = db.exec(
        select(TableSeat).where(
            TableSeat.table_id == table_id,
            TableSeat.seat_no == seat_no,
        )
    ).first()
    if seat is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Seat {seat_no} on table {table_id} not found"},
        )
    return seat


def assign_seat(table_id: int, seat_no: int, player_id: int, db: Session, chip_count: int = 0) -> TableSeat:
    """Assign a player to a seat. empty→new transition."""
    _ = get_table(table_id, db)
    seat = _get_seat(table_id, seat_no, db)

    if seat.status != "empty":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "SEAT_OCCUPIED", "message": f"Seat {seat_no} is {seat.status}, not empty"},
        )

    # Validate player exists
    player = db.exec(select(Player).where(Player.player_id == player_id)).first()
    if player is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Player {player_id} not found"},
        )

    seat.player_id = player_id
    seat.player_name = f"{player.first_name} {player.last_name}"
    seat.nationality = player.nationality
    seat.country_code = player.country_code
    seat.chip_count = chip_count
    seat.status = "new"
    seat.updated_at = _utcnow()
    db.add(seat)
    db.commit()
    db.refresh(seat)
    return seat


def update_seat_status(table_id: int, seat_no: int, new_status: str, db: Session) -> TableSeat:
    """Transition seat status with validation."""
    _ = get_table(table_id, db)
    seat = _get_seat(table_id, seat_no, db)

    allowed = VALID_SEAT_TRANSITIONS.get(seat.status, [])
    if new_status not in allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "code": "INVALID_TRANSITION",
                "message": f"Cannot transition from '{seat.status}' to '{new_status}'",
            },
        )

    seat.status = new_status
    seat.updated_at = _utcnow()

    # If transitioning to empty, clear player data
    if new_status == "empty":
        seat.player_id = None
        seat.player_name = None
        seat.nationality = None
        seat.country_code = None
        seat.chip_count = 0

    db.add(seat)
    db.commit()
    db.refresh(seat)
    return seat


def vacate_seat(table_id: int, seat_no: int, db: Session) -> TableSeat:
    """Force vacate: set status→empty, clear player data."""
    seat = _get_seat(table_id, seat_no, db)
    seat.status = "empty"
    seat.player_id = None
    seat.player_name = None
    seat.nationality = None
    seat.country_code = None
    seat.chip_count = 0
    seat.updated_at = _utcnow()
    db.add(seat)
    db.commit()
    db.refresh(seat)
    return seat


# ── Player CRUD ─────────────────────────────────────


def create_player(data, db: Session) -> Player:
    p = Player(**data.model_dump())
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


def list_players(db: Session, skip: int = 0, limit: int = 20, search: str | None = None) -> tuple[list[Player], int]:
    stmt = select(Player)
    if search:
        stmt = stmt.where(
            (Player.first_name.contains(search)) | (Player.last_name.contains(search))  # type: ignore[union-attr]
        )
    all_items = db.exec(stmt).all()
    total = len(all_items)
    items = db.exec(stmt.offset(skip).limit(limit)).all()
    return items, total


def get_player(player_id: int, db: Session) -> Player:
    p = db.exec(select(Player).where(Player.player_id == player_id)).first()
    if p is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Player {player_id} not found"},
        )
    return p


def update_player(player_id: int, data, db: Session) -> Player:
    p = get_player(player_id, db)
    updates = data.model_dump(exclude_unset=True)
    for k, v in updates.items():
        setattr(p, k, v)
    p.updated_at = _utcnow()
    db.add(p)
    db.commit()
    db.refresh(p)
    return p
