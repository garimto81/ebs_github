"""SG-006 RFID Decks Router — 52 카드 pre-registered deck 관리.

Endpoints:
  POST   /api/v1/decks                  — create deck (initial registration)
  GET    /api/v1/decks                  — list decks
  GET    /api/v1/decks/{deck_id}        — get deck + cards
  POST   /api/v1/decks/{deck_id}/cards  — register one card (scan-based mode)
  POST   /api/v1/decks/import           — bulk JSON import (vendor-provided map)
  PATCH  /api/v1/decks/{deck_id}/cards/{card_code}  — replace damaged card UID
  PATCH  /api/v1/decks/{deck_id}        — update deck status (retire)
  DELETE /api/v1/decks/{deck_id}        — hard delete (Admin only)

Spec: docs/4. Operations/Conductor_Backlog/SG-006-rfid-52-card-codemap.md

team2 session TODO markers:
  [TODO-T2-004] wire to db.session dependency (currently stub)
  [TODO-T2-005] RBAC guard: Admin required for create/delete, Operator for scan
  [TODO-T2-006] cross-deck UID uniqueness enforcement in scan path
  [TODO-T2-007] audit_events integration (deck_created, card_replaced, deck_retired)
  [TODO-T2-008] Demo deck auto-seed on first boot (SG-002 연계)
"""
from __future__ import annotations

from datetime import datetime
from typing import Literal

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/v1/decks", tags=["decks"])


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

DeckStatus = Literal["active", "retired", "damaged", "registering", "partial"]

VALID_CARD_CODES = frozenset(
    f"{r}{s}"
    for r in ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]
    for s in ["S", "H", "D", "C"]
)


class DeckCreateIn(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    notes: str | None = None


class DeckCardOut(BaseModel):
    card_code: str
    rfid_uid: str
    registered_at: datetime
    registered_by: str | None


class DeckOut(BaseModel):
    id: str
    name: str
    status: DeckStatus
    created_at: datetime
    notes: str | None
    cards_registered: int = 0


class DeckWithCardsOut(DeckOut):
    cards: list[DeckCardOut] = []


class CardRegisterIn(BaseModel):
    card_code: str = Field(..., pattern=r"^[AKQJT2-9][SHDC]$")
    rfid_uid: str = Field(..., min_length=8, max_length=32, pattern=r"^[0-9A-F]+$")


class DeckImportIn(BaseModel):
    name: str
    cards: dict[str, str]  # card_code → rfid_uid

    def validate_52(self) -> None:
        if len(self.cards) != 52:
            raise ValueError(
                f"bulk import requires all 52 cards, got {len(self.cards)}"
            )
        invalid = set(self.cards.keys()) - VALID_CARD_CODES
        if invalid:
            raise ValueError(f"invalid card codes: {sorted(invalid)}")


class CardReplaceIn(BaseModel):
    new_rfid_uid: str = Field(
        ..., min_length=8, max_length=32, pattern=r"^[0-9A-F]+$"
    )
    reason: str = Field(..., min_length=1, max_length=200)


class DeckStatusPatchIn(BaseModel):
    status: DeckStatus


# ---------------------------------------------------------------------------
# Endpoints (skeleton — team2 wires real DB sessions)
# ---------------------------------------------------------------------------


@router.post("", response_model=DeckOut, status_code=status.HTTP_201_CREATED)
async def create_deck(payload: DeckCreateIn) -> DeckOut:
    """Create a new (empty) deck. Starts in 'registering' status.

    [TODO-T2-004]: wire to db.session + real INSERT.
    """
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement",
    )


@router.get("", response_model=list[DeckOut])
async def list_decks(
    status_filter: DeckStatus | None = None,
) -> list[DeckOut]:
    """List all decks, optionally filtered by status.

    [TODO-T2-004]: wire to db.session + SELECT.
    """
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement",
    )


@router.get("/{deck_id}", response_model=DeckWithCardsOut)
async def get_deck(deck_id: str) -> DeckWithCardsOut:
    """Get deck details + card registrations.

    [TODO-T2-004]: JOIN decks + deck_cards.
    """
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement",
    )


@router.post(
    "/{deck_id}/cards",
    response_model=DeckCardOut,
    status_code=status.HTTP_201_CREATED,
)
async def register_card(deck_id: str, payload: CardRegisterIn) -> DeckCardOut:
    """Register a single card (scan-based mode B).

    Steps (team2 session to implement):
      1. Verify deck exists and status == 'registering' or 'partial'
      2. Verify card_code not already registered in this deck
      3. [TODO-T2-006] Verify rfid_uid is globally unique (not in any other deck)
      4. INSERT deck_cards row
      5. If deck now has 52 cards, auto-transition status to 'active'
      6. [TODO-T2-007] audit_events: card_registered

    Returns 409 on conflict (duplicate card_code or rfid_uid cross-deck).
    """
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement",
    )


@router.post(
    "/import",
    response_model=DeckWithCardsOut,
    status_code=status.HTTP_201_CREATED,
)
async def import_deck(payload: DeckImportIn) -> DeckWithCardsOut:
    """Bulk JSON import (mode A). All 52 cards at once.

    [TODO-T2-004]: transaction — INSERT deck + 52 deck_cards, auto-activate.
    """
    try:
        payload.validate_52()
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement",
    )


@router.patch(
    "/{deck_id}/cards/{card_code}",
    response_model=DeckCardOut,
)
async def replace_card(
    deck_id: str, card_code: str, payload: CardReplaceIn
) -> DeckCardOut:
    """Replace a damaged/lost card's RFID UID.

    [TODO-T2-007]: audit_events: card_replaced with reason.
    [TODO-T2-006]: new_rfid_uid must be globally unique.
    """
    if card_code not in VALID_CARD_CODES:
        raise HTTPException(status_code=400, detail=f"invalid card_code: {card_code}")
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement",
    )


@router.patch("/{deck_id}", response_model=DeckOut)
async def update_deck_status(
    deck_id: str, payload: DeckStatusPatchIn
) -> DeckOut:
    """Retire a deck or transition status manually.

    Transitions allowed:
      registering → partial | active (52 registered) | retired
      active → partial (card damaged) | retired
      partial → active (replacement registered) | retired
    """
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement",
    )


@router.delete("/{deck_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_deck(deck_id: str) -> None:
    """Hard delete — Admin only. Use PATCH status=retired for soft archival.

    [TODO-T2-005]: RBAC guard for Admin role.
    """
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement",
    )
