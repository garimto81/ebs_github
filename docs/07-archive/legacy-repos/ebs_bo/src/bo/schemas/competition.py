from pydantic import BaseModel


class CompetitionCreate(BaseModel):
    name: str
    competition_type: int = 0
    competition_tag: int = 0


class CompetitionUpdate(BaseModel):
    name: str | None = None
    competition_type: int | None = None
    competition_tag: int | None = None


class CompetitionRead(BaseModel):
    competition_id: int
    name: str
    competition_type: int
    competition_tag: int
    created_at: str
    updated_at: str
