"""Pydantic request/response schemas for CRUD endpoints.

B-088 PR 2 (2026-04-21): 모든 class 가 `EbsBaseModel` 을 상속하여
외부 JSON camelCase / 내부 Python snake_case 양립.

- `alias_generator=to_camel` 로 외부 직렬화 camelCase
- `populate_by_name=True` 로 request 는 양 형식 모두 수용
- `from_attributes=True` 로 ORM/SQLModel 에서 직접 변환

단일 단어 field (`data`, `error`, `meta`, `code`, `message`) 는 to_camel 이 동일 키로 반환.
"""
from typing import Any, Optional

from src.models.base import EbsBaseModel

# ── Common envelope ────────────────────────────────

class ApiResponse(EbsBaseModel):
    data: Any = None
    error: Any = None
    meta: Optional[dict] = None


class ApiError(EbsBaseModel):
    code: str
    message: str


# ── Series ─────────────────────────────────────────

class SeriesCreate(EbsBaseModel):
    competition_id: int
    series_name: str
    year: int
    begin_at: str
    end_at: str
    time_zone: str = "UTC"
    currency: str = "USD"
    country_code: Optional[str] = None
    image_url: Optional[str] = None


class SeriesUpdate(EbsBaseModel):
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


class SeriesResponse(EbsBaseModel):
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

class EventCreate(EbsBaseModel):
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


class EventResponse(EbsBaseModel):
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

class FlightCreate(EbsBaseModel):
    event_id: int
    display_name: str
    start_time: Optional[str] = None
    is_tbd: bool = False
    play_level: int = 1


class FlightResponse(EbsBaseModel):
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

class TableCreate(EbsBaseModel):
    table_no: int
    name: str
    type: str = "general"
    max_players: int = 9
    game_type: int = 0
    delay_seconds: int = 0
    event_flight_id: Optional[int] = None  # required for flat POST /tables; nested path supplies via URL


class TableResponse(EbsBaseModel):
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

class SeatUpdate(EbsBaseModel):
    seat_no: Optional[int] = None  # V9.5 P7: required for POST /tables/{id}/seats (assign)
    player_id: Optional[int] = None
    status: Optional[str] = None
    chip_count: Optional[int] = None


class SeatResponse(EbsBaseModel):
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

class PlayerCreate(EbsBaseModel):
    first_name: str
    last_name: str
    wsop_id: Optional[str] = None
    nationality: Optional[str] = None
    country_code: Optional[str] = None


