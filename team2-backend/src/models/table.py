"""Table, TableSeat, Player models — DATA-04 §2."""
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import CheckConstraint, UniqueConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


# ── SeatStatus valid transitions (IMPL-10 / DATA-04) ──

VALID_SEAT_TRANSITIONS: dict[str, list[str]] = {
    "empty": ["new", "reserved"],
    "new": ["playing"],
    "playing": ["busted"],
    "busted": ["empty"],
    "moved": ["empty"],
    "reserved": ["empty"],
}


class Table(SQLModel, table=True):
    __tablename__ = "tables"

    table_id: Optional[int] = Field(default=None, primary_key=True)
    event_flight_id: int = Field(foreign_key="event_flights.event_flight_id")
    table_no: int = Field(nullable=False)
    name: str = Field(nullable=False)
    type: str = Field(default="general")        # 'feature' | 'general'
    status: str = Field(default="empty")        # TableFSM
    max_players: int = Field(default=9)
    game_type: int = Field(default=0)
    small_blind: Optional[int] = None
    big_blind: Optional[int] = None
    ante_type: int = Field(default=0)
    ante_amount: int = Field(default=0)
    rfid_reader_id: Optional[int] = None
    deck_registered: bool = Field(default=False)
    output_type: Optional[str] = None
    current_game: Optional[int] = None
    delay_seconds: int = Field(default=0)
    ring: Optional[int] = None
    is_breaking_table: bool = Field(default=False)
    source: str = Field(default="manual")
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("event_flight_id", "name"),
    )


class Player(SQLModel, table=True):
    __tablename__ = "players"

    player_id: Optional[int] = Field(default=None, primary_key=True)
    wsop_id: Optional[str] = Field(default=None, unique=True)
    first_name: str = Field(nullable=False)
    last_name: str = Field(nullable=False)
    nationality: Optional[str] = None
    country_code: Optional[str] = None
    profile_image: Optional[str] = None
    player_status: str = Field(default="active")
    is_demo: bool = Field(default=False)
    source: str = Field(default="manual")
    synced_at: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class TableSeat(SQLModel, table=True):
    __tablename__ = "table_seats"

    seat_id: Optional[int] = Field(default=None, primary_key=True)
    table_id: int = Field(foreign_key="tables.table_id")
    seat_no: int = Field(nullable=False)        # 0-9
    player_id: Optional[int] = Field(
        default=None, foreign_key="players.player_id"
    )
    wsop_id: Optional[str] = None
    player_name: Optional[str] = None
    nationality: Optional[str] = None
    country_code: Optional[str] = None
    chip_count: int = Field(default=0)
    profile_image: Optional[str] = None
    status: str = Field(default="empty")        # SeatStatus enum
    player_move_status: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("table_id", "seat_no"),
        CheckConstraint("seat_no >= 0 AND seat_no <= 9"),
    )
