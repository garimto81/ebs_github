from sqlmodel import SQLModel, Field

from .base import utcnow


class Series(SQLModel, table=True):
    __tablename__ = "series"
    series_id: int | None = Field(default=None, primary_key=True)
    competition_id: int = Field(foreign_key="competitions.competition_id")
    series_name: str = Field(nullable=False)
    year: int = Field(nullable=False)
    begin_at: str = Field(nullable=False)
    end_at: str = Field(nullable=False)
    image_url: str | None = None
    time_zone: str = Field(default="UTC")
    currency: str = Field(default="USD")
    country_code: str | None = None
    is_completed: bool = Field(default=False)
    is_displayed: bool = Field(default=True)
    is_demo: bool = Field(default=False)
    source: str = Field(default="manual")
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
