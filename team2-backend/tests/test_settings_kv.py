"""SG-003 Settings KV — in-memory store tests.

Covers:
  - PUT global scope (scope_id=null)
  - PUT event scope (scope_id required)
  - GET resolved — 4-level override (global → series → event → table)
  - scope_id validation (global must be null; non-global must be set)
  - invalid tab → 400
  - invalid scope_level → 400
  - DELETE → 204, then fallback to next scope in resolved
  - LIST filtered by scope_level/tab

[TODO-T2-011]: when DB-backed impl lands, fixture replaces dict reset
               with transaction+rollback.
"""
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from src.main import app
from src.routers.settings_kv import _reset_store_for_tests


@pytest.fixture
def settings_client() -> TestClient:
    _reset_store_for_tests()
    return TestClient(app)


# ── PUT / upsert ──────────────────────────────────────────────────────────


def test_put_global_scope_ok(settings_client: TestClient) -> None:
    r = settings_client.put(
        "/api/v1/settings",
        json={
            "scopeLevel": "global",
            "scopeId": None,
            "tab": "outputs",
            "key": "default_sdi_mode",
            "value": "1080i60",
        },
    )
    assert r.status_code == 200
    body = r.json()
    assert body["scopeLevel"] == "global"
    assert body["scopeId"] is None
    assert body["tab"] == "outputs"
    assert body["key"] == "default_sdi_mode"
    assert body["value"] == "1080i60"
    assert body["id"]  # uuid assigned


def test_put_event_scope_requires_scope_id(settings_client: TestClient) -> None:
    r = settings_client.put(
        "/api/v1/settings",
        json={
            "scopeLevel": "event",
            "scopeId": None,  # missing → 400
            "tab": "rules",
            "key": "ante_enabled",
            "value": True,
        },
    )
    assert r.status_code == 400
    assert r.json()["detail"]["code"] == "SCOPE_ID_REQUIRED"


def test_put_global_with_scope_id_rejected(settings_client: TestClient) -> None:
    r = settings_client.put(
        "/api/v1/settings",
        json={
            "scopeLevel": "global",
            "scopeId": "evt-123",  # not allowed for global
            "tab": "outputs",
            "key": "x",
            "value": 1,
        },
    )
    assert r.status_code == 400
    assert r.json()["detail"]["code"] == "SCOPE_ID_NOT_ALLOWED"


# ── Resolved (4-level override) ────────────────────────────────────────────


def test_resolved_override_chain(settings_client: TestClient) -> None:
    """event scope overrides global for the same key."""
    # global default
    settings_client.put(
        "/api/v1/settings",
        json={
            "scopeLevel": "global",
            "scopeId": None,
            "tab": "rules",
            "key": "ante_enabled",
            "value": False,
        },
    )
    # event override
    settings_client.put(
        "/api/v1/settings",
        json={
            "scopeLevel": "event",
            "scopeId": "evt-001",
            "tab": "rules",
            "key": "ante_enabled",
            "value": True,
        },
    )
    # resolved with event_id → event wins
    r = settings_client.get(
        "/api/v1/settings/resolved?tab=rules&event_id=evt-001"
    )
    assert r.status_code == 200
    body = r.json()
    assert body["values"]["ante_enabled"] is True
    assert body["provenance"]["ante_enabled"] == "event"

    # resolved without event_id → global wins
    r2 = settings_client.get("/api/v1/settings/resolved?tab=rules")
    assert r2.status_code == 200
    body2 = r2.json()
    assert body2["values"]["ante_enabled"] is False
    assert body2["provenance"]["ante_enabled"] == "global"


