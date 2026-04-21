"""Hands router — read-only hand history.

Backend_HTTP.md §5.10.1 GET /hands 필터 명세 (2026-04-21):
  event_id, day, table_id (CSV), player_id, date_from, date_to, hand_number, page, page_size
"""
from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user
from src.models.schemas import (
    ApiResponse,
    HandActionResponse,
    HandPlayerResponse,
    HandResponse,
)
from src.models.user import User
from src.services.hand_service import (
    DEFAULT_PAGE_SIZE,
    MAX_PAGE_SIZE,
    get_hand,
    get_hand_actions,
    get_hand_players,
    list_hands,
)

router = APIRouter(prefix="/api/v1", tags=["hands"])


# ── Hands ──────────────────────────────────────────


@router.get("/hands")
def api_list_hands(
    # 기존 파라미터 (호환)
    table_id: Optional[str] = Query(None, description="Table ID (단일 정수 또는 CSV '1,2,3')"),
    skip: int = Query(0, ge=0, description="레거시: offset. page 사용 권장"),
    limit: int = Query(DEFAULT_PAGE_SIZE, ge=1, le=MAX_PAGE_SIZE, description="레거시: limit. page_size 사용 권장"),
    # 신규 필터 (2026-04-21)
    event_id: Optional[int] = Query(None, description="Event 단위 필터 (tables→event_flights JOIN)"),
    day: Optional[str] = Query(None, description="event_flights.display_name 매칭 (예: 'Day 1A')"),
    player_id: Optional[int] = Query(None, description="참여자 필터 (hand_players 서브쿼리)"),
    date_from: Optional[str] = Query(None, description="started_at >= ISO8601"),
    date_to: Optional[str] = Query(None, description="started_at < ISO8601"),
    hand_number: Optional[int] = Query(None, description="정확 매칭"),
    page: Optional[int] = Query(None, ge=1, description="1-indexed. 지정 시 skip/limit 대체"),
    page_size: Optional[int] = Query(None, ge=1, le=MAX_PAGE_SIZE, description="페이지 크기. 지정 시 limit 대체"),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # page / page_size 가 있으면 skip / limit 대체 (우선)
    effective_limit = page_size if page_size is not None else limit
    if page is not None:
        effective_skip = (page - 1) * effective_limit
    else:
        effective_skip = skip

    # table_id CSV 파싱
    table_filter: Optional[int | list[int]] = None
    if table_id is not None:
        if "," in table_id:
            try:
                table_filter = [int(x.strip()) for x in table_id.split(",") if x.strip()]
            except ValueError:
                raise HTTPException(
                    status_code=400,
                    detail={"code": "INVALID_TABLE_ID", "message": "table_id CSV parse failed"},
                )
            if not table_filter:
                table_filter = None
        else:
            try:
                table_filter = int(table_id)
            except ValueError:
                raise HTTPException(
                    status_code=400,
                    detail={"code": "INVALID_TABLE_ID", "message": "table_id must be int"},
                )

    items, total = list_hands(
        table_id=table_filter,
        db=db,
        skip=effective_skip,
        limit=effective_limit,
        event_id=event_id,
        day=day,
        player_id=player_id,
        date_from=date_from,
        date_to=date_to,
        hand_number=hand_number,
    )
    meta = {
        "total": total,
    }
    if page is not None or page_size is not None:
        meta["page"] = page or 1
        meta["page_size"] = effective_limit
    else:
        meta["skip"] = effective_skip
        meta["limit"] = effective_limit
    return ApiResponse(
        data=[HandResponse.model_validate(h, from_attributes=True) for h in items],
        meta=meta,
    )


@router.get("/hands/{hand_id}")
def api_get_hand(
    hand_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    h = get_hand(hand_id, db)
    return ApiResponse(data=HandResponse.model_validate(h, from_attributes=True))


# ── Hand Players ───────────────────────────────────


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


# ── Hand Actions ───────────────────────────────────


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
