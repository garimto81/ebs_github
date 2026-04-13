from pydantic import BaseModel


class PlayerCreate(BaseModel):
    first_name: str
    last_name: str
    wsop_id: str | None = None
    nationality: str | None = None
    country_code: str | None = None
    profile_image: str | None = None


class PlayerUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    wsop_id: str | None = None
    nationality: str | None = None
    country_code: str | None = None
    profile_image: str | None = None
    player_status: str | None = None


class PlayerRead(BaseModel):
    player_id: int
    first_name: str
    last_name: str
    wsop_id: str | None
    nationality: str | None
    country_code: str | None
    player_status: str
    created_at: str
    updated_at: str
