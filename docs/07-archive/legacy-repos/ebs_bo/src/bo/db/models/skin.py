from sqlmodel import SQLModel, Field

from .base import utcnow


class Skin(SQLModel, table=True):
    __tablename__ = "skins"
    skin_id: int | None = Field(default=None, primary_key=True)
    name: str = Field(nullable=False, unique=True)
    description: str | None = None
    theme_data: str = Field(default="{}")
    is_default: bool = Field(default=False)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
