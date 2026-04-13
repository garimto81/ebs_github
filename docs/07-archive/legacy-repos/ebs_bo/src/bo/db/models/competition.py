from sqlmodel import SQLModel, Field

from .base import utcnow


class Competition(SQLModel, table=True):
    __tablename__ = "competitions"
    competition_id: int | None = Field(default=None, primary_key=True)
    name: str = Field(nullable=False)
    competition_type: int = Field(default=0)
    competition_tag: int = Field(default=0)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
