from sqlmodel import SQLModel, Field, UniqueConstraint

from .base import utcnow


class BlindStructure(SQLModel, table=True):
    __tablename__ = "blind_structures"
    blind_structure_id: int | None = Field(default=None, primary_key=True)
    name: str = Field(nullable=False)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class BlindStructureLevel(SQLModel, table=True):
    __tablename__ = "blind_structure_levels"
    __table_args__ = (UniqueConstraint("blind_structure_id", "level_no"),)
    id: int | None = Field(default=None, primary_key=True)
    blind_structure_id: int = Field(foreign_key="blind_structures.blind_structure_id")
    level_no: int = Field(nullable=False)
    small_blind: int = Field(nullable=False)
    big_blind: int = Field(nullable=False)
    ante: int = Field(default=0)
    duration_minutes: int = Field(nullable=False)
    detail_type: int = Field(default=0)
