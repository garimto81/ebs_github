"""Hand / HandPlayer / HandAction read-only service."""
from __future__ import annotations

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.hand import Hand, HandAction, HandPlayer

# ── Hand queries ───────────────────────────────────


def list_hands(
    table_id: int, db: Session, skip: int = 0, limit: int = 20
) -> tuple[list[Hand], int]:
    stmt = select(Hand).where(Hand.table_id == table_id)
    total = len(db.exec(stmt).all())
    items = db.exec(stmt.offset(skip).limit(limit)).all()
    return items, total


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
