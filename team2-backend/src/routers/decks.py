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

This revision replaces 501 stubs with **in-memory dict store** so the
prototype can exercise the full workflow (Demo Mode seed, registration,
cross-deck UID uniqueness, 52-auto-activate, retire). The store structure
mirrors the forthcoming SQL schema 1:1 so swap-out is mechanical.

team2 session TODO markers (all handlers):
  [TODO-T2-004] replace _decks_store / _deck_cards_store with db.session
                backed by decks + deck_cards tables (Schema.md §SG-006).
  [TODO-T2-005] RBAC guard: Admin required for create/delete, Operator for scan
  [TODO-T2-007] audit_events integration (deck_created, card_replaced, deck_retired)
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone
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
# In-memory store — [TODO-T2-004] replace with db.session
# ---------------------------------------------------------------------------

_decks_store: dict[str, dict] = {}
# deck_id -> {id, name, status, created_at, notes}

_deck_cards_store: dict[tuple[str, str], dict] = {}
# (deck_id, card_code) -> {card_code, rfid_uid, registered_at, registered_by}

_rfid_uid_index: dict[str, tuple[str, str]] = {}
# rfid_uid -> (deck_id, card_code) — cross-deck uniqueness


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _deck_out(d: dict) -> DeckOut:
    count = sum(1 for k in _deck_cards_store if k[0] == d["id"])
    return DeckOut(
        id=d["id"],
        name=d["name"],
        status=d["status"],
        created_at=d["created_at"],
        notes=d.get("notes"),
        cards_registered=count,
    )


def _deck_with_cards(d: dict) -> DeckWithCardsOut:
    cards = [
        DeckCardOut(**c)
        for (did, _cc), c in _deck_cards_store.items()
        if did == d["id"]
    ]
    cards.sort(key=lambda c: c.card_code)
    count = len(cards)
    return DeckWithCardsOut(
        id=d["id"],
        name=d["name"],
        status=d["status"],
        created_at=d["created_at"],
        notes=d.get("notes"),
        cards_registered=count,
        cards=cards,
    )


def _seed_demo_deck() -> None:
    """SG-002 Demo Mode seed — single pre-loaded 52-card deck named 'demo'.

    [TODO-T2-008] lift into app.lifespan startup; currently lazy on first call.
    """
    if "demo" in _decks_store:
        return
    _decks_store["demo"] = {
        "id": "demo",
        "name": "Demo Deck (SG-002)",
        "status": "active",
        "created_at": _now(),
        "notes": "seeded by SG-006 in-memory store for Demo Mode (SG-002)",
    }
    for code in sorted(VALID_CARD_CODES):
        uid = f"DEMO{code:>2}"
        # Pad UID to 8+ hex chars to satisfy validator
        hex_uid = uid.encode("ascii").hex().upper()
        _deck_cards_store[("demo", code)] = {
            "card_code": code,
            "rfid_uid": hex_uid,
            "registered_at": _now(),
            "registered_by": "system:seed",
        }
        _rfid_uid_index[hex_uid] = ("demo", code)


def _reset_store_for_tests() -> None:
    """Test helper — full reset. Not exported via router."""
    _decks_store.clear()
    _deck_cards_store.clear()
    _rfid_uid_index.clear()


# Lazy seed on import — harmless; test fixture can call _reset_store_for_tests.
_seed_demo_deck()


# ---------------------------------------------------------------------------
# Endpoints — in-memory implementation
# ---------------------------------------------------------------------------


@router.post("", response_model=DeckOut, status_code=status.HTTP_201_CREATED)
async def create_deck(payload: DeckCreateIn) -> DeckOut:
    """Create a new (empty) deck. Starts in 'registering' status.

    [TODO-T2-004]: replace _decks_store with db.session INSERT.
    [TODO-T2-005]: RBAC admin only.
    """
    deck_id = str(uuid.uuid4())
    _decks_store[deck_id] = {
        "id": deck_id,
        "name": payload.name,
        "status": "registering",
        "created_at": _now(),
        "notes": payload.notes,
    }
    return _deck_out(_decks_store[deck_id])