def test_resolved_table_overrides_event(settings_client: TestClient) -> None:
    settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "global", "scopeId": None, "tab": "display",
              "key": "theme", "value": "light"},
    )
    settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "event", "scopeId": "evt-1", "tab": "display",
              "key": "theme", "value": "dark"},
    )
    settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "table", "scopeId": "tbl-9", "tab": "display",
              "key": "theme", "value": "high-contrast"},
    )
    r = settings_client.get(
        "/api/v1/settings/resolved?tab=display&event_id=evt-1&table_id=tbl-9"
    )
    assert r.status_code == 200
    body = r.json()
    assert body["values"]["theme"] == "high-contrast"
    assert body["provenance"]["theme"] == "table"


# ── Validation errors ─────────────────────────────────────────────────────


def test_invalid_tab_rejected(settings_client: TestClient) -> None:
    r = settings_client.put(
        "/api/v1/settings",
        json={
            "scopeLevel": "global",
            "scopeId": None,
            "tab": "nonexistent",
            "key": "x",
            "value": 1,
        },
    )
    # Pydantic Literal rejects at 422, which is also acceptable
    assert r.status_code in (400, 422)


def test_invalid_scope_level_rejected(settings_client: TestClient) -> None:
    r = settings_client.put(
        "/api/v1/settings",
        json={
            "scopeLevel": "planet",  # invalid
            "scopeId": "p-1",
            "tab": "outputs",
            "key": "x",
            "value": 1,
        },
    )
    assert r.status_code in (400, 422)


# ── DELETE ────────────────────────────────────────────────────────────────


def test_delete_then_resolved_falls_back(settings_client: TestClient) -> None:
    # global default
    settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "global", "scopeId": None, "tab": "rules",
              "key": "ante_enabled", "value": False},
    )
    # event override
    settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "event", "scopeId": "evt-del", "tab": "rules",
              "key": "ante_enabled", "value": True},
    )
    # delete event override
    r = settings_client.request(
        "DELETE",
        "/api/v1/settings",
        json={"scopeLevel": "event", "scopeId": "evt-del", "tab": "rules",
              "key": "ante_enabled"},
    )
    assert r.status_code == 204

    # resolved now falls back to global (=False)
    r2 = settings_client.get(
        "/api/v1/settings/resolved?tab=rules&event_id=evt-del"
    )
    assert r2.status_code == 200
    body = r2.json()
    assert body["values"]["ante_enabled"] is False
    assert body["provenance"]["ante_enabled"] == "global"


def test_delete_nonexistent_returns_404(settings_client: TestClient) -> None:
    r = settings_client.request(
        "DELETE",
        "/api/v1/settings",
        json={"scopeLevel": "global", "scopeId": None, "tab": "outputs",
              "key": "missing"},
    )
    assert r.status_code == 404


# ── LIST filter ────────────────────────────────────────────────────────────


def test_list_filter_by_scope_level_and_tab(settings_client: TestClient) -> None:
    settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "global", "scopeId": None, "tab": "outputs",
              "key": "a", "value": 1},
    )
    settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "global", "scopeId": None, "tab": "gfx",
              "key": "b", "value": 2},
    )
    settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "event", "scopeId": "e1", "tab": "outputs",
              "key": "a", "value": 99},
    )

    r = settings_client.get("/api/v1/settings?scope_level=global&tab=outputs")
    assert r.status_code == 200
    rows = r.json()
    assert len(rows) == 1
    assert rows[0]["key"] == "a"
    assert rows[0]["value"] == 1
    assert rows[0]["scopeLevel"] == "global"


def test_put_upsert_is_idempotent(settings_client: TestClient) -> None:
    """PUT twice on same (scope, tab, key) → same id, latest value."""
    r1 = settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "global", "scopeId": None, "tab": "stats",
              "key": "show_vpip", "value": False},
    )
    id1 = r1.json()["id"]
    r2 = settings_client.put(
        "/api/v1/settings",
        json={"scopeLevel": "global", "scopeId": None, "tab": "stats",
              "key": "show_vpip", "value": True},
    )
    assert r2.status_code == 200
    assert r2.json()["id"] == id1  # same row
    assert r2.json()["value"] is True
