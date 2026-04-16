"""Hands router — read-only hand history (DATA-04 §3)."""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
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
    get_hand,
    get_hand_actions,
    get_hand_players,
    list_hands,
)

router = APIRouter(prefix="/api/v1", tags=["hands"])


# ── Hands ──────────────────────────────────────────


@router.get("/hands")
def api_list_hands(
    table_id: int = Query(..., description="Filter by table"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_hands(table_id, db, skip, limit)
    return ApiResponse(
        data=[HandResponse.model_validate(h, from_attributes=True) for h in items],
        meta={"skip": skip, "limit": limit, "total": total},
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
