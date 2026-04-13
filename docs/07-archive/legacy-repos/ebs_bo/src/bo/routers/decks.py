import json

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Deck, Table, User
from bo.db.models.base import utcnow
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.services.audit_service import record_audit

router = APIRouter(prefix="/tables/{table_id}/decks", tags=["Decks"])

SUITS = ["c", "d", "h", "s"]
RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]


def _generate_mock_card_map() -> str:
    cards = []
    for si, suit in enumerate(SUITS):
        for ri, rank in enumerate(RANKS):
            cards.append({
                "suit": si, "rank": ri,
                "uid": f"MOCK-{si}{ri:02d}",
                "display": f"{rank}{suit}",
            })
    return json.dumps(cards)


@router.post("", response_model=ApiResponse, status_code=201)
def create_deck(
    table_id: int,
    body: dict | None = None,
    current_user: User = Depends(require_role("admin", "operator")),
    session: Session = Depends(get_session),
):
    table = session.get(Table, table_id)
    if not table:
        raise HTTPException(404, "테이블을 찾을 수 없습니다")
    if table.type != "feature":
        raise HTTPException(400, "Feature Table만 덱 등록 가능")
    if table.status == "empty":
        raise HTTPException(400, "SETUP 이상에서만 등록 가능")

    mock = (body or {}).get("mock", False)
    if mock:
        deck = Deck(
            table_id=table_id,
            label=f"Mock Deck - Table {table_id}",
            status="mock",
            card_map=_generate_mock_card_map(),
            scanned_count=52,
            registered_count=52,
            registered_at=utcnow(),
            registered_by=current_user.user_id,
        )
    else:
        deck = Deck(
            table_id=table_id,
            label=f"Deck - Table {table_id}",
            status="registering",
            scanned_count=0,
            registered_by=current_user.user_id,
        )
    session.add(deck)
    session.commit()
    session.refresh(deck)
    record_audit(session, user_id=current_user.user_id, action="deck.create", entity_type="deck", entity_id=deck.deck_id)
    return ApiResponse(data=deck)


@router.get("", response_model=ApiResponse[list])
def list_decks(
    table_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    decks = session.exec(
        select(Deck).where(Deck.table_id == table_id).order_by(Deck.deck_id.desc())
    ).all()
    return ApiResponse(data=decks)


@router.get("/active", response_model=ApiResponse)
def get_active_deck(
    table_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    deck = session.exec(
        select(Deck).where(
            Deck.table_id == table_id,
            Deck.deactivated_at.is_(None),
        ).order_by(Deck.deck_id.desc())
    ).first()
    if not deck:
        raise HTTPException(404, "활성 덱이 없습니다")
    return ApiResponse(data=deck)


@router.delete("/{deck_id}", response_model=ApiResponse[dict])
def deactivate_deck(
    table_id: int,
    deck_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    table = session.get(Table, table_id)
    if table and table.status == "live":
        raise HTTPException(403, "핸드 종료 후 교체 가능")
    deck = session.get(Deck, deck_id)
    if not deck or deck.table_id != table_id:
        raise HTTPException(404, "덱을 찾을 수 없습니다")
    deck.deactivated_at = utcnow()
    session.add(deck)
    session.commit()
    record_audit(session, user_id=current_user.user_id, action="deck.deactivate", entity_type="deck", entity_id=deck_id)
    return ApiResponse(data={"deck_id": deck_id, "deactivated": True})
