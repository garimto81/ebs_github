from sqlmodel import SQLModel, Field

from .base import utcnow


class Event(SQLModel, table=True):
    __tablename__ = "events"
    event_id: int | None = Field(default=None, primary_key=True)
    series_id: int = Field(foreign_key="series.series_id")
    event_no: int = Field(nullable=False)
    event_name: str = Field(nullable=False)
    buy_in: int | None = None
    display_buy_in: str | None = None
    game_type: int = Field(default=0)
    bet_structure: int = Field(default=0)
    event_game_type: int = Field(default=0)
    game_mode: str = Field(default="single")
    allowed_games: str | None = None       # JSON text
    rotation_order: str | None = None      # JSON text
    rotation_trigger: str | None = None    # JSON text
    blind_structure_id: int | None = Field(default=None, foreign_key="blind_structures.blind_structure_id")
    starting_chip: int | None = None
    table_size: int = Field(default=9)
    total_entries: int = Field(default=0)
    players_left: int = Field(default=0)
    start_time: str | None = None
    status: str = Field(default="created")
    source: str = Field(default="manual")
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
