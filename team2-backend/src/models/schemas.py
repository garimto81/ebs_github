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


# ── User ──────────────────────────────────────────

class UserCreate(BaseModel):
    email: str
    password: str
    display_name: str
    role: str = "viewer"


class UserUpdate(BaseModel):
    email: Optional[str] = None
    display_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None


class UserResponse(BaseModel):
    user_id: int
    email: str
    display_name: str
    role: str
    is_active: bool
    totp_enabled: bool
    last_login_at: Optional[str] = None
    created_at: str
    updated_at: str


# ── Config ────────────────────────────────────────

class ConfigResponse(BaseModel):
    id: int
    key: str
    value: str
    scope: str
    scope_id: Optional[int] = None
    category: str
    description: Optional[str] = None
    updated_at: str


class ConfigUpdate(BaseModel):
    value: str
    description: Optional[str] = None


class ConfigBulkItem(BaseModel):
    key: str
    value: str
    scope: Optional[str] = None
    scope_id: Optional[int] = None
    description: Optional[str] = None


# ── Competition ───────────────────────────────────

class CompetitionCreate(BaseModel):
    name: str
    competition_type: int = 0
    competition_tag: int = 0


class CompetitionUpdate(BaseModel):
    name: Optional[str] = None
    competition_type: Optional[int] = None
    competition_tag: Optional[int] = None


class CompetitionResponse(BaseModel):
    competition_id: int
    name: str
    competition_type: int
    competition_tag: int
    created_at: str
    updated_at: str


# ── Event / Flight Update ────────────────────────

class EventUpdate(BaseModel):
    event_name: Optional[str] = None
    buy_in: Optional[int] = None
    game_type: Optional[int] = None
    bet_structure: Optional[int] = None
    game_mode: Optional[str] = None
    table_size: Optional[int] = None
    start_time: Optional[str] = None
    status: Optional[str] = None


class FlightUpdate(BaseModel):
    display_name: Optional[str] = None
    start_time: Optional[str] = None
    is_tbd: Optional[bool] = None
    play_level: Optional[int] = None
    status: Optional[str] = None


# ── Table Update ─────────────────────────────────

class TableUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    max_players: Optional[int] = None
    game_type: Optional[int] = None
    delay_seconds: Optional[int] = None
    status: Optional[str] = None


# ── Skin ─────────────────────────────────────────

class SkinCreate(BaseModel):
    name: str
    description: Optional[str] = None
    theme_data: str = "{}"


class SkinUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    theme_data: Optional[str] = None


class SkinResponse(BaseModel):
    skin_id: int
    name: str
    description: Optional[str] = None
    theme_data: str
    is_default: bool
    created_at: str
    updated_at: str


# ── Hand ──────────────────────────────────────────

class HandResponse(BaseModel):
    hand_id: int
    table_id: int
    hand_number: int
    game_type: int
    bet_structure: int
    dealer_seat: int
    board_cards: str
    pot_total: int
    side_pots: str
    current_street: Optional[str] = None
    started_at: str
    ended_at: Optional[str] = None
    duration_sec: int
    created_at: str


class HandPlayerResponse(BaseModel):
    id: int
    hand_id: int
    seat_no: int
    player_id: Optional[int] = None
    player_name: str
    hole_cards: str
    start_stack: int
    end_stack: int
    final_action: Optional[str] = None
    is_winner: int
    pnl: int
    hand_rank: Optional[str] = None
    created_at: str


class HandActionResponse(BaseModel):
    id: int
    hand_id: int
    seat_no: int
    action_type: str
    action_amount: int
    pot_after: Optional[int] = None
    street: str
    action_order: int
    action_time: Optional[str] = None
    created_at: str


# ── BlindStructure ────────────────────────────────

class BlindStructureLevelCreate(BaseModel):
    level_no: int
    small_blind: int
    big_blind: int
    ante: int = 0
    duration_minutes: int
    detail_type: int = 0


class BlindStructureLevelResponse(BaseModel):
    id: int
    blind_structure_id: int
    level_no: int
    small_blind: int
    big_blind: int
    ante: int
    duration_minutes: int
    detail_type: int


class BlindStructureCreate(BaseModel):
    name: str
    levels: list[BlindStructureLevelCreate]


class BlindStructureUpdate(BaseModel):
    name: Optional[str] = None
    levels: Optional[list[BlindStructureLevelCreate]] = None


class BlindStructureResponse(BaseModel):
    blind_structure_id: int
    name: str
    levels: list[BlindStructureLevelResponse]
    created_at: str
    updated_at: str


class BlindStructureApply(BaseModel):
    blind_structure_id: int


# ── PayoutStructure ──────────────────────────────────

class PayoutStructureLevelCreate(BaseModel):
    position_from: int
    position_to: int
    payout_pct: float
    payout_amount: Optional[int] = None


class PayoutStructureLevelResponse(BaseModel):
    id: int
    payout_structure_id: int
    position_from: int
    position_to: int
    payout_pct: float
    payout_amount: Optional[int] = None


class PayoutStructureCreate(BaseModel):
    name: str
    levels: list[PayoutStructureLevelCreate]


class PayoutStructureUpdate(BaseModel):
    name: Optional[str] = None
    levels: Optional[list[PayoutStructureLevelCreate]] = None


class PayoutStructureResponse(BaseModel):
    payout_structure_id: int
    name: str
    levels: list[PayoutStructureLevelResponse]
    created_at: str
    updated_at: str


# ── Clock ────────────────────────────────────────────

class ClockState(BaseModel):
    event_flight_id: int
    status: str
    play_level: int
    remain_time: Optional[int] = None


class ClockAdjust(BaseModel):
    level_diff: int = 0
    time_diff: int = 0


# ── Rebalance ───────────────────────────────────────

class RebalanceRequest(BaseModel):
    event_flight_id: int
    strategy: str = "balanced"
    target_players_per_table: int = 9
    dry_run: bool = False
