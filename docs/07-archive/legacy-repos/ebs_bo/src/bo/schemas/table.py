from pydantic import BaseModel


class TableCreate(BaseModel):
    name: str
    event_flight_id: int
    table_no: int
    type: str = "general"
    max_players: int = 9
    game_type: int = 0
    small_blind: int | None = None
    big_blind: int | None = None
    delay_seconds: int = 0
    status: str = "empty"


class TableUpdate(BaseModel):
    name: str | None = None
    table_no: int | None = None
    type: str | None = None
    max_players: int | None = None
    game_type: int | None = None
    small_blind: int | None = None
    big_blind: int | None = None
    delay_seconds: int | None = None
    status: str | None = None


class TableRead(BaseModel):
    table_id: int
    event_flight_id: int
    table_no: int
    name: str
    type: str
    status: str
    max_players: int
    game_type: int
    small_blind: int | None
    big_blind: int | None
    delay_seconds: int
    created_at: str
    updated_at: str


class TableStatusRead(BaseModel):
    table_id: int
    status: str
    deck_registered: bool
    current_game: int | None
