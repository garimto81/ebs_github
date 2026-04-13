from sqlmodel import SQLModel, Field

from .base import utcnow


class Player(SQLModel, table=True):
    __tablename__ = "players"
    player_id: int | None = Field(default=None, primary_key=True)
    wsop_id: str | None = Field(default=None, unique=True)
    first_name: str = Field(nullable=False)
    last_name: str = Field(nullable=False)
    nationality: str | None = None
    country_code: str | None = None
    profile_image: str | None = None
    player_status: str = Field(default="active")
    is_demo: bool = Field(default=False)
    source: str = Field(default="manual")
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
