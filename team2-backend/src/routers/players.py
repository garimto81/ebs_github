"""Players router — API-01 §5.9 + Cycle 21 (Players_HandHistory_API.md v1.0.0).

GET endpoints (Cycle 21 spec):
  - GET /api/v1/players?event_id=&search=&nationality=&player_status=&limit=&cursor=
    → PlayerListResponse {items, next_cursor, has_more}
  - GET /api/v1/players/{id}?include_stats=true
    → PlayerDetailResponse (PlayerListItem + optional stats)

POST/PUT/DELETE (admin-only) — 기존 ApiResponse 래퍼 유지 (cycle 21 spec 범위 밖).
"""
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    PlayerCreate,
    PlayerDetailResponse,
    PlayerListItem,
    PlayerListResponse,
    PlayerResponse,
    PlayerStats,
    PlayerUpdate,
)
from src.models.user import User
from src.services.player_service import (
    DEFAULT_LIMIT,
    MAX_LIMIT,
    compute_player_stats,
    encode_player_cursor,
    get_player_or_404,
    list_players_with_cursor,
)
from src.services.table_service import (
    create_player,
    delete_player,
    update_player,
)

router = APIRouter(prefix="/api/v1", tags=["players"])


# ── Cycle 21 cursor-based list (spec v1.0.0 §2.1) ──


@router.get("/players", response_model=PlayerListResponse)
def api_list_players(
    event_id: int | None = Query(None, description="Filter by event participation"),
    search: str | None = Query(None, description="first_name/last_name/wsop_id ILIKE"),
    nationality: str | None = Query(None, description="ISO country_code exact match"),
    player_status: str | None = Query(None, description="active/eliminated/away"),
    limit: int = Query(DEFAULT_LIMIT, ge=1, le=MAX_LIMIT),
    cursor: str | None = Query(None, description="base64 {player_id: N} from previous page"),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, next_cursor_pid, has_more = list_players_with_cursor(
        db,
        event_id=event_id,
        search=search,
        nationality=nationality,
        player_status=player_status,
        limit=limit,
        cursor=cursor,
    )
    return PlayerListResponse(
        items=[PlayerListItem.model_validate(p, from_attributes=True) for p in items],
        next_cursor=encode_player_cursor(next_cursor_pid) if next_cursor_pid else None,
        has_more=has_more,
    )


@router.post("/players", status_code=201)
def api_create_player(
    body: PlayerCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    p = create_player(body, db)
    return ApiResponse(data=PlayerResponse.model_validate(p, from_attributes=True))


@router.get("/players/search", response_model=PlayerListResponse)
def api_search_players(
    q: str = Query(""),
    limit: int = Query(DEFAULT_LIMIT, ge=1, le=MAX_LIMIT),
    cursor: str | None = Query(None),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Backwards-compat: ?q= 매핑. 기본 동작은 GET /players?search= 와 동일."""
    items, next_cursor_pid, has_more = list_players_with_cursor(
        db, search=q or None, limit=limit, cursor=cursor,
    )
    return PlayerListResponse(
        items=[PlayerListItem.model_validate(p, from_attributes=True) for p in items],
        next_cursor=encode_player_cursor(next_cursor_pid) if next_cursor_pid else None,
        has_more=has_more,
    )


# ── Cycle 21 detail + optional stats (spec v1.0.0 §2.2) ──


@router.get("/players/{player_id}", response_model=PlayerDetailResponse)
def api_get_player(
    player_id: int,
    include_stats: bool = Query(False, description="누적 통계 포함 여부"),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    p = get_player_or_404(player_id, db)
    base = PlayerDetailResponse.model_validate(p, from_attributes=True)
    if include_stats:
        base.stats = PlayerStats(**compute_player_stats(player_id, db))
    return base


@router.put("/players/{player_id}")
def api_update_player(
    player_id: int,
    body: PlayerUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    p = update_player(player_id, body, db)
    return ApiResponse(data=PlayerResponse.model_validate(p, from_attributes=True))


@router.delete("/players/{player_id}")
def api_delete_player(
    player_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_player(player_id, db)
    return ApiResponse(data={"deleted": True})
