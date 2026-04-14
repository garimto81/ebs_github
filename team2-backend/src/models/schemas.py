"""Pydantic request/response schemas for CRUD endpoints."""
from typing import Any, Optional

from pydantic import BaseModel


# ── Common envelope ────────────────────────────────

class ApiResponse(BaseModel):
    data: Any = None
    error: Any = None
    meta: Optional[dict] = None


class ApiError(BaseModel):
    code: str
    message: str


# ── Series ─────────────────────────────────────────

class SeriesCreate(BaseModel):
    competition_id: int
    series_name: str
    year: int
    begin_at: str
    end_at: str
    time_zone: str = "UTC"
    currency: str = "USD"
    country_code: Optional[str] = None
    image_url: Optional[str] = None


class SeriesUpdate(BaseModel):
    series_name: Optional[str] = None
    year: Optional[int] = None
    begin_at: Optional[str] = None
    end_at: Optional[str] = None
    time_zone: Optional[str] = None
    currency: Optional[str] = None
    country_code: Optional[str] = None
    image_url: Optional[str] = None
    is_completed: Optional[bool] = None
    is_displayed: Optional[bool] = None


class SeriesResponse(BaseModel):
    series_id: int
    competition_id: int
    series_name: str
    year: int
    begin_at: str
    end_at: str
    time_zone: str
    currency: str
    country_code: Optional[str] = None
    image_url: Optional[str] = None
    is_completed: bool
    is_displayed: bool
    source: str
    created_at: str
    updated_at: str


# ── Event ──────────────────────────────────────────

class EventCreate(BaseModel):
    series_id: int
    event_no: int
    event_name: str
    buy_in: Optional[int] = None
    display_buy_in: Optional[str] = None
    game_type: int = 0
    bet_structure: int = 0
    game_mode: str = "single"
    table_size: int = 9
    start_time: Optional[str] = None


class EventResponse(BaseModel):
    event_id: int
    series_id: int
    event_no: int
    event_name: str
    buy_in: Optional[int] = None
    game_type: int
    bet_structure: int
    game_mode: str
    table_size: int
    status: str
    start_time: Optional[str] = None
    source: str
    created_at: str
    updated_at: str


# ── Flight ─────────────────────────────────────────

class FlightCreate(BaseModel):
    event_id: int
    display_name: str
    start_time: Optional[str] = None
    is_tbd: bool = False
    play_level: int = 1


class FlightResponse(BaseModel):
    event_flight_id: int
    event_id: int
    display_name: str
    start_time: Optional[str] = None
    is_tbd: bool
    entries: int
    players_left: int
    table_count: int
    status: str
    play_level: int
    source: str
    created_at: str
    updated_at: str


# ── Table ──────────────────────────────────────────

class TableCreate(BaseModel):
    table_no: int
    name: str
    type: str = "general"
    max_players: int = 9
    game_type: int = 0
    delay_seconds: int = 0


class TableResponse(BaseModel):
    table_id: int
    event_flight_id: int
    table_no: int
    name: str
    type: str
    status: str
    max_players: int
    game_type: int
    delay_seconds: int
    source: str
    created_at: str
    updated_at: str


# ── Seat ───────────────────────────────────────────

class SeatUpdate(BaseModel):
    player_id: Optional[int] = None
    status: Optional[str] = None
    chip_count: Optional[int] = None


class SeatResponse(BaseModel):
    seat_id: int
    table_id: int
    seat_no: int
    player_id: Optional[int] = None
    player_name: Optional[str] = None
    nationality: Optional[str] = None
    chip_count: int
    status: str
    created_at: str
    updated_at: str


# ── Player ─────────────────────────────────────────

class PlayerCreate(BaseModel):
    first_name: str
    last_name: str
    wsop_id: Optional[str] = None
    nationality: Optional[str] = None
    country_code: Optional[str] = None


class PlayerUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    wsop_id: Optional[str] = None
    nationality: Optional[str] = None
    country_code: Optional[str] = None


class PlayerResponse(BaseModel):
    player_id: int
    wsop_id: Optional[str] = None
    first_name: str
    last_name: str
    nationality: Optional[str] = None
    country_code: Optional[str] = None
    player_status: str
    source: str
    created_at: str
    updated_at: str
