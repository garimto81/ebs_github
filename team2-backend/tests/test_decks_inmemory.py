"""SG-006 in-memory deck router tests.

Covers:
  - Demo Mode seed (SG-002 연계) presence + 52 cards
  - create_deck → register_card workflow
  - Cross-deck UID uniqueness (409)
  - Auto-transition to 'active' at 52 cards
  - Bulk import (mode A) + conflict detection
  - Replace card UID
  - Patch status (retire transition guards)
  - Delete deck

[TODO-T2-004]: when DB-backed impl lands, fixture will wrap transaction+rollback
               instead of _reset_store_for_tests().
"""
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from src.main import app
from src.routers.decks import (
    VALID_CARD_CODES,
    _reset_store_for_tests,
    _seed_demo_deck,
)


# ── Local fixture: isolate in-memory store per test ──────────────────────


@pytest.fixture
def deck_client() -> TestClient:
    _reset_store_for_tests()
    _seed_demo_deck()
    return TestClient(app)


def _uid(n: int) -> str:
    """Produce a valid 8-char hex UID unique per n."""
    return f"{n:08X}"


# ── Demo seed ────────────────────────────────────────────────────────────


def test_demo_deck_seeded_active_with_52_cards(deck_client: TestClient) -> None:
    r = deck_client.get("/api/v1/decks/demo")
    assert r.status_code == 200
    body = r.json()
    assert body["id"] == "demo"
    assert body["status"] == "active"
    assert body["cardsRegistered"] == 52
    assert len(body["cards"]) == 52
    # All 52 codes present
    codes = {c["cardCode"] for c in body["cards"]}
    assert codes == set(VALID_CARD_CODES)


# ── Create + register cards ──────────────────────────────────────────────


def test_create_deck_starts_registering(deck_client: TestClient) -> None:
    r = deck_client.post("/api/v1/decks", json={"name": "Table-01 deck"})
    assert r.status_code == 201
    body = r.json()
    assert body["name"] == "Table-01 deck"
    assert body["status"] == "registering"
    assert body["cardsRegistered"] == 0


def test_register_single_card_transitions_to_partial(deck_client: TestClient) -> None:
    create = deck_client.post("/api/v1/decks", json={"name": "T1"}).json()
    deck_id = create["id"]
    r = deck_client.post(
        f"/api/v1/decks/{deck_id}/cards",
        json={"cardCode": "AS", "rfidUid": _uid(1)},
    )
    assert r.status_code == 201
    assert r.json()["cardCode"] == "AS"

    deck = deck_client.get(f"/api/v1/decks/{deck_id}").json()
    assert deck["status"] == "partial"
    assert deck["cardsRegistered"] == 1


def test_register_all_52_auto_activates(deck_client: TestClient) -> None:
    create = deck_client.post("/api/v1/decks", json={"name": "T52"}).json()
    deck_id = create["id"]
    for i, code in enumerate(sorted(VALID_CARD_CODES)):
        r = deck_client.post(
            f"/api/v1/decks/{deck_id}/cards",
            json={"cardCode": code, "rfidUid": _uid(1000 + i)},
        )
        assert r.status_code == 201
    deck = deck_client.get(f"/api/v1/decks/{deck_id}").json()
    assert deck["status"] == "active"
    assert deck["cardsRegistered"] == 52


def test_duplicate_card_code_rejected(deck_client: TestClient) -> None:
    create = deck_client.post("/api/v1/decks", json={"name": "Tdup"}).json()
    deck_id = create["id"]
    deck_client.post(
        f"/api/v1/decks/{deck_id}/cards",
        json={"cardCode": "KH", "rfidUid": _uid(2)},
    )
    r = deck_client.post(
        f"/api/v1/decks/{deck_id}/cards",
        json={"cardCode": "KH", "rfidUid": _uid(3)},
    )
    assert r.status_code == 409
    assert r.json()["detail"]["code"] == "CARD_CODE_ALREADY_REGISTERED"


# ── Cross-deck UID uniqueness ────────────────────────────────────────────


