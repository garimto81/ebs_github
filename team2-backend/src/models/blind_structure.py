"""BlindStructure, BlindStructureLevel models — DATA-04 §4+."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import CheckConstraint, UniqueConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class BlindStructure(SQLModel, table=True):
    __tablename__ = "blind_structures"

    blind_structure_id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(nullable=False)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class BlindStructureLevel(SQLModel, table=True):
    __tablename__ = "blind_structure_levels"

    id: Optional[int] = Field(default=None, primary_key=True)
    blind_structure_id: int = Field(
        foreign_key="blind_structures.blind_structure_id"
    )
    level_no: int = Field(nullable=False)
    small_blind: int = Field(nullable=False)
    big_blind: int = Field(nullable=False)
    ante: int = Field(default=0)
    duration_minutes: int = Field(nullable=False)
    detail_type: int = Field(default=0)

    __table_args__ = (
        UniqueConstraint("blind_structure_id", "level_no"),
        CheckConstraint("detail_type IN (0, 1, 2, 3, 4)"),
    )
