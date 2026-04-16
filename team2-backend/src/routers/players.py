"""Players router — API-01 §5.9."""
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    PlayerCreate,
    PlayerResponse,
    PlayerUpdate,
)
from src.models.user import User
from src.services.table_service import (
    create_player,
    delete_player,
    get_player,
    list_players,
    update_player,
)

router = APIRouter(prefix="/api/v1", tags=["players"])


@router.get("/players")
def api_list_players(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    search: str | None = Query(None),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_players(db, skip, limit, search)
    return ApiResponse(
        data=[PlayerResponse.model_validate(p, from_attributes=True) for p in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/players", status_code=201)
def api_create_player(
    body: PlayerCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    p = create_player(body, db)
    return ApiResponse(data=PlayerResponse.model_validate(p, from_attributes=True))


@router.get("/players/search")
def api_search_players(
    q: str = Query(""),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_players(db, skip, limit, q or None)
    return ApiResponse(
        data=[PlayerResponse.model_validate(p, from_attributes=True) for p in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.get("/players/{player_id}")
def api_get_player(
    player_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    p = get_player(player_id, db)
    return ApiResponse(data=PlayerResponse.model_validate(p, from_attributes=True))


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
