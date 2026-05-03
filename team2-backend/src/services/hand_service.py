"""Hand / HandPlayer / HandAction read-only service.

Backend_HTTP.md §5.10.1 GET /hands 필터 명세 준거 (2026-04-21 확장):
  - event_id, day, table_id(CSV 지원), player_id, date_from, date_to, hand_number
  - page / page_size (1-indexed)

실제 DB schema 기준 JOIN:
  event_id → JOIN event_flights ON tables.event_flight_id → event_flights.event_id
  day      → event_flights.display_name 매칭 (e.g. "Day 1A")
  player   → hand_players JOIN (실제 테이블명, Backend_HTTP.md `hand_seats` 는 spec drift — 정정 예정)
"""
from __future__ import annotations

from typing import Optional, Sequence

from fastapi import HTTPException, status
from sqlalchemy import and_, func, select as sa_select
from sqlmodel import Session, select

from src.models.competition import Event, EventFlight
from src.models.hand import Hand, HandAction, HandPlayer
from src.models.table import Table

MAX_PAGE_SIZE = 200
DEFAULT_PAGE_SIZE = 20


# ── Hand queries ───────────────────────────────────


def list_hands(
    table_id: Optional[int | Sequence[int]] = None,
    db: Session = None,
    skip: int = 0,
    limit: int = DEFAULT_PAGE_SIZE,
    *,
    event_id: Optional[int] = None,
    day: Optional[str] = None,
    player_id: Optional[int] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    hand_number: Optional[int] = None,
) -> tuple[list[Hand], int]:
    """핸드 목록 조회 — 다중 필터 지원.

    table_id: int 단일 또는 Sequence[int] (CSV 지원). 기존 호환을 위해 첫 positional.
    event_id: tables → event_flights → events JOIN.
    day: event_flights.display_name 매칭 (예: "Day 1A").
    player_id: hand_players 서브쿼리 존재.
    date_from / date_to: hands.started_at 범위.
    hand_number: 정확 매칭.
    """
    if db is None:  # pragma: no cover — defensive
        raise ValueError("db Session required")

    stmt = select(Hand)

    # table_id — 단일 int 또는 Sequence[int] 허용
    if table_id is not None:
        if isinstance(table_id, int):
            stmt = stmt.where(Hand.table_id == table_id)
        else:
            ids = list(table_id)
            if ids:
                stmt = stmt.where(Hand.table_id.in_(ids))

    # event_id — tables JOIN → event_flights JOIN
    if event_id is not None:
        stmt = (
            stmt.join(Table, Table.table_id == Hand.table_id)
            .join(EventFlight, EventFlight.event_flight_id == Table.event_flight_id)
            .where(EventFlight.event_id == event_id)
        )

    # day — event_flights.display_name 매칭 (JOIN 중복 방지)
    if day is not None:
        if event_id is None:  # day 단독 필터도 허용하되 JOIN 필요
            stmt = (
                stmt.join(Table, Table.table_id == Hand.table_id)
                .join(EventFlight, EventFlight.event_flight_id == Table.event_flight_id)
            )
        stmt = stmt.where(EventFlight.display_name == day)

    # player_id — hand_players 서브쿼리 존재
    if player_id is not None:
        subq = sa_select(HandPlayer.hand_id).where(HandPlayer.player_id == player_id)
        stmt = stmt.where(Hand.hand_id.in_(subq))

    if date_from is not None:
        stmt = stmt.where(Hand.started_at >= date_from)
    if date_to is not None:
        stmt = stmt.where(Hand.started_at < date_to)

    if hand_number is not None:
        stmt = stmt.where(Hand.hand_number == hand_number)

    # count total — 같은 WHERE 에 SELECT COUNT.
    # B-Q19 fix: SQLAlchemy 2.x 의 .one() 은 Row 객체 반환 → int(Row) TypeError.
    # .scalar() 로 명시적 단일 값 추출 (SQLAlchemy 1.x/2.x 양쪽 호환).
    count_stmt = sa_select(func.count()).select_from(stmt.subquery())
    total = db.exec(count_stmt).scalar() or 0

    # paginated items — 시간 내림차순 정렬
    stmt = stmt.order_by(Hand.started_at.desc()).offset(skip).limit(limit)
    items = db.exec(stmt).all()
    return list(items), int(total)


def get_hand(hand_id: int, db: Session) -> Hand:
    h = db.exec(select(Hand).where(Hand.hand_id == hand_id)).first()
    if h is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Hand {hand_id} not found"},
        )
    return h


# ── HandPlayer queries ─────────────────────────────


def get_hand_players(hand_id: int, db: Session) -> list[HandPlayer]:
    _ = get_hand(hand_id, db)
    return db.exec(
        select(HandPlayer)
        .where(HandPlayer.hand_id == hand_id)
        .order_by(HandPlayer.seat_no)
    ).all()


# ── HandAction queries ─────────────────────────────


def get_hand_actions(hand_id: int, db: Session) -> list[HandAction]:
    _ = get_hand(hand_id, db)
    return db.exec(
        select(HandAction)
        .where(HandAction.hand_id == hand_id)
        .order_by(HandAction.action_order)
    ).all()