@router.get("", response_model=list[DeckOut])
async def list_decks(
    status_filter: DeckStatus | None = None,
) -> list[DeckOut]:
    """List all decks, optionally filtered by status.

    [TODO-T2-004]: replace with db.exec(select(Deck).where(...)).
    """
    decks = list(_decks_store.values())
    if status_filter is not None:
        decks = [d for d in decks if d["status"] == status_filter]
    decks.sort(key=lambda d: d["created_at"])
    return [_deck_out(d) for d in decks]


@router.get("/{deck_id}", response_model=DeckWithCardsOut)
async def get_deck(deck_id: str) -> DeckWithCardsOut:
    """Get deck details + card registrations.

    [TODO-T2-004]: replace with JOIN decks + deck_cards.
    """
    if deck_id not in _decks_store:
        raise HTTPException(status_code=404, detail={"code": "DECK_NOT_FOUND"})
    return _deck_with_cards(_decks_store[deck_id])


@router.post(
    "/{deck_id}/cards",
    response_model=DeckCardOut,
    status_code=status.HTTP_201_CREATED,
)
async def register_card(deck_id: str, payload: CardRegisterIn) -> DeckCardOut:
    """Register a single card (scan-based mode B).

    Steps:
      1. Verify deck exists and status allows registration
      2. Verify card_code not already registered in this deck
      3. Verify rfid_uid is globally unique (not in any other deck)
      4. INSERT deck_cards row
      5. If deck now has 52 cards, auto-transition status to 'active'

    [TODO-T2-004]: swap dict → db.session.
    [TODO-T2-007]: audit_event card_registered.
    """
    if deck_id not in _decks_store:
        raise HTTPException(status_code=404, detail={"code": "DECK_NOT_FOUND"})
    deck = _decks_store[deck_id]
    if deck["status"] not in ("registering", "partial"):
        raise HTTPException(
            status_code=409,
            detail={
                "code": "DECK_NOT_OPEN_FOR_REGISTRATION",
                "current_status": deck["status"],
            },
        )
    if payload.card_code not in VALID_CARD_CODES:
        raise HTTPException(
            status_code=400,
            detail={"code": "INVALID_CARD_CODE", "value": payload.card_code},
        )
    if (deck_id, payload.card_code) in _deck_cards_store:
        raise HTTPException(
            status_code=409,
            detail={"code": "CARD_CODE_ALREADY_REGISTERED", "card_code": payload.card_code},
        )
    if payload.rfid_uid in _rfid_uid_index:
        (existing_deck, existing_code) = _rfid_uid_index[payload.rfid_uid]
        raise HTTPException(
            status_code=409,
            detail={
                "code": "RFID_UID_DUPLICATE",
                "message": "UID already registered in another deck",
                "existing_deck_id": existing_deck,
                "existing_card_code": existing_code,
            },
        )

    row = {
        "card_code": payload.card_code,
        "rfid_uid": payload.rfid_uid,
        "registered_at": _now(),
        "registered_by": None,  # [TODO-T2-005] fill from current user
    }
    _deck_cards_store[(deck_id, payload.card_code)] = row
    _rfid_uid_index[payload.rfid_uid] = (deck_id, payload.card_code)

    # Auto-activate when all 52 registered
    registered_count = sum(1 for k in _deck_cards_store if k[0] == deck_id)
    if registered_count == 52 and deck["status"] != "active":
        deck["status"] = "active"
    elif 0 < registered_count < 52 and deck["status"] == "registering":
        deck["status"] = "partial"

    return DeckCardOut(**row)


@router.post(
    "/import",
    response_model=DeckWithCardsOut,
    status_code=status.HTTP_201_CREATED,
)
async def import_deck(payload: DeckImportIn) -> DeckWithCardsOut:
    """Bulk JSON import (mode A). All 52 cards at once.

    [TODO-T2-004]: wrap in transaction — INSERT deck + 52 deck_cards atomically.
    """
    try:
        payload.validate_52()
    except ValueError as e:
        raise HTTPException(status_code=400, detail={"code": "INVALID_IMPORT", "message": str(e)})

    # Cross-deck UID conflict check before mutating
    conflicts: list[dict] = []
    for cc, uid in payload.cards.items():
        if uid in _rfid_uid_index:
            (ed, ec) = _rfid_uid_index[uid]
            conflicts.append({"card_code": cc, "rfid_uid": uid, "existing_deck": ed, "existing_card": ec})
    if conflicts:
        raise HTTPException(
            status_code=409,
            detail={"code": "RFID_UID_DUPLICATE", "conflicts": conflicts},
        )

    deck_id = str(uuid.uuid4())
    now = _now()
    _decks_store[deck_id] = {
        "id": deck_id,
        "name": payload.name,
        "status": "active",
        "created_at": now,
        "notes": None,
    }
    for cc, uid in payload.cards.items():
        row = {
            "card_code": cc,
            "rfid_uid": uid,
            "registered_at": now,
            "registered_by": "bulk_import",
        }
        _deck_cards_store[(deck_id, cc)] = row
        _rfid_uid_index[uid] = (deck_id, cc)

    return _deck_with_cards(_decks_store[deck_id])


