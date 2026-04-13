from fastapi import HTTPException
from sqlmodel import Session, select

from bo.db.models import Table, TableSeat
from bo.db.models.base import utcnow

VALID_TRANSITIONS = {
    "empty": ["setup"],
    "setup": ["live"],
    "live": ["paused", "closed"],
    "paused": ["live", "closed"],
    "closed": ["empty"],
}


def validate_transition(
    session: Session, table: Table, new_status: str
) -> tuple[bool, str]:
    """Validate if a table status transition is allowed."""
    current = table.status
    allowed = VALID_TRANSITIONS.get(current, [])

    if new_status not in allowed:
        return False, f"'{current}' 상태에서 '{new_status}' 상태로 전환할 수 없습니다"

    # Guard: empty -> setup
    if current == "empty" and new_status == "setup":
        if table.game_type is None or table.game_type == 0:
            return False, "게임 설정을 완료하세요"
        seats = session.exec(
            select(TableSeat).where(
                TableSeat.table_id == table.table_id,
                TableSeat.status == "occupied",
            )
        ).all()
        if len(seats) < 1:
            return False, "플레이어를 1명 이상 등록하세요"

    # Guard: setup -> live
    if current == "setup" and new_status == "live":
        occupied_seats = session.exec(
            select(TableSeat).where(
                TableSeat.table_id == table.table_id,
                TableSeat.status == "occupied",
            )
        ).all()
        for seat in occupied_seats:
            if seat.player_id is None:
                return False, (
                    f"좌석 배치를 완료하세요 (좌석 {seat.seat_no}에 플레이어 미배정)"
                )
        if table.type == "feature":
            if table.rfid_reader_id is None:
                return False, "RFID 리더를 할당하세요"
            if not table.deck_registered:
                return False, "덱 등록을 완료하세요"

    return True, ""


def apply_transition(
    session: Session, table: Table, new_status: str
) -> Table:
    """Validate and apply a table status transition."""
    allowed, reason = validate_transition(session, table, new_status)
    if not allowed:
        raise HTTPException(status_code=400, detail=reason)

    table.status = new_status
    table.updated_at = utcnow()
    session.add(table)
    session.commit()
    session.refresh(table)
    return table
