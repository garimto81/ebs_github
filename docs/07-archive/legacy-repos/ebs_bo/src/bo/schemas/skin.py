from pydantic import BaseModel


class SkinCreate(BaseModel):
    name: str
    description: str | None = None
    theme_data: str = "{}"
    is_default: bool = False


class SkinUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    theme_data: str | None = None


class SkinRead(BaseModel):
    skin_id: int
    name: str
    description: str | None
    theme_data: str
    is_default: bool
    created_at: str
    updated_at: str