class PlayerUpdate(EbsBaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    wsop_id: Optional[str] = None
    nationality: Optional[str] = None
    country_code: Optional[str] = None


class PlayerResponse(EbsBaseModel):
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

class UserCreate(EbsBaseModel):
    email: str
    password: str
    display_name: str
    role: str = "viewer"


class UserUpdate(EbsBaseModel):
    email: Optional[str] = None
    display_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None


class UserResponse(EbsBaseModel):
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

class ConfigResponse(EbsBaseModel):
    id: int
    key: str
    value: str
    scope: str
    scope_id: Optional[int] = None
    category: str
    description: Optional[str] = None
    updated_at: str


class ConfigUpdate(EbsBaseModel):
    value: str
    description: Optional[str] = None


class ConfigBulkItem(EbsBaseModel):
    key: str
    value: str
    scope: Optional[str] = None
    scope_id: Optional[int] = None
    description: Optional[str] = None


# ── Competition ───────────────────────────────────

class CompetitionCreate(EbsBaseModel):
    name: str
    competition_type: int = 0
    competition_tag: int = 0


class CompetitionUpdate(EbsBaseModel):
    name: Optional[str] = None
    competition_type: Optional[int] = None
    competition_tag: Optional[int] = None


class CompetitionResponse(EbsBaseModel):
    competition_id: int
    name: str
    competition_type: int
    competition_tag: int
    created_at: str
    updated_at: str


# ── Event / Flight Update ────────────────────────

class EventUpdate(EbsBaseModel):
    event_name: Optional[str] = None
    buy_in: Optional[int] = None
    game_type: Optional[int] = None
    bet_structure: Optional[int] = None
    game_mode: Optional[str] = None
    table_size: Optional[int] = None
    start_time: Optional[str] = None
    status: Optional[str] = None


class FlightUpdate(EbsBaseModel):
    display_name: Optional[str] = None
    start_time: Optional[str] = None
    is_tbd: Optional[bool] = None
    play_level: Optional[int] = None
    status: Optional[str] = None


# ── Table Update ─────────────────────────────────

class TableUpdate(EbsBaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    max_players: Optional[int] = None
    game_type: Optional[int] = None
    delay_seconds: Optional[int] = None
    status: Optional[str] = None


# ── Skin ─────────────────────────────────────────

class SkinCreate(EbsBaseModel):
    name: str
    description: Optional[str] = None
    theme_data: str = "{}"


class SkinUpdate(EbsBaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    theme_data: Optional[str] = None


class SkinResponse(EbsBaseModel):
    skin_id: int
    name: str
    description: Optional[str] = None
    theme_data: str
    is_default: bool
    created_at: str
    updated_at: str


# ── BrandPack (Cycle 17 — 사용자 표 #6) ─────────────
# SSOT: docs/1. Product/RIVE_Standards.md Ch.7 — 컬러 팔레트, 폰트, 로고 (3종), 모티프

class BrandPackCreate(EbsBaseModel):
    name: str
    display_name: str
    primary_color: str
    secondary_color: str
    accent_color: str
    font_family: Optional[str] = None
    logo_primary_url: Optional[str] = None
    logo_secondary_url: Optional[str] = None
    logo_tertiary_url: Optional[str] = None
    motif_data: str = "{}"
    is_default: bool = False


class BrandPackUpdate(EbsBaseModel):
    name: Optional[str] = None
    display_name: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_color: Optional[str] = None
    accent_color: Optional[str] = None
    font_family: Optional[str] = None
    logo_primary_url: Optional[str] = None
    logo_secondary_url: Optional[str] = None
    logo_tertiary_url: Optional[str] = None
    motif_data: Optional[str] = None
    is_default: Optional[bool] = None


class BrandPackResponse(EbsBaseModel):
    brand_pack_id: int
    name: str
    display_name: str
    primary_color: str
    secondary_color: str
    accent_color: str
    font_family: Optional[str] = None
    logo_primary_url: Optional[str] = None
    logo_secondary_url: Optional[str] = None
    logo_tertiary_url: Optional[str] = None
    motif_data: str
    is_default: bool
    created_at: str
    updated_at: str


# ── Hand ──────────────────────────────────────────

class HandResponse(EbsBaseModel):
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


class HandPlayerResponse(EbsBaseModel):
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


class HandActionResponse(EbsBaseModel):
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

class BlindStructureLevelCreate(EbsBaseModel):
    level_no: int
    small_blind: int
    big_blind: int
    ante: int = 0
    duration_minutes: int
    detail_type: int = 0


class BlindStructureLevelResponse(EbsBaseModel):
    id: int
    blind_structure_id: int
    level_no: int
    small_blind: int
    big_blind: int
    ante: int
    duration_minutes: int
    detail_type: int


class BlindStructureLevelUpdate(EbsBaseModel):
    """V9.5 Phase 3: individual level CRUD (separate from BlindStructureUpdate)."""
    level_no: Optional[int] = None
    small_blind: Optional[int] = None
    big_blind: Optional[int] = None
    ante: Optional[int] = None
    duration_minutes: Optional[int] = None
    detail_type: Optional[int] = None


class BlindStructureCreate(EbsBaseModel):
    name: str
    levels: list[BlindStructureLevelCreate]


class BlindStructureUpdate(EbsBaseModel):
    name: Optional[str] = None
    levels: Optional[list[BlindStructureLevelCreate]] = None


class BlindStructureResponse(EbsBaseModel):
    blind_structure_id: int
    name: str
    levels: list[BlindStructureLevelResponse]
    created_at: str
    updated_at: str


class BlindStructureApply(EbsBaseModel):
    blind_structure_id: int


# ── PayoutStructure ──────────────────────────────────

class PayoutStructureLevelCreate(EbsBaseModel):
    position_from: int
    position_to: int
    payout_pct: float
    payout_amount: Optional[int] = None


class PayoutStructureLevelResponse(EbsBaseModel):
    id: int
    payout_structure_id: int
    position_from: int
    position_to: int
    payout_pct: float
    payout_amount: Optional[int] = None


class PayoutStructureCreate(EbsBaseModel):
    name: str
    levels: list[PayoutStructureLevelCreate]


class PayoutStructureUpdate(EbsBaseModel):
    name: Optional[str] = None
    levels: Optional[list[PayoutStructureLevelCreate]] = None


class PayoutStructureResponse(EbsBaseModel):
    payout_structure_id: int
    name: str
    levels: list[PayoutStructureLevelResponse]
    created_at: str
    updated_at: str


# ── Clock ────────────────────────────────────────────

class ClockState(EbsBaseModel):
    event_flight_id: int
    status: str
    play_level: int
    remain_time: Optional[int] = None


class ClockAdjust(EbsBaseModel):
    level_diff: int = 0
    time_diff: int = 0


# ── Rebalance ───────────────────────────────────────

class RebalanceRequest(EbsBaseModel):
    event_flight_id: int
    strategy: str = "balanced"
    target_players_per_table: int = 9
    dry_run: bool = False
