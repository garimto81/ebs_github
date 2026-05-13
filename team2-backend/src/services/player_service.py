"""Player query service — Cycle 21 (Players + Hand History API contract v1.0.0).

Spec: docs/2. Development/2.2 Backend/APIs/Players_HandHistory_API.md §2.1 + §2.2

Responsibilities:
  - cursor-based pagination (base64 encoded {"player_id": N})
  - filter combination (event_id via tables → event_flights → events JOIN, search ILIKE,
    nationality, player_status)
  - get_player_with_stats (누적 통계: total_hands, wins, cumulative_pnl, VPIP/PFR/AGR pct)

기존 CRUD 로직(create_player / update_player / delete_player)은 table_service.py 에 유지.
본 모듈은 spec contract v1.0.0 의 read-only 확장만 담당.
"""
from __future__ import annotations

import base64
import json
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy import and_, distinct, func, or_
from sqlalchemy import select as sa_select
from sqlmodel import Session, select

from src.models.competition import EventFlight
from src.models.hand import Hand, HandAction, HandPlayer
from src.models.table import Player, Table

DEFAULT_LIMIT = 50
MAX_LIMIT = 200


# ── Cursor encode / decode ─────────────────────────


def encode_player_cursor(player_id: int) -> str:
    payload = json.dumps({"player_id": player_id}).encode()
    return base64.urlsafe_b64encode(payload).decode().rstrip("=")


def decode_player_cursor(cursor: str) -> int:
    # Add padding back for base64 decode (urlsafe variant)
    padded = cursor + "=" * (-len(cursor) % 4)
    try:
        payload = json.loads(base64.urlsafe_b64decode(padded.encode()).decode())
        return int(payload["player_id"])
    except (ValueError, KeyError, json.JSONDecodeError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_CURSOR", "message": f"cursor decode failed: {exc}"},
        ) from exc


# ── Player list (cursor pagination + filters) ──────


def list_players_with_cursor(
    db: Session,
    *,
    event_id: Optional[int] = None,
    search: Optional[str] = None,
    nationality: Optional[str] = None,
    player_status: Optional[str] = None,
    limit: int = DEFAULT_LIMIT,
    cursor: Optional[str] = None,
) -> tuple[list[Player], Optional[int], bool]:
    """List players with cursor-based pagination.

    Returns (items, next_cursor_player_id_or_None, has_more).

    Ordering: player_id DESC (newest first → stable cursor).
    """
    if limit < 1 or limit > MAX_LIMIT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "INVALID_LIMIT", "message": f"limit must be 1..{MAX_LIMIT}"},
        )

    stmt = select(Player)

    # event_id filter — players who participated in hands of the given event
    # (events_players table 미정의 → hand_players → hands → tables → event_flights → events JOIN
    #  으로 derive. Schema.md §players 행 자체에는 event 관계 없음.)
    if event_id is not None:
        subq = (
            sa_select(distinct(HandPlayer.player_id))
            .join(Hand, Hand.hand_id == HandPlayer.hand_id)
            .join(Table, Table.table_id == Hand.table_id)
            .join(EventFlight, EventFlight.event_flight_id == Table.event_flight_id)
            .where(EventFlight.event_id == event_id)
            .where(HandPlayer.player_id.isnot(None))
        )
        stmt = stmt.where(Player.player_id.in_(subq))

    # search — first_name / last_name / wsop_id ILIKE 부분 일치
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(
            or_(
                Player.first_name.ilike(pattern),
                Player.last_name.ilike(pattern),
                Player.wsop_id.ilike(pattern),
            )
        )

    if nationality is not None:
        stmt = stmt.where(Player.country_code == nationality)

    if player_status is not None:
        stmt = stmt.where(Player.player_status == player_status)

    # cursor — player_id < cursor (DESC ordering)
    if cursor:
        cursor_pid = decode_player_cursor(cursor)
        stmt = stmt.where(Player.player_id < cursor_pid)

    # LIMIT n+1 으로 has_more 판정
    stmt = stmt.order_by(Player.player_id.desc()).limit(limit + 1)
    rows = db.exec(stmt).all()

    has_more = len(rows) > limit
    items = list(rows[:limit])
    next_cursor_pid: Optional[int] = None
    if has_more and items:
        next_cursor_pid = items[-1].player_id

    return items, next_cursor_pid, has_more


