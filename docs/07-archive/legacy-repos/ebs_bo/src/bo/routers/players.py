from fastapi import APIRouter, Depends
from sqlmodel import Session, col, func, or_, select

from bo.db.engine import get_session
from bo.db.models import Player, User
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse, PaginationMeta
from bo.schemas.player import PlayerCreate, PlayerRead, PlayerUpdate
from bo.services.crud_service import create_item, delete_item, get_by_id, get_list, update_item

router = APIRouter(prefix="/players", tags=["Players"])


@router.get("/search", response_model=ApiResponse[list[PlayerRead]])
def search_players(
    q: str = "",
    page: int = 1,
    limit: int = 20,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    """Search players by first or last name. Must be defined before /{player_id}."""
    where_clause = or_(
        col(Player.first_name).ilike(f"%{q}%"),
        col(Player.last_name).ilike(f"%{q}%"),
    )
    total = session.exec(select(func.count()).select_from(Player).where(where_clause)).one()
    offset = (page - 1) * limit
    stmt = select(Player).where(where_clause).offset(offset).limit(limit)
    results = session.exec(stmt).all()
    return ApiResponse(
        data=results,
        meta=PaginationMeta(page=page, limit=limit, total=total),
    )


@router.get("", response_model=ApiResponse[list[PlayerRead]])
def list_players(
    page: int = 1,
    limit: int = 20,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    return get_list(session, Player, page=page, limit=limit)


@router.get("/{player_id}", response_model=ApiResponse[PlayerRead])
def get_player(
    player_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Player, player_id, pk_field="player_id")
    return ApiResponse(data=item)


@router.post("", response_model=ApiResponse[PlayerRead], status_code=201)
def create_player(
    body: PlayerCreate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = create_item(session, Player, body.model_dump())
    return ApiResponse(data=item)


@router.put("/{player_id}", response_model=ApiResponse[PlayerRead])
def update_player(
    player_id: int,
    body: PlayerUpdate,
    _: User = Depends(require_role("admin", "operator")),
    session: Session = Depends(get_session),
):
    item = update_item(
        session, Player, player_id,
        body.model_dump(exclude_unset=True), pk_field="player_id",
    )
    return ApiResponse(data=item)


@router.delete("/{player_id}", response_model=ApiResponse[dict])
def delete_player(
    player_id: int,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    result = delete_item(session, Player, player_id, pk_field="player_id")
    return ApiResponse(data=result)
