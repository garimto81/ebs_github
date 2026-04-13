import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Player, Table, TableSeat, User
from bo.db.models.base import utcnow
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.seat import SeatRead
from bo.schemas.table import TableCreate, TableRead, TableStatusRead, TableUpdate
from bo.services.audit_service import record_audit
from bo.services.crud_service import create_item, delete_item, get_by_id, get_list, update_item

router = APIRouter(prefix="/tables", tags=["Tables"])


@router.get("", response_model=ApiResponse[list[TableRead]])
def list_tables(
    page: int = 1,
    limit: int = 20,
    flight_id: int | None = None,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    filters = {"event_flight_id": flight_id} if flight_id else None
    result = get_list(session, Table, page=page, limit=limit, filters=filters)
    # BO-02 §4.1: Operator can only see tables assigned to them.
    # TODO: Add UserTableAssignment model for proper operator-table mapping.
    # For now, operators see all tables until the assignment model is implemented.
    return result


@router.get("/{table_id}", response_model=ApiResponse[TableRead])
def get_table(
    table_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Table, table_id, pk_field="table_id")
    return ApiResponse(data=item)


@router.post("", response_model=ApiResponse[TableRead], status_code=201)
def create_table(
    body: TableCreate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = create_item(session, Table, body.model_dump())
    record_audit(session, user_id=current_user.user_id, action="table.create", entity_type="table", entity_id=item.table_id)
    return ApiResponse(data=item)


@router.put("/{table_id}", response_model=ApiResponse[TableRead])
def update_table(
    table_id: int,
    body: TableUpdate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = update_item(
        session, Table, table_id,
        body.model_dump(exclude_unset=True), pk_field="table_id",
    )
    record_audit(session, user_id=current_user.user_id, action="table.update", entity_type="table", entity_id=table_id)
    return ApiResponse(data=item)


@router.delete("/{table_id}", response_model=ApiResponse[dict])
def delete_table(
    table_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    # BO-04 T-3: Only EMPTY and CLOSED tables can be deleted
    table = session.get(Table, table_id)
    if not table:
        raise HTTPException(status_code=404, detail="테이블을 찾을 수 없습니다")
    if table.status not in ("empty", "closed"):
        raise HTTPException(
            status_code=409,
            detail="EMPTY 또는 CLOSED 상태의 테이블만 삭제할 수 있습니다",
        )
    result = delete_item(session, Table, table_id, pk_field="table_id")
    record_audit(session, user_id=current_user.user_id, action="table.delete", entity_type="table", entity_id=table_id)
    return ApiResponse(data=result)


@router.post("/{table_id}/launch-cc", response_model=ApiResponse[dict])
def launch_cc(
    table_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Table, table_id, pk_field="table_id")
    item.status = "live"
    session.add(item)
    session.commit()
    session.refresh(item)
    return ApiResponse(
        data={
            "table_id": table_id,
            "status": "live",
            "cc_instance_id": str(uuid.uuid4()),
        }
    )


@router.get("/{table_id}/status", response_model=ApiResponse[TableStatusRead])
def get_table_status(
    table_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Table, table_id, pk_field="table_id")
    return ApiResponse(
        data=TableStatusRead(
            table_id=item.table_id,
            status=item.status,
            deck_registered=item.deck_registered,
            current_game=item.current_game,
        )
    )


# --- Table-Player Mapping (BO-05 §3.1) ---


@router.post("/{table_id}/players", response_model=ApiResponse[SeatRead], status_code=201)
def assign_player_to_table(
    table_id: int,
    body: dict,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    """Admin: Assign a player to the next available seat at the table."""
    table = session.get(Table, table_id)
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")

    player_id = body.get("player_id")
    seat_no = body.get("seat_no")
    if not player_id:
        raise HTTPException(status_code=422, detail="player_id is required")

    player = session.get(Player, player_id)
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")

    # Check if player already seated at this table
    existing = session.exec(
        select(TableSeat).where(
            TableSeat.table_id == table_id,
            TableSeat.player_id == player_id,
        )
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="Player already seated at this table")

    if seat_no is not None:
        # Assign to specific seat
        seat = session.exec(
            select(TableSeat).where(
                TableSeat.table_id == table_id,
                TableSeat.seat_no == seat_no,
            )
        ).first()
        if not seat:
            raise HTTPException(status_code=404, detail=f"Seat {seat_no} not found")
        if seat.player_id is not None:
            raise HTTPException(status_code=409, detail=f"Seat {seat_no} is already occupied")
    else:
        # Find first vacant seat
        seat = session.exec(
            select(TableSeat).where(
                TableSeat.table_id == table_id,
                TableSeat.status == "vacant",
            ).order_by(TableSeat.seat_no)
        ).first()
        if not seat:
            raise HTTPException(status_code=409, detail="No vacant seats available")

    seat.player_id = player.player_id
    seat.player_name = f"{player.first_name} {player.last_name}"
    seat.nationality = player.nationality
    seat.country_code = player.country_code
    seat.status = "occupied"
    seat.updated_at = utcnow()
    session.add(seat)
    session.commit()
    session.refresh(seat)
    record_audit(session, user_id=current_user.user_id, action="player.assign", entity_type="table", entity_id=table_id, detail=f"player_id={player_id}")
    return ApiResponse(data=seat)


@router.get("/{table_id}/players", response_model=ApiResponse[list[SeatRead]])
def get_table_players(
    table_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    """All roles: Get players currently seated at a table."""
    table = session.get(Table, table_id)
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    seats = session.exec(
        select(TableSeat).where(
            TableSeat.table_id == table_id,
            TableSeat.player_id.isnot(None),  # noqa: E711
        ).order_by(TableSeat.seat_no)
    ).all()
    return ApiResponse(data=seats)


@router.delete("/{table_id}/players/{player_id}", response_model=ApiResponse[dict])
def remove_player_from_table(
    table_id: int,
    player_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    """Admin: Remove a player from the table (vacate their seat)."""
    seat = session.exec(
        select(TableSeat).where(
            TableSeat.table_id == table_id,
            TableSeat.player_id == player_id,
        )
    ).first()
    if not seat:
        raise HTTPException(status_code=404, detail="Player not found at this table")

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
    record_audit(session, user_id=current_user.user_id, action="player.remove", entity_type="table", entity_id=table_id, detail=f"player_id={player_id}")
    return ApiResponse(data={"table_id": table_id, "player_id": player_id, "removed": True})


@router.post("/{table_id}/duplicate", response_model=ApiResponse[TableRead], status_code=201)
def duplicate_table(
    table_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    """Admin: Duplicate table with new name."""
    source = session.get(Table, table_id)
    if not source:
        raise HTTPException(404, "테이블을 찾을 수 없습니다")
    new_table = Table(
        event_flight_id=source.event_flight_id,
        table_no=source.table_no + 100,
        name=f"{source.name} (Copy)",
        type=source.type,
        status="empty",
        max_players=source.max_players,
        game_type=source.game_type,
        small_blind=source.small_blind,
        big_blind=source.big_blind,
        ante_type=source.ante_type,
        ante_amount=source.ante_amount,
        output_type=source.output_type,
        delay_seconds=source.delay_seconds,
        source="manual",
    )
    session.add(new_table)
    session.commit()
    session.refresh(new_table)
    record_audit(session, user_id=current_user.user_id, action="table.duplicate", entity_type="table", entity_id=new_table.table_id, detail=f"from={table_id}")
    return ApiResponse(data=new_table)