# ── Player detail + optional stats ─────────────────


def get_player_or_404(player_id: int, db: Session) -> Player:
    p = db.exec(select(Player).where(Player.player_id == player_id)).first()
    if p is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Player {player_id} not found"},
        )
    return p


def compute_player_stats(player_id: int, db: Session) -> dict:
    """누적 통계 — total_hands / wins / cumulative_pnl / vpip_pct / pfr_pct / agr_pct.

    VPIP = (vpip=1 인 hand 수) / total_hands × 100
    PFR  = (pfr=1 인 hand 수) / total_hands × 100
    AGR  = (raise/bet 액션 수) / (raise/bet/call 액션 수) × 100  (aggression ratio)
    """
    # total_hands / wins / cumulative_pnl
    total_hands = db.exec(
        sa_select(func.count(HandPlayer.id)).where(HandPlayer.player_id == player_id)
    ).scalar() or 0
    wins = db.exec(
        sa_select(func.count(HandPlayer.id))
        .where(HandPlayer.player_id == player_id)
        .where(HandPlayer.is_winner == 1)
    ).scalar() or 0
    cumulative_pnl = db.exec(
        sa_select(func.coalesce(func.sum(HandPlayer.pnl), 0))
        .where(HandPlayer.player_id == player_id)
    ).scalar() or 0

    vpip_count = db.exec(
        sa_select(func.count(HandPlayer.id))
        .where(HandPlayer.player_id == player_id)
        .where(HandPlayer.vpip == 1)
    ).scalar() or 0
    pfr_count = db.exec(
        sa_select(func.count(HandPlayer.id))
        .where(HandPlayer.player_id == player_id)
        .where(HandPlayer.pfr == 1)
    ).scalar() or 0

    # AGR — hand_players 의 hand_id 집합에 대한 hand_actions 분석.
    #   aggressive = raise/bet 액션 수
    #   passive    = call 액션 수
    # AGR % = aggressive / (aggressive + passive) × 100
    # seat_no 도 매칭해야 정확하지만 spec 은 player-level. 단순화: 같은 hand 안에서 player_id 매칭.
    seat_subq = sa_select(HandPlayer.hand_id, HandPlayer.seat_no).where(
        HandPlayer.player_id == player_id
    )
    # SQLite/PostgreSQL 양립을 위해 별도 쿼리 후 Python 계산
    seat_rows = db.exec(seat_subq).all()
    seat_pairs = [(r[0], r[1]) for r in seat_rows] if seat_rows else []

    aggressive = 0
    passive = 0
    if seat_pairs:
        action_stmt = sa_select(HandAction.action_type).where(
            and_(
                HandAction.hand_id.in_([p[0] for p in seat_pairs]),
                HandAction.seat_no.in_([p[1] for p in seat_pairs]),
            )
        )
        for (action_type,) in db.exec(action_stmt).all():
            if action_type in ("raise", "bet"):
                aggressive += 1
            elif action_type == "call":
                passive += 1

    vpip_pct = (vpip_count / total_hands * 100.0) if total_hands else 0.0
    pfr_pct = (pfr_count / total_hands * 100.0) if total_hands else 0.0
    agr_pct = (aggressive / (aggressive + passive) * 100.0) if (aggressive + passive) else 0.0

    return {
        "total_hands": int(total_hands),
        "wins": int(wins),
        "cumulative_pnl": int(cumulative_pnl),
        "vpip_pct": round(vpip_pct, 2),
        "pfr_pct": round(pfr_pct, 2),
        "agr_pct": round(agr_pct, 2),
    }
