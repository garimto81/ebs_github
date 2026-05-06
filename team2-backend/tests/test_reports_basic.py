"""SG-007 Reports — 6 endpoint basic shape + RBAC + validation tests.

12 scenarios covered:
  1. dashboard happy (admin)
  2. dashboard viewer allowed (RBAC)
  3. table-activity happy (admin)
  4. table-activity operator allowed
  5. player-stats happy
  6. hand-distribution happy (admin only)
  7. hand-distribution viewer rejected (403)
  8. rfid-health happy (admin)
  9. operator-activity happy
  10. invalid scope → 400
  11. global scope with scope_id omitted → ok
  12. non-global scope without scope_id → 400 SCOPE_ID_REQUIRED

[TODO-T2-009]: swap mock data for MV-backed real aggregates.
"""
from __future__ import annotations


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    r = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    return r.json()["data"]["accessToken"]


def _auth(client, role="admin") -> dict:
    emails = {
        "admin": ("admin@test.com", "Admin123!"),
        "operator": ("operator@test.com", "Op123!"),
        "viewer": ("viewer@test.com", "View123!"),
    }
    email, pw = emails[role]
    return {"Authorization": f"Bearer {_login(client, email, pw)}"}


COMMON_Q = (
    "scope=global"
    "&from=2026-04-01T00:00:00Z"
    "&to=2026-04-20T00:00:00Z"
    "&granularity=day"
)


# 1. dashboard happy ──────────────────────────────────────────────


def test_dashboard_admin(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(f"/api/v1/reports/dashboard?{COMMON_Q}", headers=headers)
    assert r.status_code == 200
    body = r.json()
    assert body["reportType"] == "dashboard"
    assert body["scope"]["level"] == "global"
    assert body["scope"]["id"] is None
    assert "generatedAt" in body
    assert "tables" in body["data"]
    assert "hands" in body["data"]
    assert "rfidHealth" in body["data"]


# 2. dashboard viewer (RBAC) ──────────────────────────────────────


def test_dashboard_viewer(client, seed_users):
    headers = _auth(client, "viewer")
    r = client.get(f"/api/v1/reports/dashboard?{COMMON_Q}", headers=headers)
    assert r.status_code == 200


# 3. table-activity happy ─────────────────────────────────────────


def test_table_activity_admin(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(f"/api/v1/reports/table-activity?{COMMON_Q}", headers=headers)
    assert r.status_code == 200
    body = r.json()
    assert body["reportType"] == "table-activity"
    assert isinstance(body["data"], list)


# 4. table-activity operator ──────────────────────────────────────


def test_table_activity_operator(client, seed_users):
    headers = _auth(client, "operator")
    r = client.get(f"/api/v1/reports/table-activity?{COMMON_Q}", headers=headers)
    assert r.status_code == 200


# 5. player-stats happy ───────────────────────────────────────────


def test_player_stats_admin(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(
        f"/api/v1/reports/player-stats?player_id=p-1&{COMMON_Q}",
        headers=headers,
    )
    assert r.status_code == 200
    body = r.json()
    assert body["data"]["playerId"] == "p-1"
    assert "metrics" in body["data"]
    m = body["data"]["metrics"]
    for k in ("vpip", "pfr", "af", "threebetPct", "totalHands"):
        assert k in m


# 6. hand-distribution happy (admin) ──────────────────────────────


def test_hand_distribution_admin(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(
        f"/api/v1/reports/hand-distribution?{COMMON_Q}", headers=headers
    )
    assert r.status_code == 200
    body = r.json()
    assert "matrix" in body["data"]
    assert "showdownOnly" in body["data"]


# 7. hand-distribution viewer → 403 ───────────────────────────────


def test_hand_distribution_viewer_forbidden(client, seed_users):
    headers = _auth(client, "viewer")
    r = client.get(
        f"/api/v1/reports/hand-distribution?{COMMON_Q}", headers=headers
    )
    assert r.status_code == 403


# 8. rfid-health happy (admin) ────────────────────────────────────


def test_rfid_health_admin(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(f"/api/v1/reports/rfid-health?{COMMON_Q}", headers=headers)
    assert r.status_code == 200
    body = r.json()
    assert "readers" in body["data"]
    assert "cards" in body["data"]


# 9. operator-activity happy ──────────────────────────────────────


def test_operator_activity_admin(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(
        f"/api/v1/reports/operator-activity?user_id=u-1&{COMMON_Q}",
        headers=headers,
    )
    assert r.status_code == 200
    body = r.json()
    assert body["data"]["userId"] == "u-1"


# 10. invalid scope → 400 ─────────────────────────────────────────


def test_dashboard_invalid_scope(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(
        "/api/v1/reports/dashboard"
        "?scope=planet&from=2026-04-01T00:00:00Z"
        "&to=2026-04-20T00:00:00Z&granularity=day",
        headers=headers,
    )
    # Pydantic Literal rejects at 422; custom validator at 400. Either is acceptable.
    assert r.status_code in (400, 422)


# 11. global with scope_id omitted → 200 ──────────────────────────


def test_dashboard_global_scope_id_omitted(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(f"/api/v1/reports/dashboard?{COMMON_Q}", headers=headers)
    assert r.status_code == 200


# 12. non-global scope without scope_id → 400 ────────────────────


def test_dashboard_event_scope_missing_id(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get(
        "/api/v1/reports/dashboard"
        "?scope=event&from=2026-04-01T00:00:00Z"
        "&to=2026-04-20T00:00:00Z&granularity=day",
        headers=headers,
    )
    assert r.status_code == 400
    assert r.json()["detail"]["code"] == "SCOPE_ID_REQUIRED"


# 13. Legacy /reports/{report_type} is DELETED (SG-008-b12) ───────


def test_legacy_reports_endpoint_deleted(client, seed_users):
    headers = _auth(client, "admin")
    r = client.get("/api/v1/reports/hands-summary", headers=headers)
    # Must not be the legacy 200. FastAPI returns 422 (bad query params) or 404.
    assert r.status_code in (404, 422, 400)
