"""Competition hierarchy models — DATA-04 §1."""
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class Competition(SQLModel, table=True):
    __tablename__ = "competitions"

    competition_id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(nullable=False)
    competition_type: int = Field(default=0)  # enum 0-4
    competition_tag: int = Field(default=0)   # enum 0-3
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class Series(SQLModel, table=True):
    __tablename__ = "series"

    series_id: Optional[int] = Field(default=None, primary_key=True)
    competition_id: int = Field(foreign_key="competitions.competition_id")
    series_name: str = Field(nullable=False)
    year: int = Field(nullable=False)
    begin_at: str = Field(nullable=False)       # DATE ISO
    end_at: str = Field(nullable=False)         # DATE ISO
    image_url: Optional[str] = None
    time_zone: str = Field(default="UTC")
    currency: str = Field(default="USD")
    country_code: Optional[str] = None
    is_completed: bool = Field(default=False)
    is_displayed: bool = Field(default=True)
    is_demo: bool = Field(default=False)
    source: str = Field(default="manual")       # 'manual' | 'api'
    synced_at: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class Event(SQLModel, table=True):
    __tablename__ = "events"

    event_id: Optional[int] = Field(default=None, primary_key=True)
    series_id: int = Field(foreign_key="series.series_id")
    event_no: int = Field(nullable=False)
    event_name: str = Field(nullable=False)
    buy_in: Optional[int] = None
    display_buy_in: Optional[str] = None
    game_type: int = Field(default=0)           # enum 0-21
    bet_structure: int = Field(default=0)       # enum 0-2
    event_game_type: int = Field(default=0)     # enum 0-8
    game_mode: str = Field(default="single")    # single|fixed_rotation|dealers_choice
    allowed_games: Optional[str] = None         # TEXT (JSON serialized)
    rotation_order: Optional[str] = None        # TEXT (JSON serialized)
    rotation_trigger: Optional[str] = None      # TEXT (JSON serialized)
    blind_structure_id: Optional[int] = None
    starting_chip: Optional[int] = None
    table_size: int = Field(default=9)
    total_entries: int = Field(default=0)
    players_left: int = Field(default=0)
    start_time: Optional[str] = None            # DATETIME ISO
    status: str = Field(default="created")      # EventFSM
    source: str = Field(default="manual")
    synced_at: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class EventFlight(SQLModel, table=True):
    __tablename__ = "event_flights"

    event_flight_id: Optional[int] = Field(default=None, primary_key=True)
    event_id: int = Field(foreign_key="events.event_id")
    display_name: str = Field(nullable=False)
    start_time: Optional[str] = None
    is_tbd: bool = Field(default=False)
    entries: int = Field(default=0)
    players_left: int = Field(default=0)
    table_count: int = Field(default=0)
    status: str = Field(default="created")
    play_level: int = Field(default=1)
    remain_time: Optional[int] = None
    source: str = Field(default="manual")
    synced_at: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
