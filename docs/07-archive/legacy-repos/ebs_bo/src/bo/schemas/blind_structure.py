from pydantic import BaseModel


class BlindLevelInput(BaseModel):
    level_no: int
    small_blind: int
    big_blind: int
    ante: int = 0
    duration_minutes: int


class BlindStructureCreate(BaseModel):
    name: str
    levels: list[BlindLevelInput] = []


class BlindStructureUpdate(BaseModel):
    name: str | None = None
    levels: list[BlindLevelInput] | None = None


class BlindLevelRead(BaseModel):
    id: int
    level_no: int
    small_blind: int
    big_blind: int
    ante: int
    duration_minutes: int


class BlindStructureRead(BaseModel):
    blind_structure_id: int
    name: str
    created_at: str
    updated_at: str
