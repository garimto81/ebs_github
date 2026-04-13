from sqlmodel import SQLModel, Field

from .base import utcnow


class EventFlight(SQLModel, table=True):
    __tablename__ = "event_flights"
    event_flight_id: int | None = Field(default=None, primary_key=True)
    event_id: int = Field(foreign_key="events.event_id")
    display_name: str = Field(nullable=False)
    start_time: str | None = None
    is_tbd: bool = Field(default=False)
    entries: int = Field(default=0)
    players_left: int = Field(default=0)
    table_count: int = Field(default=0)
    status: str = Field(default="created")
    play_level: int = Field(default=1)
    remain_time: int | None = None
    source: str = Field(default="manual")
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