def test_cross_deck_uid_conflict_returns_422(deck_client: TestClient) -> None:
    """DRIFT-50.2 (2026-05-12 Cycle 5): cross-deck dup UID = 422 DUPLICATE_UID.

    .http SSOT (50-rfid-deck-register.http) 와 contract 정합. RFC 상 409 가 더
    정확하지만 integration-tests/.http SSOT + issue #282 가 422 명시.
    """
    d1 = deck_client.post("/api/v1/decks", json={"name": "A"}).json()
    d2 = deck_client.post("/api/v1/decks", json={"name": "B"}).json()
    deck_client.post(
        f"/api/v1/decks/{d1['id']}/cards",
        json={"cardCode": "QS", "rfidUid": "DEADBEEF"},
    )
    r = deck_client.post(
        f"/api/v1/decks/{d2['id']}/cards",
        json={"cardCode": "QS", "rfidUid": "DEADBEEF"},
    )
    assert r.status_code == 422
    assert r.json()["detail"]["code"] == "DUPLICATE_UID"
    assert r.json()["detail"]["uid"] == "DEADBEEF"
    assert r.json()["detail"]["existing_deck_id"] == d1["id"]


def test_same_deck_dup_uid_second_register_returns_422(deck_client: TestClient) -> None:
    """DRIFT-50.2 핵심 회귀 — issue #282 증상 (201 → 422 정합).

    동일 deck 내에서 이미 등록된 UID 를 다른 card_code 로 재등록 시도.
    Cycle 2/4 에서 누적 미해결 HIGH — 본 테스트가 실패하면 즉시 회귀.
    """
    create = deck_client.post("/api/v1/decks", json={"name": "DupTest"}).json()
    deck_id = create["id"]
    r1 = deck_client.post(
        f"/api/v1/decks/{deck_id}/cards",
        json={"cardCode": "AS", "rfidUid": "DEADC0DE"},
    )
    assert r1.status_code == 201
    r2 = deck_client.post(
        f"/api/v1/decks/{deck_id}/cards",
        json={"cardCode": "KS", "rfidUid": "DEADC0DE"},  # same UID, different card
    )
    assert r2.status_code == 422
    assert r2.json()["detail"]["code"] == "DUPLICATE_UID"
    assert r2.json()["detail"]["uid"] == "DEADC0DE"


# ── Bulk import ──────────────────────────────────────────────────────────


def test_bulk_import_52_activates_immediately(deck_client: TestClient) -> None:
    cards = {code: _uid(5000 + i) for i, code in enumerate(sorted(VALID_CARD_CODES))}
    r = deck_client.post(
        "/api/v1/decks/import",
        json={"name": "Imported", "cards": cards},
    )
    assert r.status_code == 201
    body = r.json()
    assert body["status"] == "active"
    assert body["cardsRegistered"] == 52


def test_bulk_import_less_than_52_rejected(deck_client: TestClient) -> None:
    r = deck_client.post(
        "/api/v1/decks/import",
        json={"name": "Partial", "cards": {"AS": _uid(9001)}},
    )
    assert r.status_code == 400
    assert r.json()["detail"]["code"] == "INVALID_IMPORT"


def test_bulk_import_uid_conflict_with_demo_rejected(deck_client: TestClient) -> None:
    """DRIFT-50.2 (Cycle 5): cross-deck dup UID in import = 422/DUPLICATE_UID."""
    demo_as = next(
        c for c in deck_client.get("/api/v1/decks/demo").json()["cards"]
        if c["cardCode"] == "AS"
    )
    cards = {code: _uid(7000 + i) for i, code in enumerate(sorted(VALID_CARD_CODES))}
    cards["AS"] = demo_as["rfidUid"]  # conflict
    r = deck_client.post(
        "/api/v1/decks/import",
        json={"name": "Conflict", "cards": cards},
    )
    assert r.status_code == 422
    assert r.json()["detail"]["code"] == "DUPLICATE_UID"
    assert r.json()["detail"]["scope"] == "cross_deck"


def test_bulk_import_intra_payload_dup_uid_rejected(deck_client: TestClient) -> None:
    """DRIFT-50.2 신규 (Cycle 5): payload 내부에서 두 card_code 가 동일 UID
    가지면 422.

    dict[card_code → uid] 구조에서 키 중복은 dict 가 차단하지만 값(uid) 중복은
    명시 검증 없이는 통과. cross-deck index 추가 전 단계에서 catch 해야 함.
    """
    # 51 unique + 1 duplicate (AS 와 2C 가 동일 UID)
    cards = {code: _uid(8000 + i) for i, code in enumerate(sorted(VALID_CARD_CODES))}
    cards["2C"] = cards["AS"]  # intra-payload dup
    r = deck_client.post(
        "/api/v1/decks/import",
        json={"name": "IntraDup", "cards": cards},
    )
    assert r.status_code == 422
    assert r.json()["detail"]["code"] == "DUPLICATE_UID"
    assert r.json()["detail"]["scope"] == "intra_payload"


