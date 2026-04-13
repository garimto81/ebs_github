from sqlmodel import SQLModel, Field, UniqueConstraint

from .base import utcnow


class Hand(SQLModel, table=True):
    __tablename__ = "hands"
    __table_args__ = (UniqueConstraint("table_id", "hand_number"),)
    hand_id: int | None = Field(default=None, primary_key=True)
    table_id: int = Field(foreign_key="tables.table_id")
    hand_number: int = Field(nullable=False)
    game_type: int = Field(default=0)
    bet_structure: int = Field(default=0)
    dealer_seat: int = Field(default=-1)
    board_cards: str = Field(default="[]")
    pot_total: int = Field(default=0)
    side_pots: str = Field(default="[]")
    current_street: str | None = None
    started_at: str = Field(nullable=False)
    ended_at: str | None = None
    duration_sec: int = Field(default=0)
    created_at: str = Field(default_factory=utcnow)


class HandPlayer(SQLModel, table=True):
    __tablename__ = "hand_players"
    __table_args__ = (UniqueConstraint("hand_id", "seat_no"),)
    id: int | None = Field(default=None, primary_key=True)
    hand_id: int = Field(foreign_key="hands.hand_id")
    seat_no: int = Field(nullable=False)
    player_id: int | None = Field(default=None, foreign_key="players.player_id")
    player_name: str = Field(nullable=False)
    hole_cards: str = Field(default="[]")
    start_stack: int = Field(default=0)
    end_stack: int = Field(default=0)
    final_action: str | None = None
    is_winner: bool = Field(default=False)
    pnl: int = Field(default=0)
    hand_rank: str | None = None
    win_probability: float | None = None
    vpip: bool = Field(default=False)
    pfr: bool = Field(default=False)
    created_at: str = Field(default_factory=utcnow)


class HandAction(SQLModel, table=True):
    __tablename__ = "hand_actions"
    __table_args__ = (UniqueConstraint("hand_id", "action_order"),)
    id: int | None = Field(default=None, primary_key=True)
    hand_id: int = Field(foreign_key="hands.hand_id")
    seat_no: int = Field(default=0)
    action_type: str = Field(nullable=False)
    action_amount: int = Field(default=0)
    pot_after: int | None = None
    street: str = Field(nullable=False)
    action_order: int = Field(nullable=False)
    board_cards: str | None = None
    action_time: str | None = None
    created_at: str = Field(default_factory=utcnow)