@router.patch(
    "/{deck_id}/cards/{card_code}",
    response_model=DeckCardOut,
)
async def replace_card(
    deck_id: str, card_code: str, payload: CardReplaceIn
) -> DeckCardOut:
    """Replace a damaged/lost card's RFID UID.

    [TODO-T2-007]: audit_event card_replaced with reason.
    """
    if card_code not in VALID_CARD_CODES:
        raise HTTPException(status_code=400, detail={"code": "INVALID_CARD_CODE", "value": card_code})
    if deck_id not in _decks_store:
        raise HTTPException(status_code=404, detail={"code": "DECK_NOT_FOUND"})
    if (deck_id, card_code) not in _deck_cards_store:
        raise HTTPException(status_code=404, detail={"code": "CARD_NOT_FOUND"})
    if payload.new_rfid_uid in _rfid_uid_index:
        (ed, ec) = _rfid_uid_index[payload.new_rfid_uid]
        if (ed, ec) != (deck_id, card_code):
            raise HTTPException(
                status_code=409,
                detail={
                    "code": "RFID_UID_DUPLICATE",
                    "existing_deck_id": ed,
                    "existing_card_code": ec,
                },
            )

    row = _deck_cards_store[(deck_id, card_code)]
    old_uid = row["rfid_uid"]
    if old_uid != payload.new_rfid_uid:
        _rfid_uid_index.pop(old_uid, None)
    row["rfid_uid"] = payload.new_rfid_uid
    row["registered_at"] = _now()
    _rfid_uid_index[payload.new_rfid_uid] = (deck_id, card_code)
    return DeckCardOut(**row)


@router.patch("/{deck_id}", response_model=DeckOut)
async def update_deck_status(
    deck_id: str, payload: DeckStatusPatchIn
) -> DeckOut:
    """Retire a deck or transition status manually.

    Allowed transitions (guarded):
      registering → partial | active | retired
      active      → partial | damaged | retired
      partial     → active  | retired
      damaged     → active  | retired
      retired     → (terminal — reject)
    """
    if deck_id not in _decks_store:
        raise HTTPException(status_code=404, detail={"code": "DECK_NOT_FOUND"})
    allowed = {
        "registering": {"partial", "active", "retired"},
        "active": {"partial", "damaged", "retired"},
        "partial": {"active", "retired"},
        "damaged": {"active", "retired"},
        "retired": set(),
    }
    deck = _decks_store[deck_id]
    current = deck["status"]
    if payload.status not in allowed.get(current, set()) and payload.status != current:
        raise HTTPException(
            status_code=409,
            detail={"code": "INVALID_STATUS_TRANSITION", "from": current, "to": payload.status},
        )
    deck["status"] = payload.status
    return _deck_out(deck)


@router.delete("/{deck_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_deck(deck_id: str) -> None:
    """Hard delete — Admin only. Prefer PATCH status=retired for soft archival.

    [TODO-T2-005]: RBAC guard for Admin role.
    """
    if deck_id not in _decks_store:
        raise HTTPException(status_code=404, detail={"code": "DECK_NOT_FOUND"})
    # Remove cards + UID index
    to_drop = [k for k in _deck_cards_store if k[0] == deck_id]
    for k in to_drop:
        uid = _deck_cards_store[k]["rfid_uid"]
        _rfid_uid_index.pop(uid, None)
        del _deck_cards_store[k]
    del _decks_store[deck_id]
    return None
