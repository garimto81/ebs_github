"""Break lifecycle service — SG-042 PR-A Area 2.

SSOT: docs/2. Development/2.2 Backend/Back_Office/Overview.md §3.9.1
Contract: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md

WSOP LIVE webhook 에서 chip count snapshot 이 도착할 때, 해당 테이블의 모든 활성
좌석이 제출을 완료했는지 자동으로 감지하여 break_table_chip_count_complete 이벤트를
발생시킨다.

설계 원칙 (PRD §3.9.1 3-mode):
- Auto mode: WSOP LIVE webhook 이 push → 자동 감지 (본 서비스)
- Manual mode: Operator 수동 확인 버튼 → 본 서비스의 trigger_break_complete_if_ready 직접 호출
- Override mode: SysOp 명시 → break_id 무관하게 강제 complete

중복 방지 (idempotency): BreakCompletionMarker 테이블에 (table_id, break_id) 고유 키로
already-triggered 상태를 영속화한다. 메모리 상태에 의존하지 않아 재시작 후에도 중복 신호 없음.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone
from enum import Enum
from typing import Optional

from sqlmodel import Field, SQLModel, Session, select

from src.models.chip_count_snapshot import ChipCountSnapshot
from src.models.table import Table, TableSeat

logger = logging.getLogger(__name__)

# ── 완료 상태 영속화 모델 ─────────────────────────────────────────────────────


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class BreakCompletionMarker(SQLModel, table=True):
    """break_id + table_id 조합의 완료 이력 — 중복 신호 방지용.

    이 테이블은 immutable append (삭제/수정 없음).
    같은 (table_id, break_id) 가 이미 존재하면 → ALREADY_TRIGGERED.
    """

    __tablename__ = "break_completion_markers"

    id: Optional[int] = Field(default=None, primary_key=True)
    table_id: int = Field(nullable=False, index=True)
    break_id: int = Field(nullable=False, index=True)
    triggered_at: str = Field(default_factory=_utcnow)
    # 활성 좌석 수 (감지 당시 스냅샷)
    seat_count: int = Field(default=0)
    total_chips: int = Field(default=0)

    __table_args__ = (
        __import__("sqlalchemy").UniqueConstraint(
            "table_id", "break_id",
            name="uq_break_completion_table_break",
        ),
    )


# ── 결과 열거 ─────────────────────────────────────────────────────────────────


class BreakCompleteResult(str, Enum):
    """trigger_break_complete_if_ready 반환 값."""

    PENDING = "pending"           # 아직 모든 좌석 미제출
    TRIGGERED = "triggered"       # 이번에 최초로 완료 감지
    ALREADY_TRIGGERED = "already_triggered"  # 이미 감지됨 (중복 호출)


# ── 활성 좌석 조회 ────────────────────────────────────────────────────────────


_INACTIVE_STATUSES = frozenset({"empty", "reserved", "hold"})


def _get_active_seat_numbers(table_id: int, db: Session) -> set[int]:
    """테이블의 활성 좌석 번호 집합을 반환한다.

    status 가 empty/reserved/hold 인 좌석은 chip count 대상에서 제외.
    좌석이 전혀 없는 경우 빈 집합 반환.
    """
    rows = db.exec(
        select(TableSeat).where(TableSeat.table_id == table_id)
    ).all()
    active = {r.seat_no for r in rows if r.status not in _INACTIVE_STATUSES}
    return active


def _get_submitted_seat_numbers(table_id: int, break_id: int, db: Session) -> set[int]:
    """해당 break_id 에 대해 chip count snapshot 을 제출한 좌석 번호 집합."""
    rows = db.exec(
        select(ChipCountSnapshot).where(
            ChipCountSnapshot.table_id == table_id,
            ChipCountSnapshot.break_id == break_id,
        )
    ).all()
    return {r.seat_number for r in rows}


# ── 공개 API ──────────────────────────────────────────────────────────────────


def is_table_chip_count_complete(table_id: int, break_id: int, db: Session) -> bool:
    """해당 break_id 에 대해 테이블의 모든 활성 좌석이 chip count 를 제출했는지 확인.

    Returns:
        True: 활성 좌석이 1개 이상 있고 모두 제출 완료.
        False: 활성 좌석 없음, 또는 미제출 좌석 존재.
    """
    active_seats = _get_active_seat_numbers(table_id, db)
    if not active_seats:
        logger.debug(
            "break_lifecycle: table_id=%s has no active seats → incomplete",
            table_id,
        )
        return False

    submitted_seats = _get_submitted_seat_numbers(table_id, break_id, db)
    missing = active_seats - submitted_seats

    if missing:
        logger.debug(
            "break_lifecycle: table_id=%s break_id=%s missing seats=%s",
            table_id, break_id, sorted(missing),
        )
        return False

    logger.info(
        "break_lifecycle: table_id=%s break_id=%s ALL %d seats submitted",
        table_id, break_id, len(active_seats),
    )
    return True


def trigger_break_complete_if_ready(
    table_id: int,
    break_id: int,
    db: Session,
    *,
    ws_manager=None,
) -> BreakCompleteResult:
    """완료 조건이 충족되면 break_table_chip_count_complete 이벤트를 발생시킨다.

    Args:
        table_id: 감지 대상 테이블 ID.
        break_id: WSOP LIVE 에서 발급한 브레이크 식별자.
        db: SQLModel Session.
        ws_manager: WebSocket ConnectionManager (선택). None 이면 DB 마커만 기록.

    Returns:
        BreakCompleteResult 열거값.

    Idempotency:
        동일 (table_id, break_id) 조합에 대한 두 번째 호출은 ALREADY_TRIGGERED 반환.
    """
    # 1. 중복 체크
    existing = db.exec(
        select(BreakCompletionMarker).where(
            BreakCompletionMarker.table_id == table_id,
            BreakCompletionMarker.break_id == break_id,
        )
    ).first()
    if existing is not None:
        return BreakCompleteResult.ALREADY_TRIGGERED

    # 2. 완료 조건 확인
    if not is_table_chip_count_complete(table_id, break_id, db):
        return BreakCompleteResult.PENDING

    # 3. 완료 마커 영속화
    active_seats = _get_active_seat_numbers(table_id, db)
    snaps = db.exec(
        select(ChipCountSnapshot).where(
            ChipCountSnapshot.table_id == table_id,
            ChipCountSnapshot.break_id == break_id,
        )
    ).all()
    total_chips = sum(s.chip_count for s in snaps)

    marker = BreakCompletionMarker(
        table_id=table_id,
        break_id=break_id,
        seat_count=len(active_seats),
        total_chips=total_chips,
    )
    db.add(marker)
    db.commit()

    logger.info(
        "break_lifecycle: TRIGGERED table_id=%s break_id=%s seats=%d total_chips=%d",
        table_id, break_id, len(active_seats), total_chips,
    )

    # 4. WS 브로드캐스트 (선택적 — ws_manager 없으면 DB 마커만)
    if ws_manager is not None:
        import asyncio

        async def _broadcast():
            try:
                await ws_manager.broadcast("lobby", str(table_id), {
                    "type": "break_table_chip_count_complete",
                    "data": {
                        "table_id": table_id,
                        "break_id": break_id,
                        "seat_count": len(active_seats),
                        "total_chips": total_chips,
                        "triggered_at": marker.triggered_at,
                    },
                })
            except Exception as exc:  # noqa: BLE001
                logger.warning(
                    "break_lifecycle: WS broadcast failed table_id=%s: %s",
                    table_id, exc,
                )

        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                loop.create_task(_broadcast())
            else:
                loop.run_until_complete(_broadcast())
        except RuntimeError:
            logger.warning(
                "break_lifecycle: no event loop for WS broadcast table_id=%s",
                table_id,
            )

    return BreakCompleteResult.TRIGGERED
