"""Skin model — overlay theme/skin management."""
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class Skin(SQLModel, table=True):
    __tablename__ = "skins"

    skin_id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(nullable=False, unique=True)
    description: Optional[str] = None
    theme_data: str = Field(default="{}")
    is_default: bool = Field(default=False)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
