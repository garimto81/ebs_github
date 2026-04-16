"""Hand, HandPlayer, HandAction models — DATA-04 §3."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import UniqueConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class Hand(SQLModel, table=True):
    __tablename__ = "hands"

    hand_id: Optional[int] = Field(default=None, primary_key=True)
    table_id: int = Field(foreign_key="tables.table_id")
    hand_number: int = Field(nullable=False)
    game_type: int = Field(default=0)
    bet_structure: int = Field(default=0)
    dealer_seat: int = Field(default=-1)
    board_cards: str = Field(default="[]")
    pot_total: int = Field(default=0)
    side_pots: str = Field(default="[]")
    current_street: Optional[str] = None
    started_at: str = Field(nullable=False)
    ended_at: Optional[str] = None
    duration_sec: int = Field(default=0)
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("table_id", "hand_number"),
    )


class HandPlayer(SQLModel, table=True):
    __tablename__ = "hand_players"

    id: Optional[int] = Field(default=None, primary_key=True)
    hand_id: int = Field(nullable=False)
    seat_no: int = Field(nullable=False)
    player_id: Optional[int] = None
    player_name: str = Field(nullable=False)
    hole_cards: str = Field(default="[]")
    start_stack: int = Field(default=0)
    end_stack: int = Field(default=0)
    final_action: Optional[str] = None
    is_winner: int = Field(default=0)
    pnl: int = Field(default=0)
    hand_rank: Optional[str] = None
    win_probability: Optional[float] = None
    vpip: int = Field(default=0)
    pfr: int = Field(default=0)
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("hand_id", "seat_no"),
    )


class HandAction(SQLModel, table=True):
    __tablename__ = "hand_actions"

    id: Optional[int] = Field(default=None, primary_key=True)
    hand_id: int = Field(nullable=False)
    seat_no: int = Field(default=0)
    action_type: str = Field(nullable=False)
    action_amount: int = Field(default=0)
    pot_after: Optional[int] = None
    street: str = Field(nullable=False)
    action_order: int = Field(nullable=False)
    board_cards: Optional[str] = None
    action_time: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("hand_id", "action_order"),
    )