# ── Replace card ─────────────────────────────────────────────────────────


def test_replace_card_updates_uid(deck_client: TestClient) -> None:
    create = deck_client.post("/api/v1/decks", json={"name": "Tr"}).json()
    deck_id = create["id"]
    deck_client.post(
        f"/api/v1/decks/{deck_id}/cards",
        json={"cardCode": "2C", "rfidUid": _uid(42)},
    )
    r = deck_client.patch(
        f"/api/v1/decks/{deck_id}/cards/2C",
        json={"newRfidUid": _uid(4242), "reason": "damaged sleeve"},
    )
    assert r.status_code == 200
    assert r.json()["rfidUid"] == _uid(4242)


def test_replace_card_dup_uid_returns_422(deck_client: TestClient) -> None:
    """DRIFT-50.2 (Cycle 5): replace 시도 UID 가 다른 deck/card 점유 중이면 422."""
    d1 = deck_client.post("/api/v1/decks", json={"name": "R1"}).json()
    d2 = deck_client.post("/api/v1/decks", json={"name": "R2"}).json()
    deck_client.post(
        f"/api/v1/decks/{d1['id']}/cards",
        json={"cardCode": "5H", "rfidUid": "BEEFCAFE"},
    )
    deck_client.post(
        f"/api/v1/decks/{d2['id']}/cards",
        json={"cardCode": "6H", "rfidUid": "C0FFEE00"},
    )
    r = deck_client.patch(
        f"/api/v1/decks/{d2['id']}/cards/6H",
        json={"newRfidUid": "BEEFCAFE", "reason": "swap"},
    )
    assert r.status_code == 422
    assert r.json()["detail"]["code"] == "DUPLICATE_UID"
    assert r.json()["detail"]["uid"] == "BEEFCAFE"


# ── Status transitions ───────────────────────────────────────────────────


def test_retire_deck_then_transition_rejected(deck_client: TestClient) -> None:
    create = deck_client.post("/api/v1/decks", json={"name": "Tret"}).json()
    deck_id = create["id"]
    r1 = deck_client.patch(
        f"/api/v1/decks/{deck_id}", json={"status": "retired"}
    )
    assert r1.status_code == 200
    assert r1.json()["status"] == "retired"
    # Retired is terminal
    r2 = deck_client.patch(
        f"/api/v1/decks/{deck_id}", json={"status": "active"}
    )
    assert r2.status_code == 409
    assert r2.json()["detail"]["code"] == "INVALID_STATUS_TRANSITION"


# ── List + delete ────────────────────────────────────────────────────────


def test_list_filter_by_status(deck_client: TestClient) -> None:
    deck_client.post("/api/v1/decks", json={"name": "L1"})
    deck_client.post("/api/v1/decks", json={"name": "L2"})
    r = deck_client.get("/api/v1/decks?status_filter=registering")
    assert r.status_code == 200
    body = r.json()
    # Two newly created plus none else (demo=active)
    assert len(body) == 2


def test_delete_deck_removes_cards_and_uid_index(deck_client: TestClient) -> None:
    create = deck_client.post("/api/v1/decks", json={"name": "Tdel"}).json()
    deck_id = create["id"]
    deck_client.post(
        f"/api/v1/decks/{deck_id}/cards",
        json={"cardCode": "TD", "rfidUid": _uid(99)},
    )
    r = deck_client.delete(f"/api/v1/decks/{deck_id}")
    assert r.status_code == 204

    # UID can be reused after deletion
    create2 = deck_client.post("/api/v1/decks", json={"name": "Treuse"}).json()
    r2 = deck_client.post(
        f"/api/v1/decks/{create2['id']}/cards",
        json={"cardCode": "TD", "rfidUid": _uid(99)},
    )
    assert r2.status_code == 201
