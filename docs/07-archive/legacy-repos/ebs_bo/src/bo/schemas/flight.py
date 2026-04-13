from pydantic import BaseModel


class FlightCreate(BaseModel):
    display_name: str
    event_id: int
    start_time: str | None = None
    is_tbd: bool = False
    status: str = "created"


class FlightUpdate(BaseModel):
    display_name: str | None = None
    start_time: str | None = None
    is_tbd: bool | None = None
    status: str | None = None


class FlightRead(BaseModel):
    event_flight_id: int
    event_id: int
    display_name: str
    start_time: str | None
    is_tbd: bool
    status: str
    created_at: str
    updated_at: str
