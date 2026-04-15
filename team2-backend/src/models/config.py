"""Config model — DATA-04 §configs (2026-04-15 G4-C scope 확장).

Schema.md §configs SSOT. scope ∈ {global,series,event,table}.
"""
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import CheckConstraint, Index, UniqueConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class Config(SQLModel, table=True):
    __tablename__ = "configs"

    id: Optional[int] = Field(default=None, primary_key=True)
    key: str = Field(nullable=False)
    value: str = Field(nullable=False)
    scope: str = Field(default="global")
    scope_id: Optional[int] = None
    category: str = Field(default="system")
    description: Optional[str] = None
    updated_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("key", "scope", "scope_id", name="uq_configs_key_scope"),
        CheckConstraint(
            "scope IN ('global','series','event','table')",
            name="ck_configs_scope",
        ),
        CheckConstraint(
            "(scope = 'global' AND scope_id IS NULL) "
            "OR (scope != 'global' AND scope_id IS NOT NULL)",
            name="ck_configs_scope_id",
        ),
        Index("idx_configs_lookup", "key", "scope", "scope_id"),
    )
