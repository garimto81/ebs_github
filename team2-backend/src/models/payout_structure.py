"""PayoutStructure, PayoutStructureLevel models."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import UniqueConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class PayoutStructure(SQLModel, table=True):
    __tablename__ = "payout_structures"

    payout_structure_id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(nullable=False)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class PayoutStructureLevel(SQLModel, table=True):
    __tablename__ = "payout_structure_levels"

    id: Optional[int] = Field(default=None, primary_key=True)
    payout_structure_id: int = Field(
        foreign_key="payout_structures.payout_structure_id"
    )
    position_from: int = Field(nullable=False)
    position_to: int = Field(nullable=False)
    payout_pct: float = Field(nullable=False)  # 0.0-100.0 percentage
    payout_amount: Optional[int] = None  # fixed amount (alternative to pct)

    __table_args__ = (
        UniqueConstraint("payout_structure_id", "position_from"),
    )
