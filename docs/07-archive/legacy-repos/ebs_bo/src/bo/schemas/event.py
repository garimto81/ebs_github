from pydantic import BaseModel


class EventCreate(BaseModel):
    event_name: str
    series_id: int
    event_no: int
    game_type: int = 0
    bet_structure: int = 0
    game_mode: str = "single"
    buy_in: int | None = None
    table_size: int = 9
    starting_chip: int | None = None
    start_time: str | None = None
    status: str = "created"


class EventUpdate(BaseModel):
    event_name: str | None = None
    event_no: int | None = None
    game_type: int | None = None
    bet_structure: int | None = None
    game_mode: str | None = None
    buy_in: int | None = None
    table_size: int | None = None
    starting_chip: int | None = None
    start_time: str | None = None
    status: str | None = None


class EventRead(BaseModel):
    event_id: int
    series_id: int
    event_no: int
    event_name: str
    buy_in: int | None
    game_type: int
    bet_structure: int
    game_mode: str
    table_size: int
    starting_chip: int | None
    start_time: str | None
    status: str
    created_at: str
