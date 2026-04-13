from sqlmodel import SQLModel, Field

from .base import utcnow


class Config(SQLModel, table=True):
    __tablename__ = "configs"
    id: int | None = Field(default=None, primary_key=True)
    key: str = Field(nullable=False, unique=True)
    value: str = Field(nullable=False)
    category: str = Field(default="system")
    description: str | None = None
    updated_at: str = Field(default_factory=utcnow)
