"""Sync namespace SSOT alignment — Backend_HTTP.md L965-967."""
import pytest


def _login(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!"}
    resp = client.post("/auth/login", json={
        "email": emails[role], "password": passwords[role],
    })
    return {"Authorization": f"Bearer {resp.json()['data']['access_token']}"}


def test_wsop_live_status_canonical_route(client, seed_users):
    headers = _login(client, "admin")
    resp = client.get("/api/v1/sync/wsop-live/status", headers=headers)
    assert resp.status_code == 200
    assert "data" in resp.json()


def test_wsop_live_trigger_admin_only(client, seed_users):
    headers = _login(client, "admin")
    resp = client.post("/api/v1/sync/wsop-live", headers=headers)
    assert resp.status_code == 200
    body = resp.json()["data"]
    assert body["source"] == "wsop_live"


def test_wsop_live_trigger_operator_denied(client, seed_users):
    headers = _login(client, "operator")
    resp = client.post("/api/v1/sync/wsop-live", headers=headers)
    assert resp.status_code == 403


def test_conflicts_endpoint_returns_list(client, seed_users):
    headers = _login(client, "admin")
    resp = client.get("/api/v1/sync/conflicts", headers=headers)
    assert resp.status_code == 200
    assert "conflicts" in resp.json()["data"]


def test_legacy_trigger_still_works(client, seed_users):
    """Existing clients using POST /sync/trigger/wsop_live remain functional."""
    headers = _login(client, "admin")
    resp = client.post("/api/v1/sync/trigger/wsop_live", headers=headers)
    assert resp.status_code == 200
