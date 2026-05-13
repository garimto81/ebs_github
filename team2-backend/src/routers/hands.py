"""Hands router — Cycle 21 (Players_HandHistory_API.md v1.0.0).

GET endpoints (spec §2.3 + §2.4):
  - GET /api/v1/hands?event_id=&flight_id=&table_id=&player_id=&showdown_only=
                     &date_from=&date_to=&limit=&cursor=
    → HandListResponse {items, next_cursor, has_more}
  - GET /api/v1/hands/{id}
    → HandDetailResponse (nested hand_players + hand_actions)

Sub-routes (legacy, kept for backwards-compat):
  - GET /api/v1/hands/{id}/players → ApiResponse + HandPlayerResponse[]
  - GET /api/v1/hands/{id}/actions → ApiResponse + HandActionResponse[]

이전 Backend_HTTP.md §5.10.1 offset/page 페이지네이션은 deprecated.
cursor 미지정 시 첫 페이지(hand_id DESC) 반환.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user
from src.models.schemas import (
    ApiResponse,
    HandActionNested,
    HandActionResponse,
    HandDetailResponse,
    HandListItem,
    HandListResponse,
    HandPlayerNested,
    HandPlayerResponse,
)
from src.models.user import User
from src.services.hand_service import (
    DEFAULT_CURSOR_LIMIT,
    MAX_CURSOR_LIMIT,
    encode_hand_cursor,
    get_hand_actions,
    get_hand_players,
    get_hand_with_nested,
    list_hands_with_cursor,
)

router = APIRouter(prefix="/api/v1", tags=["hands"])


# ── Cycle 21 cursor-based list (spec v1.0.0 §2.3) ──


@router.get("/hands", response_model=HandListResponse)
def api_list_hands(
    event_id: int | None = Query(None, description="Event 단위 필터"),
    flight_id: int | None = Query(None, description="Flight 단위 필터"),
    table_id: int | None = Query(None, description="Table 단위 필터"),
    player_id: int | None = Query(None, description="참여자 필터"),
    showdown_only: bool = Query(False, description="ended_at IS NOT NULL + board >= flop"),
    date_from: str | None = Query(None, description="started_at >= ISO8601"),
    date_to: str | None = Query(None, description="started_at < ISO8601"),
    limit: int = Query(DEFAULT_CURSOR_LIMIT, ge=1, le=MAX_CURSOR_LIMIT),
    cursor: str | None = Query(None, description="base64 {hand_id: N} from previous page"),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, next_cursor_hid, has_more, winner_by_hid = list_hands_with_cursor(
        db,
        event_id=event_id,
        flight_id=flight_id,
        table_id=table_id,
        player_id=player_id,
        showdown_only=showdown_only,
        date_from=date_from,
        date_to=date_to,
        limit=limit,
        cursor=cursor,
    )

    list_items: list[HandListItem] = []
    for h in items:
        item = HandListItem.model_validate(h, from_attributes=True)
        item.winner_player_name = winner_by_hid.get(h.hand_id)
        list_items.append(item)

    return HandListResponse(
        items=list_items,
        next_cursor=encode_hand_cursor(next_cursor_hid) if next_cursor_hid else None,
        has_more=has_more,
    )


# ── Cycle 21 detail (spec v1.0.0 §2.4) ──


@router.get("/hands/{hand_id}", response_model=HandDetailResponse)
def api_get_hand(
    hand_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    h, players, actions = get_hand_with_nested(hand_id, db)
    return HandDetailResponse(
        hand_id=h.hand_id,
        table_id=h.table_id,
        hand_number=h.hand_number,
        game_type=h.game_type,
        bet_structure=h.bet_structure,
        dealer_seat=h.dealer_seat,
        board_cards=h.board_cards,
        pot_total=h.pot_total,
        side_pots=h.side_pots,
        current_street=h.current_street,
        started_at=h.started_at,
        ended_at=h.ended_at,
        duration_sec=h.duration_sec,
        hand_players=[HandPlayerNested.model_validate(p, from_attributes=True) for p in players],
        hand_actions=[HandActionNested.model_validate(a, from_attributes=True) for a in actions],
    )


# ── Legacy sub-routes (Backend_HTTP.md §5.10.1, 2026-04-21) ──


@router.get("/hands/{hand_id}/players")
def api_get_hand_players(
    hand_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    players = get_hand_players(hand_id, db)
    return ApiResponse(
        data=[HandPlayerResponse.model_validate(p, from_attributes=True) for p in players],
    )


@router.get("/hands/{hand_id}/actions")
def api_get_hand_actions(
    hand_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    actions = get_hand_actions(hand_id, db)
    return ApiResponse(
        data=[HandActionResponse.model_validate(a, from_attributes=True) for a in actions],
    )
