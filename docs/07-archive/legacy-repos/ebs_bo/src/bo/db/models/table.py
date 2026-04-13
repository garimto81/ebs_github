from sqlmodel import SQLModel, Field, UniqueConstraint, CheckConstraint

from .base import utcnow


class Table(SQLModel, table=True):
    __tablename__ = "tables"
    __table_args__ = (UniqueConstraint("event_flight_id", "name"),)
    table_id: int | None = Field(default=None, primary_key=True)
    event_flight_id: int = Field(foreign_key="event_flights.event_flight_id")
    table_no: int = Field(nullable=False)
    name: str = Field(nullable=False)
    type: str = Field(default="general")
    status: str = Field(default="empty")
    max_players: int = Field(default=9)
    game_type: int = Field(default=0)
    small_blind: int | None = None
    big_blind: int | None = None
    ante_type: int = Field(default=0)
    ante_amount: int = Field(default=0)
    rfid_reader_id: int | None = None
    deck_registered: bool = Field(default=False)
    output_type: str | None = None
    current_game: int | None = None
    delay_seconds: int = Field(default=0)
    ring: int | None = None
    is_breaking_table: bool = Field(default=False)
    source: str = Field(default="manual")
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class TableSeat(SQLModel, table=True):
    __tablename__ = "table_seats"
    __table_args__ = (
        UniqueConstraint("table_id", "seat_no"),
        CheckConstraint("seat_no >= 0 AND seat_no <= 9"),
    )
    seat_id: int | None = Field(default=None, primary_key=True)
    table_id: int = Field(foreign_key="tables.table_id")
    seat_no: int = Field(nullable=False)
    player_id: int | None = Field(default=None, foreign_key="players.player_id")
    wsop_id: str | None = None
    player_name: str | None = None
    nationality: str | None = None
    country_code: str | None = None
    chip_count: int = Field(default=0)
    profile_image: str | None = None
    status: str = Field(default="vacant")
    player_move_status: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
