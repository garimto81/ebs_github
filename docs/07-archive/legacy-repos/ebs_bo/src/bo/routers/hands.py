from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Hand, HandAction, HandPlayer, User
from bo.middleware.auth import get_current_user
from bo.schemas.common import ApiResponse
from bo.schemas.hand import HandActionRead, HandPlayerRead, HandRead
from bo.services.crud_service import get_by_id, get_list

router = APIRouter(prefix="/hands", tags=["Hands"])


@router.get("", response_model=ApiResponse[list[HandRead]])
def list_hands(
    page: int = 1,
    limit: int = 20,
    table_id: int | None = None,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    filters = {"table_id": table_id} if table_id else None
    return get_list(session, Hand, page=page, limit=limit, filters=filters)


@router.get("/{hand_id}", response_model=ApiResponse[HandRead])
def get_hand(
    hand_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Hand, hand_id, pk_field="hand_id")
    return ApiResponse(data=item)


@router.get("/{hand_id}/actions", response_model=ApiResponse[list[HandActionRead]])
def get_hand_actions(
    hand_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    actions = session.exec(
        select(HandAction)
        .where(HandAction.hand_id == hand_id)
        .order_by(HandAction.action_order)
    ).all()
    return ApiResponse(data=actions)


@router.get("/{hand_id}/players", response_model=ApiResponse[list[HandPlayerRead]])
def get_hand_players(
    hand_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    players = session.exec(
        select(HandPlayer)
        .where(HandPlayer.hand_id == hand_id)
        .order_by(HandPlayer.seat_no)
    ).all()
    return ApiResponse(data=players)
