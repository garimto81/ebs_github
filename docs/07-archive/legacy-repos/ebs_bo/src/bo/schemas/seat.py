from pydantic import BaseModel


class SeatUpdate(BaseModel):
    player_id: int | None = None
    player_name: str | None = None
    wsop_id: str | None = None
    nationality: str | None = None
    country_code: str | None = None
    chip_count: int | None = None
    status: str | None = None


class SeatRead(BaseModel):
    seat_id: int
    table_id: int
    seat_no: int
    player_id: int | None
    player_name: str | None
    wsop_id: str | None
    chip_count: int
    status: str
