from pydantic import BaseModel


class ConfigRead(BaseModel):
    id: int
    key: str
    value: str
    category: str
    description: str | None
    updated_at: str


class ConfigUpdate(BaseModel):
    values: dict[str, str]
