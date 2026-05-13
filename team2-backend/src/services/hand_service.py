"""Hand / HandPlayer / HandAction read-only service.

Backend_HTTP.md §5.10.1 GET /hands 필터 명세 준거 (2026-04-21 확장):
  - event_id, day, table_id(CSV 지원), player_id, date_from, date_to, hand_number
  - page / page_size (1-indexed)

Cycle 21 (Players_HandHistory_API.md v1.0.0) 확장:
  - cursor-based pagination (LIMIT n+1 → has_more)
  - flight_id 필터 (tables.event_flight_id 직접 매칭)
  - showdown_only 필터 (ended_at IS NOT NULL AND JSON array length(board_cards) >= 3)
  - winner_player_name derive (hand_players JOIN WHERE is_winner=1 LIMIT 1)
  - get_hand_with_nested (hand + players + actions 한 번에)

실제 DB schema 기준 JOIN:
  event_id → JOIN event_flights ON tables.event_flight_id → event_flights.event_id
  day      → event_flights.display_name 매칭 (e.g. "Day 1A")
  player   → hand_players JOIN (실제 테이블명, Backend_HTTP.md `hand_seats` 는 spec drift — 정정 예정)
"""
from __future__ import annotations

import base64
import json
from typing import Optional, Sequence

from fastapi import HTTPException, status
from sqlalchemy import and_, func
from sqlalchemy import select as sa_select
from sqlmodel import Session, select

from src.models.competition import EventFlight
from src.models.hand import Hand, HandAction, HandPlayer
from src.models.table import Table

MAX_PAGE_SIZE = 200
DEFAULT_PAGE_SIZE = 20

# Cycle 21 cursor pagination defaults
DEFAULT_CURSOR_LIMIT = 50
MAX_CURSOR_LIMIT = 200


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


# ── Cycle 21: cursor pagination + nested detail ────


def encode_hand_cursor(hand_id: int) -> str:
    payload = json.dumps({"hand_id": hand_id}).encode()
    return base64.urlsafe_b64encode(payload).decode().rstrip("=")


def decode_hand_cursor(cursor: str) -> int:
    padded = cursor + "=" * (-len(cursor) % 4)
    try:
        payload = json.loads(base64.urlsafe_b64decode(padded.encode()).decode())
        return int(payload["hand_id"])
    except (ValueError, KeyError, json.JSONDecodeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_CURSOR", "message": f"cursor decode failed: {exc}"},
        ) from exc


def list_hands_with_cursor(
    db: Session,
    *,
    event_id: Optional[int] = None,
    flight_id: Optional[int] = None,
    table_id: Optional[int] = None,
    player_id: Optional[int] = None,
    showdown_only: bool = False,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    limit: int = DEFAULT_CURSOR_LIMIT,
    cursor: Optional[str] = None,
) -> tuple[list[Hand], Optional[int], bool, dict[int, str]]:
    """Cycle 21 contract — cursor-based hands list.

    Returns (hands, next_cursor_hand_id_or_None, has_more, winner_name_by_hand_id).

    Ordering: hand_id DESC (newest first → stable cursor against new INSERTs).
    """
    if limit < 1 or limit > MAX_CURSOR_LIMIT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_LIMIT", "message": f"limit must be 1..{MAX_CURSOR_LIMIT}"},
        )

    stmt = select(Hand)

    if table_id is not None:
        stmt = stmt.where(Hand.table_id == table_id)

    if flight_id is not None:
        stmt = (
            stmt.join(Table, Table.table_id == Hand.table_id)
            .where(Table.event_flight_id == flight_id)
        )

    if event_id is not None:
        # Avoid double JOIN if flight_id already joined Table
        if flight_id is None:
            stmt = stmt.join(Table, Table.table_id == Hand.table_id)
        stmt = (
            stmt.join(EventFlight, EventFlight.event_flight_id == Table.event_flight_id)
            .where(EventFlight.event_id == event_id)
        )

    if player_id is not None:
        subq = sa_select(HandPlayer.hand_id).where(HandPlayer.player_id == player_id)
        stmt = stmt.where(Hand.hand_id.in_(subq))

    if showdown_only:
        # ended_at IS NOT NULL AND board_cards JSON length >= 3 (flop+).
        # SQLite/PostgreSQL 양립을 위해 단순 문자열 길이 가드 사용:
        #   "[\"As\",\"Kh\",\"Qd\"]" 는 약 22자 이상 → "[" + 3 카드(약 6자/카드) = 길이 기준.
        # 정확도 위해 hand_id 별 후처리 필터링 가능하지만 list endpoint 는 DB 측 가드만.
        stmt = stmt.where(Hand.ended_at.isnot(None))
        stmt = stmt.where(func.length(Hand.board_cards) >= 10)

    if date_from is not None:
        stmt = stmt.where(Hand.started_at >= date_from)
    if date_to is not None:
        stmt = stmt.where(Hand.started_at < date_to)

    if cursor:
        cursor_hid = decode_hand_cursor(cursor)
        stmt = stmt.where(Hand.hand_id < cursor_hid)

    stmt = stmt.order_by(Hand.hand_id.desc()).limit(limit + 1)
    rows = db.exec(stmt).all()

    has_more = len(rows) > limit
    items = list(rows[:limit])
    next_cursor_hid: Optional[int] = None
    if has_more and items:
        next_cursor_hid = items[-1].hand_id

    # Derive winner_player_name (single JOIN hand_players WHERE is_winner=1)
    winner_by_hid: dict[int, str] = {}
    if items:
        hand_ids = [h.hand_id for h in items]
        winner_stmt = sa_select(HandPlayer.hand_id, HandPlayer.player_name).where(
            and_(
                HandPlayer.hand_id.in_(hand_ids),
                HandPlayer.is_winner == 1,
            )
        )
        for hid, pname in db.exec(winner_stmt).all():
            # first winner per hand wins (multi-winner edge case → first encountered)
            if hid not in winner_by_hid:
                winner_by_hid[hid] = pname

    return items, next_cursor_hid, has_more, winner_by_hid


def get_hand_with_nested(
    hand_id: int, db: Session
) -> tuple[Hand, list[HandPlayer], list[HandAction]]:
    """Hand detail — hand + nested players + actions (단일 트랜잭션)."""
    h = get_hand(hand_id, db)
    players = db.exec(
        select(HandPlayer)
        .where(HandPlayer.hand_id == hand_id)
        .order_by(HandPlayer.seat_no)
    ).all()
    actions = db.exec(
        select(HandAction)
        .where(HandAction.hand_id == hand_id)
        .order_by(HandAction.action_order)
    ).all()
    return h, list(players), list(actions)
